"""
Initialize CloudSITLSIM database
"""

import os
import logging
from pathlib import Path

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def init_database():
    """Initialize the application database"""
    # Create instance directory
    instance_dir = Path("instance")
    instance_dir.mkdir(exist_ok=True)
    
    # Create logs directory
    logs_dir = Path("logs")
    logs_dir.mkdir(exist_ok=True)
    
    # For now, we'll use a simple file-based approach
    # In the future, this will be replaced with SQLAlchemy
    db_file = instance_dir / "cloudsitlsim.db"
    
    if not db_file.exists():
        # Create empty database file
        db_file.touch()
        logger.info(f"Created database file: {db_file}")
    else:
        logger.info(f"Database file already exists: {db_file}")
    
    # Create default configuration if it doesn't exist
    config_file = Path("config/config.yaml")
    if not config_file.exists():
        logger.warning(f"Configuration file not found: {config_file}")
        logger.warning("Please ensure config/config.yaml exists")
    
    logger.info("Database initialization complete")

if __name__ == "__main__":
    init_database()
