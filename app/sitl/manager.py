"""
SITL Manager - High-level management of SITL instances
"""

import logging
import threading
import time
from typing import Dict, List, Optional
from pathlib import Path

from .px4_engine import PX4Engine

logger = logging.getLogger(__name__)

class SITLManager:
    """High-level manager for SITL instances across different engines"""
    
    def __init__(self, config: Dict):
        """
        Initialize SITL Manager
        
        Args:
            config: Configuration dictionary
        """
        self.config = config
        self.engines: Dict[str, PX4Engine] = {}
        self.instance_registry: Dict[str, str] = {}  # instance_id -> engine_name
        self.lock = threading.Lock()
        
        # Initialize PX4 engine
        px4_path = config.get('px4_path', 'sitl_engines/px4/PX4-Autopilot')
        self.engines['px4'] = PX4Engine(px4_path, config.get('config_path'))
        
        logger.info("SITL Manager initialized")
    
    def get_available_aircraft(self) -> Dict[str, List[Dict]]:
        """Get available aircraft types from all engines"""
        aircraft = {}
        
        for engine_name, engine in self.engines.items():
            if hasattr(engine, 'get_available_aircraft'):
                aircraft[engine_name] = engine.get_available_aircraft()
        
        return aircraft
    
    def start_instance(self, engine_type: str, aircraft_type: str, instance_id: str = None) -> str:
        """
        Start a new SITL instance
        
        Args:
            engine_type: Type of SITL engine ('px4', 'ardupilot', etc.)
            aircraft_type: Type of aircraft to simulate
            instance_id: Optional custom instance ID
            
        Returns:
            Instance ID of the started instance
        """
        with self.lock:
            if engine_type not in self.engines:
                raise ValueError(f"Unknown engine type: {engine_type}")
            
            engine = self.engines[engine_type]
            
            # Generate instance ID if not provided
            if instance_id is None:
                instance_id = f"{engine_type}_{aircraft_type}_{int(time.time())}"
            
            # Check if instance already exists
            if instance_id in self.instance_registry:
                raise ValueError(f"Instance {instance_id} already exists")
            
            try:
                # Start the instance
                actual_instance_id = engine.start_instance(aircraft_type, instance_id)
                
                # Register the instance
                self.instance_registry[actual_instance_id] = engine_type
                
                logger.info(f"Started {engine_type} instance {actual_instance_id}")
                return actual_instance_id
                
            except Exception as e:
                logger.error(f"Failed to start {engine_type} instance: {e}")
                raise
    
    def stop_instance(self, instance_id: str) -> bool:
        """
        Stop a SITL instance
        
        Args:
            instance_id: ID of the instance to stop
            
        Returns:
            True if successfully stopped, False otherwise
        """
        with self.lock:
            if instance_id not in self.instance_registry:
                logger.warning(f"Instance {instance_id} not found in registry")
                return False
            
            engine_type = self.instance_registry[instance_id]
            engine = self.engines[engine_type]
            
            try:
                success = engine.stop_instance(instance_id)
                if success:
                    del self.instance_registry[instance_id]
                    logger.info(f"Stopped {engine_type} instance {instance_id}")
                return success
                
            except Exception as e:
                logger.error(f"Error stopping instance {instance_id}: {e}")
                return False
    
    def get_instance_status(self, instance_id: str) -> Dict:
        """Get status of a specific instance"""
        if instance_id not in self.instance_registry:
            return {"error": "Instance not found"}
        
        engine_type = self.instance_registry[instance_id]
        engine = self.engines[engine_type]
        
        return engine.get_instance_status(instance_id)
    
    def list_instances(self) -> List[Dict]:
        """List all running instances across all engines"""
        instances = []
        
        for instance_id, engine_type in self.instance_registry.items():
            try:
                status = self.get_instance_status(instance_id)
                if "error" not in status:
                    status["engine_type"] = engine_type
                    instances.append(status)
            except Exception as e:
                logger.error(f"Error getting status for instance {instance_id}: {e}")
        
        return instances
    
    def stop_all_instances(self):
        """Stop all running instances"""
        with self.lock:
            instance_ids = list(self.instance_registry.keys())
            for instance_id in instance_ids:
                self.stop_instance(instance_id)
    
    def get_engine_status(self) -> Dict[str, Dict]:
        """Get status of all engines"""
        status = {}
        
        for engine_name, engine in self.engines.items():
            try:
                if hasattr(engine, 'list_instances'):
                    instances = engine.list_instances()
                    status[engine_name] = {
                        "available": True,
                        "instance_count": len(instances),
                        "instances": instances
                    }
                else:
                    status[engine_name] = {
                        "available": True,
                        "instance_count": 0,
                        "instances": []
                    }
            except Exception as e:
                status[engine_name] = {
                    "available": False,
                    "error": str(e),
                    "instance_count": 0,
                    "instances": []
                }
        
        return status
    
    def cleanup(self):
        """Cleanup all resources"""
        logger.info("Cleaning up SITL Manager")
        self.stop_all_instances()
        
        for engine in self.engines.values():
            if hasattr(engine, 'cleanup'):
                engine.cleanup()
