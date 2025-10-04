// CloudSITLSIM JavaScript Application

// Global configuration
const CONFIG = {
    refreshInterval: 5000, // 5 seconds
    apiBaseUrl: '/api'
};

// Utility functions
function formatUptime(seconds) {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = Math.floor(seconds % 60);
    
    if (hours > 0) {
        return `${hours}h ${minutes}m`;
    } else if (minutes > 0) {
        return `${minutes}m ${secs}s`;
    } else {
        return `${secs}s`;
    }
}

function formatBytes(bytes) {
    if (bytes === 0) return '0 Bytes';
    
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

function formatCPUPercent(percent) {
    return `${percent.toFixed(1)}%`;
}

// API functions
async function apiRequest(endpoint, options = {}) {
    const url = `${CONFIG.apiBaseUrl}${endpoint}`;
    const defaultOptions = {
        headers: {
            'Content-Type': 'application/json'
        }
    };
    
    const mergedOptions = { ...defaultOptions, ...options };
    
    try {
        const response = await fetch(url, mergedOptions);
        const data = await response.json();
        
        if (!response.ok) {
            throw new Error(data.error || `HTTP ${response.status}`);
        }
        
        return data;
    } catch (error) {
        console.error(`API request failed for ${endpoint}:`, error);
        throw error;
    }
}

// System status functions
async function loadSystemStatus() {
    try {
        const status = await apiRequest('/status');
        updateSystemStatus(status);
        return status;
    } catch (error) {
        updateSystemStatusError(error);
        throw error;
    }
}

function updateSystemStatus(status) {
    // Update navbar status
    const statusElement = document.getElementById('system-status');
    if (statusElement) {
        const badgeClass = status.system === 'online' ? 'bg-success' : 'bg-danger';
        statusElement.innerHTML = `<span class="badge ${badgeClass}">${status.system}</span>`;
    }
    
    // Update system status content
    const contentElement = document.getElementById('system-status-content');
    if (contentElement) {
        let html = '<div class="row">';
        
        // Engine status
        for (const [engine, engineStatus] of Object.entries(status.engines)) {
            const badgeClass = engineStatus.available ? 'bg-success' : 'bg-danger';
            const statusText = engineStatus.available ? 'Available' : 'Unavailable';
            
            html += `
                <div class="col-md-6 mb-2">
                    <div class="d-flex justify-content-between align-items-center">
                        <strong>${engine.toUpperCase()}</strong>
                        <span class="badge ${badgeClass}">${statusText}</span>
                    </div>
                    <small class="text-muted">${engineStatus.instance_count} instances</small>
                </div>
            `;
        }
        
        html += '</div>';
        
        // Add instance summary
        if (status.instances && status.instances.length > 0) {
            html += '<hr>';
            html += '<div class="row">';
            html += `
                <div class="col-12">
                    <h6>Instance Summary</h6>
                    <p class="mb-0">Total instances: <strong>${status.instances.length}</strong></p>
                </div>
            `;
            html += '</div>';
        }
        
        contentElement.innerHTML = html;
    }
}

function updateSystemStatusError(error) {
    const statusElement = document.getElementById('system-status');
    if (statusElement) {
        statusElement.innerHTML = '<span class="badge bg-danger">Error</span>';
    }
    
    const contentElement = document.getElementById('system-status-content');
    if (contentElement) {
        contentElement.innerHTML = `
            <div class="alert alert-danger">
                <strong>Error loading system status:</strong> ${error.message}
            </div>
        `;
    }
}

// Instance management functions
async function loadInstances() {
    try {
        const instances = await apiRequest('/instances');
        updateInstancesDisplay(instances);
        return instances;
    } catch (error) {
        updateInstancesError(error);
        throw error;
    }
}

function updateInstancesDisplay(instances) {
    const contentElement = document.getElementById('instances-content');
    if (!contentElement) return;
    
    if (instances.length === 0) {
        contentElement.innerHTML = `
            <div class="text-center text-muted py-4">
                <i class="fas fa-plane-slash fa-3x mb-3"></i>
                <p>No instances running</p>
                <p class="small">Start an instance to see it here</p>
            </div>
        `;
        return;
    }
    
    let html = '<div class="table-responsive"><table class="table table-striped table-hover">';
    html += `
        <thead class="table-dark">
            <tr>
                <th>Instance ID</th>
                <th>Aircraft Type</th>
                <th>Engine</th>
                <th>Port</th>
                <th>Status</th>
                <th>Uptime</th>
                <th>Connection</th>
                <th>Actions</th>
            </tr>
        </thead>
        <tbody>
    `;
    
    instances.forEach(instance => {
        const statusBadge = getStatusBadge(instance.status);
        const uptime = formatUptime(instance.uptime || 0);
        
        html += `
            <tr class="instance-row">
                <td><code class="small">${instance.instance_id}</code></td>
                <td>${instance.aircraft_type}</td>
                <td><span class="badge bg-info">${instance.engine_type || 'px4'}</span></td>
                <td>${instance.port}</td>
                <td>${statusBadge}</td>
                <td>${uptime}</td>
                <td>
                    <button class="btn btn-sm btn-outline-primary" 
                            onclick="showConnectionInfo('${instance.instance_id}', ${instance.port})">
                        <i class="fas fa-info-circle"></i> Info
                    </button>
                </td>
                <td>
                    <button class="btn btn-sm btn-outline-danger" 
                            onclick="stopInstance('${instance.instance_id}')">
                        <i class="fas fa-stop"></i> Stop
                    </button>
                </td>
            </tr>
        `;
    });
    
    html += '</tbody></table></div>';
    contentElement.innerHTML = html;
}

function getStatusBadge(status) {
    const statusMap = {
        'running': 'bg-success',
        'starting': 'bg-warning',
        'stopped': 'bg-secondary',
        'failed': 'bg-danger',
        'error': 'bg-danger'
    };
    
    const badgeClass = statusMap[status] || 'bg-secondary';
    return `<span class="badge ${badgeClass}">${status}</span>`;
}

function updateInstancesError(error) {
    const contentElement = document.getElementById('instances-content');
    if (contentElement) {
        contentElement.innerHTML = `
            <div class="alert alert-danger">
                <strong>Error loading instances:</strong> ${error.message}
            </div>
        `;
    }
}

// Aircraft management functions
async function loadAircraftTypes() {
    try {
        const aircraft = await apiRequest('/aircraft');
        updateAircraftSelect(aircraft);
        return aircraft;
    } catch (error) {
        console.error('Error loading aircraft types:', error);
        throw error;
    }
}

function updateAircraftSelect(aircraft) {
    const selectElement = document.getElementById('aircraftType');
    if (!selectElement) return;
    
    selectElement.innerHTML = '<option value="">Select aircraft type...</option>';
    
    for (const [engine, types] of Object.entries(aircraft)) {
        if (types.length > 0) {
            const optgroup = document.createElement('optgroup');
            optgroup.label = engine.toUpperCase();
            
            types.forEach(type => {
                const option = document.createElement('option');
                option.value = type.name;
                option.textContent = `${type.name} - ${type.description || 'No description'}`;
                optgroup.appendChild(option);
            });
            
            selectElement.appendChild(optgroup);
        }
    }
}

// Instance control functions
async function startInstance(engineType, aircraftType, instanceId = null) {
    const data = {
        engine: engineType,
        aircraft_type: aircraftType
    };
    
    if (instanceId) {
        data.instance_id = instanceId;
    }
    
    try {
        const result = await apiRequest('/instances', {
            method: 'POST',
            body: JSON.stringify(data)
        });
        
        return result;
    } catch (error) {
        throw error;
    }
}

async function stopInstance(instanceId) {
    try {
        const result = await apiRequest(`/instances/${instanceId}`, {
            method: 'DELETE'
        });
        
        return result;
    } catch (error) {
        throw error;
    }
}

// UI helper functions
function showQGCConnectionInfo(instanceId, port) {
    const host = window.location.hostname;
    
    // Create modal HTML
    const modalHtml = `
        <div class="modal fade" id="connectionModal" tabindex="-1">
            <div class="modal-dialog modal-lg">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title">QGroundControl Connection Info</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                    </div>
                    <div class="modal-body">
                        <div class="connection-details">
                            <h6>Connection Parameters</h6>
                            <div class="connection-param">
                                <span class="param-name">Connection Type:</span>
                                <span class="param-value">UDP</span>
                            </div>
                            <div class="connection-param">
                                <span class="param-name">Host/IP Address:</span>
                                <span class="param-value">${host}</span>
                                <button class="btn btn-sm btn-outline-light ms-2" onclick="copyToClipboard('${host}')">Copy</button>
                            </div>
                            <div class="connection-param">
                                <span class="param-name">Port:</span>
                                <span class="param-value">${port}</span>
                                <button class="btn btn-sm btn-outline-light ms-2" onclick="copyToClipboard('${port}')">Copy</button>
                            </div>
                        </div>
                        
                        <div class="mt-4">
                            <h6>Step-by-Step Instructions</h6>
                            <ol>
                                <li>Open <strong>QGroundControl</strong></li>
                                <li>Go to <strong>Application Settings</strong> (gear icon)</li>
                                <li>Select <strong>"Comm Links"</strong> tab</li>
                                <li>Click <strong>"Add"</strong> to create new connection</li>
                                <li>Select <strong>"UDP"</strong> as connection type</li>
                                <li>Set <strong>Host</strong> to: <code>${host}</code></li>
                                <li>Set <strong>Port</strong> to: <code>${port}</code></li>
                                <li>Click <strong>"OK"</strong> to save</li>
                                <li>Select the new connection and click <strong>"Connect"</strong></li>
                            </ol>
                        </div>
                        
                        <div class="alert alert-info mt-3">
                            <strong>Note:</strong> Make sure your firewall allows connections on port ${port}.
                            The connection will be established automatically once configured.
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                        <button type="button" class="btn btn-primary" onclick="copyAllConnectionInfo('${host}', '${port}')">Copy All Info</button>
                    </div>
                </div>
            </div>
        </div>
    `;
    
    // Remove existing modal if any
    const existingModal = document.getElementById('connectionModal');
    if (existingModal) {
        existingModal.remove();
    }
    
    // Add modal to body
    document.body.insertAdjacentHTML('beforeend', modalHtml);
    
    // Show modal
    const modal = new bootstrap.Modal(document.getElementById('connectionModal'));
    modal.show();
    
    // Remove modal from DOM when hidden
    document.getElementById('connectionModal').addEventListener('hidden.bs.modal', function () {
        this.remove();
    });
}

function copyAllConnectionInfo(host, port) {
    const connectionText = `QGroundControl Connection Info:
Connection Type: UDP
Host/IP Address: ${host}
Port: ${port}

Steps:
1. Open QGroundControl
2. Go to Application Settings > Comm Links
3. Add new UDP connection
4. Set Host: ${host}
5. Set Port: ${port}
6. Connect`;
    
    copyToClipboard(connectionText);
}

function copyToClipboard(text) {
    navigator.clipboard.writeText(text).then(() => {
        // Show a temporary success message
        const button = event.target;
        const originalText = button.textContent;
        button.textContent = 'Copied!';
        button.classList.add('btn-success');
        button.classList.remove('btn-outline-primary');
        
        setTimeout(() => {
            button.textContent = originalText;
            button.classList.remove('btn-success');
            button.classList.add('btn-outline-primary');
        }, 2000);
    }).catch(err => {
        console.error('Failed to copy to clipboard:', err);
    });
}

// Auto-refresh functionality
let refreshInterval = null;

function startAutoRefresh() {
    if (refreshInterval) {
        clearInterval(refreshInterval);
    }
    
    refreshInterval = setInterval(async () => {
        try {
            await Promise.all([
                loadSystemStatus(),
                loadInstances()
            ]);
        } catch (error) {
            console.error('Auto-refresh error:', error);
        }
    }, CONFIG.refreshInterval);
}

function stopAutoRefresh() {
    if (refreshInterval) {
        clearInterval(refreshInterval);
        refreshInterval = null;
    }
}

// Initialize application
document.addEventListener('DOMContentLoaded', function() {
    console.log('CloudSITLSIM initialized');
    
    // Load initial data
    loadSystemStatus();
    loadInstances();
    loadAircraftTypes();
    
    // Start auto-refresh
    startAutoRefresh();
});

// Cleanup on page unload
window.addEventListener('beforeunload', function() {
    stopAutoRefresh();
});
