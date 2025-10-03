"""
CloudSITLSIM - Main Application Entry Point
"""

import os
import sys
import logging
import yaml
from pathlib import Path
from flask import Flask, render_template, jsonify, request
from werkzeug.exceptions import BadRequest

# Add app directory to Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'app'))

from app.sitl.manager import SITLManager

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def load_config():
    """Load configuration from YAML file"""
    config_path = Path("config/config.yaml")
    if not config_path.exists():
        raise FileNotFoundError(f"Configuration file not found: {config_path}")
    
    with open(config_path, 'r') as f:
        config = yaml.safe_load(f)
    
    return config

def create_app():
    """Create and configure Flask application"""
    app = Flask(__name__)
    
    # Load configuration
    try:
        config = load_config()
        app.config.update(config.get('app', {}))
    except Exception as e:
        logger.error(f"Failed to load configuration: {e}")
        # Use default configuration
        app.config.update({
            'SECRET_KEY': 'dev-secret-key-change-in-production',
            'DEBUG': True,
            'HOST': '0.0.0.0',
            'PORT': 5000
        })
        config = {}
    
    # Initialize SITL Manager
    try:
        sitl_manager = SITLManager(config)
        app.sitl_manager = sitl_manager
    except Exception as e:
        logger.error(f"Failed to initialize SITL Manager: {e}")
        sitl_manager = None
        app.sitl_manager = None
    
    @app.route('/')
    def index():
        """Main dashboard page"""
        return render_template('index.html', 
                             title=config.get('web', {}).get('title', 'CloudSITLSIM'))
    
    @app.route('/api/status')
    def api_status():
        """Get system status"""
        if not app.sitl_manager:
            return jsonify({"error": "SITL Manager not initialized"}), 500
        
        try:
            status = {
                "system": "online",
                "engines": app.sitl_manager.get_engine_status(),
                "instances": app.sitl_manager.list_instances()
            }
            return jsonify(status)
        except Exception as e:
            logger.error(f"Error getting system status: {e}")
            return jsonify({"error": str(e)}), 500
    
    @app.route('/api/aircraft')
    def api_aircraft():
        """Get available aircraft types"""
        if not app.sitl_manager:
            return jsonify({"error": "SITL Manager not initialized"}), 500
        
        try:
            aircraft = app.sitl_manager.get_available_aircraft()
            return jsonify(aircraft)
        except Exception as e:
            logger.error(f"Error getting aircraft types: {e}")
            return jsonify({"error": str(e)}), 500
    
    @app.route('/api/instances', methods=['GET'])
    def api_list_instances():
        """List all running instances"""
        if not app.sitl_manager:
            return jsonify({"error": "SITL Manager not initialized"}), 500
        
        try:
            instances = app.sitl_manager.list_instances()
            return jsonify(instances)
        except Exception as e:
            logger.error(f"Error listing instances: {e}")
            return jsonify({"error": str(e)}), 500
    
    @app.route('/api/instances', methods=['POST'])
    def api_start_instance():
        """Start a new SITL instance"""
        if not app.sitl_manager:
            return jsonify({"error": "SITL Manager not initialized"}), 500
        
        try:
            data = request.get_json()
            if not data:
                raise BadRequest("No JSON data provided")
            
            engine_type = data.get('engine', 'px4')
            aircraft_type = data.get('aircraft_type')
            instance_id = data.get('instance_id')
            
            if not aircraft_type:
                raise BadRequest("aircraft_type is required")
            
            instance_id = app.sitl_manager.start_instance(
                engine_type=engine_type,
                aircraft_type=aircraft_type,
                instance_id=instance_id
            )
            
            return jsonify({
                "success": True,
                "instance_id": instance_id,
                "message": f"Started {engine_type} instance with {aircraft_type}"
            })
            
        except Exception as e:
            logger.error(f"Error starting instance: {e}")
            return jsonify({"error": str(e)}), 500
    
    @app.route('/api/instances/<instance_id>', methods=['GET'])
    def api_get_instance(instance_id):
        """Get status of a specific instance"""
        if not app.sitl_manager:
            return jsonify({"error": "SITL Manager not initialized"}), 500
        
        try:
            status = app.sitl_manager.get_instance_status(instance_id)
            return jsonify(status)
        except Exception as e:
            logger.error(f"Error getting instance status: {e}")
            return jsonify({"error": str(e)}), 500
    
    @app.route('/api/instances/<instance_id>', methods=['DELETE'])
    def api_stop_instance(instance_id):
        """Stop a specific instance"""
        if not app.sitl_manager:
            return jsonify({"error": "SITL Manager not initialized"}), 500
        
        try:
            success = app.sitl_manager.stop_instance(instance_id)
            if success:
                return jsonify({
                    "success": True,
                    "message": f"Stopped instance {instance_id}"
                })
            else:
                return jsonify({
                    "success": False,
                    "message": f"Failed to stop instance {instance_id}"
                }), 500
                
        except Exception as e:
            logger.error(f"Error stopping instance: {e}")
            return jsonify({"error": str(e)}), 500
    
    @app.teardown_appcontext
    def cleanup(error):
        """Cleanup resources on app shutdown"""
        if hasattr(app, 'sitl_manager') and app.sitl_manager:
            app.sitl_manager.cleanup()
    
    return app

if __name__ == '__main__':
    app = create_app()
    
    # Get configuration
    try:
        config = load_config()
        app_config = config.get('app', {})
    except:
        app_config = {}
    
    host = app_config.get('host', '0.0.0.0')
    port = app_config.get('port', 5000)
    debug = app_config.get('debug', False)
    
    logger.info(f"Starting CloudSITLSIM on {host}:{port}")
    
    try:
        app.run(host=host, port=port, debug=debug)
    except KeyboardInterrupt:
        logger.info("Shutting down CloudSITLSIM")
    except Exception as e:
        logger.error(f"Error running application: {e}")
        sys.exit(1)
