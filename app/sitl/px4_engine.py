"""
PX4 SITL Engine - Manages PX4 SITL instances
"""

import os
import subprocess
import time
import threading
import logging
import psutil
import signal
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass
from pathlib import Path

logger = logging.getLogger(__name__)

@dataclass
class PX4Instance:
    """Represents a running PX4 SITL instance"""
    instance_id: str
    aircraft_type: str
    port: int
    process: subprocess.Popen
    mavlink_router_process: Optional[subprocess.Popen] = None
    gazebo_process: Optional[subprocess.Popen] = None
    status: str = "starting"
    created_at: float = 0
    last_heartbeat: float = 0

class PX4Engine:
    """Manages PX4 SITL instances and their lifecycle"""
    
    def __init__(self, px4_path: str, config_path: str = None):
        """
        Initialize PX4 Engine
        
        Args:
            px4_path: Path to PX4-Autopilot directory
            config_path: Path to configuration directory
        """
        self.px4_path = Path(px4_path).resolve()
        self.config_path = Path(config_path) if config_path else Path("config")
        self.instances: Dict[str, PX4Instance] = {}
        self.available_ports = set(range(14550, 14600))  # Available MAVLink ports
        self.used_ports = set()
        
        # Validate PX4 installation
        if not self._validate_px4_installation():
            raise RuntimeError("PX4 installation not found or invalid")
    
    def _validate_px4_installation(self) -> bool:
        """Validate that PX4 is properly installed"""
        px4_build_path = self.px4_path / "build" / "px4_sitl_default"
        px4_binary = px4_build_path / "bin" / "px4"
        
        if not px4_binary.exists():
            logger.error(f"PX4 binary not found at {px4_binary}")
            return False
        
        # Check if binary is executable
        if not os.access(px4_binary, os.X_OK):
            logger.error(f"PX4 binary is not executable: {px4_binary}")
            return False
        
        logger.info(f"PX4 installation validated at {self.px4_path}")
        return True
    
    def get_available_aircraft(self) -> List[Dict[str, str]]:
        """Get list of available aircraft types"""
        # Load aircraft types from configuration
        import yaml
        config_path = Path("config/config.yaml")
        
        aircraft_types = []
        
        if config_path.exists():
            with open(config_path, 'r') as f:
                config = yaml.safe_load(f)
                aircraft_config = config.get('aircraft', {}).get('default_types', [])
                
                for aircraft in aircraft_config:
                    aircraft_types.append({
                        'name': aircraft['name'],
                        'description': aircraft['description'],
                        'gazebo_model': aircraft.get('gazebo_model', aircraft['name']),
                        'px4_model': aircraft.get('px4_model', aircraft['name']),
                        'autostart_id': aircraft.get('autostart_id', '4001')
                    })
        
        # If no config, provide default aircraft types
        if not aircraft_types:
            aircraft_types = [
                {'name': 'iris', 'description': 'Iris Quadcopter', 'gazebo_model': 'iris', 'px4_model': 'iris', 'autostart_id': '4001'},
                {'name': 'x500', 'description': 'X500 Quadcopter', 'gazebo_model': 'x500', 'px4_model': 'x500', 'autostart_id': '4001'},
                {'name': 'solo', 'description': '3DR Solo Quadcopter', 'gazebo_model': 'solo', 'px4_model': 'solo', 'autostart_id': '4001'},
                {'name': 'plane', 'description': 'Generic Fixed-wing Aircraft', 'gazebo_model': 'plane', 'px4_model': 'plane', 'autostart_id': '2100'},
                {'name': 'rover', 'description': 'Generic Ground Rover', 'gazebo_model': 'rover', 'px4_model': 'rover', 'autostart_id': '50000'},
            ]
        
        return aircraft_types
    
    def get_next_available_port(self) -> int:
        """Get next available MAVLink port"""
        available = self.available_ports - self.used_ports
        if not available:
            raise RuntimeError("No available MAVLink ports")
        
        port = min(available)
        self.used_ports.add(port)
        return port
    
    def release_port(self, port: int):
        """Release a MAVLink port"""
        self.used_ports.discard(port)
    
    def start_instance(self, aircraft_type: str, instance_id: str = None) -> str:
        """
        Start a new PX4 SITL instance
        
        Args:
            aircraft_type: Type of aircraft to simulate
            instance_id: Optional custom instance ID
            
        Returns:
            Instance ID of the started instance
        """
        if instance_id is None:
            instance_id = f"{aircraft_type}_{int(time.time())}"
        
        if instance_id in self.instances:
            raise ValueError(f"Instance {instance_id} already exists")
        
        try:
            port = self.get_next_available_port()
            logger.info(f"Starting PX4 SITL instance {instance_id} with {aircraft_type} on port {port}")
            
            # Start PX4 SITL process
            px4_process = self._start_px4_process(aircraft_type, port)
            
            # Start MAVLink router
            mavlink_process = self._start_mavlink_router(port)
            
            # Create instance record
            instance = PX4Instance(
                instance_id=instance_id,
                aircraft_type=aircraft_type,
                port=port,
                process=px4_process,
                mavlink_router_process=mavlink_process,
                status="running",
                created_at=time.time(),
                last_heartbeat=time.time()
            )
            
            self.instances[instance_id] = instance
            
            # Start monitoring thread
            monitor_thread = threading.Thread(
                target=self._monitor_instance,
                args=(instance_id,),
                daemon=True
            )
            monitor_thread.start()
            
            logger.info(f"PX4 SITL instance {instance_id} started successfully")
            return instance_id
            
        except Exception as e:
            logger.error(f"Failed to start PX4 SITL instance: {e}")
            self.release_port(port)
            raise
    
    def _start_px4_process(self, aircraft_type: str, port: int) -> subprocess.Popen:
        """Start PX4 SITL process"""
        # Get aircraft configuration
        aircraft_types = self.get_available_aircraft()
        aircraft_config = None
        
        for aircraft in aircraft_types:
            if aircraft['name'] == aircraft_type:
                aircraft_config = aircraft
                break
        
        if not aircraft_config:
            raise ValueError(f"Unknown aircraft type: {aircraft_type}")
        
        # Set environment variables
        env = os.environ.copy()
        env['HEADLESS'] = '1'
        env['PX4_SIM_HOSTNAME'] = 'localhost'
        
        # Use make command to start PX4 SITL with specific model
        gazebo_model = aircraft_config.get('gazebo_model', aircraft_type)
        
        # Build command using make (this is the correct way for PX4 SITL)
        cmd = [
            'make',
            'px4_sitl',
            f'gz_{gazebo_model}'
        ]
        
        logger.info(f"Starting PX4 SITL with aircraft: {aircraft_type} (Gazebo model: {gazebo_model})")
        logger.info(f"Command: {' '.join(cmd)}")
        
        # Start process
        process = subprocess.Popen(
            cmd,
            cwd=str(self.px4_path),
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            preexec_fn=os.setsid
        )
        
        # Give it a moment to start
        time.sleep(3)
        
        if process.poll() is not None:
            stdout, stderr = process.communicate()
            raise RuntimeError(f"PX4 process failed to start: {stderr.decode()}")
        
        return process
    
    def _start_mavlink_router(self, port: int) -> subprocess.Popen:
        """Start MAVLink router for external connections"""
        # Check if mavlink-routerd is available
        import shutil
        mavlink_router_path = shutil.which('mavlink-routerd')
        
        if not mavlink_router_path:
            raise RuntimeError("mavlink-routerd not found. Please ensure MAVLink router is installed.")
        
        cmd = [
            mavlink_router_path,
            f'0.0.0.0:{port}',
            '-t', '5760',
            '-v'
        ]
        
        logger.info(f"Starting MAVLink router with command: {' '.join(cmd)}")
        
        process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            preexec_fn=os.setsid
        )
        
        # Give it a moment to start
        time.sleep(1)
        
        if process.poll() is not None:
            stdout, stderr = process.communicate()
            raise RuntimeError(f"MAVLink router failed to start: {stderr.decode()}")
        
        return process
    
    def stop_instance(self, instance_id: str) -> bool:
        """
        Stop a PX4 SITL instance
        
        Args:
            instance_id: ID of the instance to stop
            
        Returns:
            True if successfully stopped, False otherwise
        """
        if instance_id not in self.instances:
            logger.warning(f"Instance {instance_id} not found")
            return False
        
        instance = self.instances[instance_id]
        logger.info(f"Stopping PX4 SITL instance {instance_id}")
        
        try:
            # Stop MAVLink router
            if instance.mavlink_router_process:
                self._terminate_process(instance.mavlink_router_process)
            
            # Stop PX4 process
            if instance.process:
                self._terminate_process(instance.process)
            
            # Release port
            self.release_port(instance.port)
            
            # Remove from instances
            del self.instances[instance_id]
            
            logger.info(f"PX4 SITL instance {instance_id} stopped successfully")
            return True
            
        except Exception as e:
            logger.error(f"Error stopping instance {instance_id}: {e}")
            return False
    
    def _terminate_process(self, process: subprocess.Popen):
        """Terminate a process gracefully"""
        if process and process.poll() is None:
            try:
                # Try graceful termination first
                os.killpg(os.getpgid(process.pid), signal.SIGTERM)
                
                # Wait for graceful shutdown
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    # Force kill if graceful shutdown fails
                    os.killpg(os.getpgid(process.pid), signal.SIGKILL)
                    process.wait()
                    
            except ProcessLookupError:
                # Process already terminated
                pass
    
    def _monitor_instance(self, instance_id: str):
        """Monitor a PX4 instance for health"""
        while instance_id in self.instances:
            instance = self.instances[instance_id]
            
            # Check if processes are still running
            px4_running = instance.process and instance.process.poll() is None
            mavlink_running = (instance.mavlink_router_process and 
                             instance.mavlink_router_process.poll() is None)
            
            if not px4_running or not mavlink_running:
                logger.warning(f"Instance {instance_id} processes died, cleaning up")
                instance.status = "failed"
                self.stop_instance(instance_id)
                break
            
            # Update heartbeat
            instance.last_heartbeat = time.time()
            
            time.sleep(5)  # Check every 5 seconds
    
    def get_instance_status(self, instance_id: str) -> Dict:
        """Get status of a specific instance"""
        if instance_id not in self.instances:
            return {"error": "Instance not found"}
        
        instance = self.instances[instance_id]
        return {
            "instance_id": instance.instance_id,
            "aircraft_type": instance.aircraft_type,
            "port": instance.port,
            "status": instance.status,
            "created_at": instance.created_at,
            "last_heartbeat": instance.last_heartbeat,
            "uptime": time.time() - instance.created_at,
            "connection_info": {
                "host": "0.0.0.0",
                "port": instance.port,
                "protocol": "UDP"
            }
        }
    
    def list_instances(self) -> List[Dict]:
        """List all running instances"""
        return [self.get_instance_status(instance_id) 
                for instance_id in self.instances.keys()]
    
    def stop_all_instances(self):
        """Stop all running instances"""
        instance_ids = list(self.instances.keys())
        for instance_id in instance_ids:
            self.stop_instance(instance_id)
    
    def cleanup(self):
        """Cleanup resources"""
        logger.info("Cleaning up PX4 Engine")
        self.stop_all_instances()
