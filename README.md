# CloudSITLSIM

**Cloud-based SITL (Software In The Loop) Simulation Platform**

CloudSITLSIM is a comprehensive platform for running multiple PX4 SITL instances on cloud infrastructure, allowing remote QGroundControl connections to control simulated aircraft through a web interface.

## Features

- **Multi-Instance SITL Management**: Run multiple PX4 SITL instances simultaneously
- **Web-Based Interface**: Easy-to-use dashboard for managing aircraft simulations
- **Remote Access**: Allow QGroundControl connections from any location
- **Aircraft Type Support**: Support for various PX4 aircraft models (X500, Solo, Iris, etc.)
- **Real-time Monitoring**: Live status updates and instance management
- **Resource Management**: Automatic port allocation and process monitoring
- **Cloud-Ready**: Designed for deployment on Azure VMs and other cloud platforms

## Quick Start

### Prerequisites

- Ubuntu 22.04 LTS (recommended for Azure VMs)
- Python 3.10+
- sudo privileges
- Internet connection for downloading dependencies

### Installation

1. **Clone or download the project**:
   ```bash
   # If you have git access
   git clone <repository-url> CloudSITLSIM
   cd CloudSITLSIM
   
   # Or extract from downloaded archive
   cd CloudSITLSIM
   ```

2. **Run the installation script**:
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

   This will:
   - Install all system dependencies
   - Download and build PX4-Autopilot
   - Install Python dependencies
   - Set up the application database
   - Configure the system

3. **Start the application**:
   ```bash
   ./start_cloudsitlsim.sh
   ```

4. **Access the web interface**:
   Open your browser to `http://your-server-ip:5000`

### Quick Test (Single Instance)

For a quick test of PX4 SITL without the web interface:

```bash
./start_px4_sitl.sh x500 14550
```

This will start a single PX4 SITL instance with an X500 quadcopter on port 14550.

## Usage

### Web Interface

1. **Dashboard**: View system status and running instances
2. **Start Instance**: Create new SITL instances with different aircraft types
3. **Monitor**: Real-time status updates and resource usage
4. **Manage**: Start, stop, and monitor instances

### API Endpoints

The application provides a REST API for programmatic access:

- `GET /api/status` - System status
- `GET /api/aircraft` - Available aircraft types
- `GET /api/instances` - List running instances
- `POST /api/instances` - Start new instance
- `GET /api/instances/{id}` - Get instance status
- `DELETE /api/instances/{id}` - Stop instance

### QGroundControl Connection

To connect QGroundControl to your SITL instances:

1. Open QGroundControl
2. Go to Application Settings > Comm Links
3. Add new connection
4. Select "UDP"
5. Set Host to your server's IP address
6. Set Port to the instance's assigned port (shown in web interface)

## Configuration

### Main Configuration (`config/config.yaml`)

```yaml
# Application settings
app:
  host: "0.0.0.0"
  port: 5000
  debug: false

# PX4 settings
px4:
  path: "sitl_engines/px4/PX4-Autopilot"
  max_instances: 10

# MAVLink settings
mavlink:
  port_range:
    start: 14550
    end: 14600
```

### Aircraft Configuration

Supported aircraft types are defined in `config/config.yaml`:

```yaml
aircraft:
  default_types:
    - name: "x500"
      description: "X500 Quadcopter"
    - name: "solo"
      description: "3DR Solo Quadcopter"
    - name: "iris"
      description: "Iris Quadcopter"
```

## Architecture

### Components

1. **SITL Manager**: High-level management of SITL instances
2. **PX4 Engine**: PX4-specific process management
3. **Web Interface**: Flask-based dashboard and API
4. **MAVLink Router**: External communication routing

### Directory Structure

```
CloudSITLSIM/
├── app/                    # Main application code
│   ├── sitl/              # SITL management
│   ├── api/               # REST API endpoints
│   └── gui/               # Web interface routes
├── config/                # Configuration files
├── sitl_engines/          # SITL engine repositories
│   └── px4/              # PX4-Autopilot installation
├── static/               # Web assets (CSS, JS)
├── templates/            # HTML templates
├── logs/                 # Application logs
└── instance/             # Database and runtime files
```

## Development

### Project Structure

- **`setup.sh`**: Main installation script
- **`setup_px4.sh`**: PX4-specific setup
- **`setup_dependencies.sh`**: System dependencies
- **`app.py`**: Main Flask application
- **`init_db.py`**: Database initialization

### Adding New Aircraft Types

1. Ensure the aircraft model exists in PX4
2. Add configuration to `config/config.yaml`
3. Test with the web interface

### Extending Functionality

The modular architecture allows for easy extension:

- Add new SITL engines (ArduPilot, etc.)
- Implement additional web interface features
- Add telemetry and logging capabilities

## Troubleshooting

### Common Issues

1. **PX4 Build Fails**:
   ```bash
   cd sitl_engines/px4/PX4-Autopilot
   make clean
   make px4_sitl
   ```

2. **Port Already in Use**:
   - Check for existing processes: `sudo netstat -tulpn | grep 14550`
   - Kill existing processes: `sudo pkill -f px4`
   - Restart the application

3. **Permission Denied**:
   ```bash
   sudo chown -R $USER:$USER .
   chmod +x *.sh
   ```

4. **MAVLink Router Issues**:
   ```bash
   sudo apt-get update
   sudo apt-get install mavlink-router
   ```

### Logs

Check application logs in the `logs/` directory:
```bash
tail -f logs/cloudsitlsim.log
```

### System Requirements

**Minimum Requirements**:
- 2 CPU cores
- 4 GB RAM
- 10 GB disk space
- Ubuntu 22.04 LTS

**Recommended for Production**:
- 4+ CPU cores
- 8+ GB RAM
- 20+ GB disk space
- Azure Standard_B2s or larger

## Security Considerations

- The current implementation is designed for development/testing
- For production use, implement:
  - User authentication
  - HTTPS/TLS encryption
  - Firewall configuration
  - Input validation and sanitization

## Roadmap

### Phase 1 (Current) - Basic Functionality
- [x] Single PX4 SITL instance management
- [x] Web-based dashboard
- [x] Basic API endpoints
- [x] Installation scripts

### Phase 2 - Multi-Instance Support
- [ ] Multiple concurrent SITL instances
- [ ] Dynamic port allocation
- [ ] Resource monitoring
- [ ] Instance lifecycle management

### Phase 3 - Enhanced Features
- [ ] User authentication
- [ ] Telemetry display
- [ ] Mission upload support
- [ ] Advanced monitoring

### Phase 4 - Production Features
- [ ] Docker deployment
- [ ] SSL/HTTPS support
- [ ] Load balancing
- [ ] Backup and recovery

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review the logs
3. Create an issue with detailed information
4. Include system information and error messages

## Acknowledgments

- PX4 Development Team for the excellent SITL framework
- MAVLink community for communication protocols
- Flask and Bootstrap communities for web frameworks
