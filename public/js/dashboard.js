// Dashboard JavaScript

// Configuration
const API_BASE = '/api/v1';
const REFRESH_INTERVAL = 30000; // 30 segundos

// Chart instances
let recordTypeChart = null;
let hourlyActivityChart = null;
let topTerminalsChart = null;

// Initialize dashboard
document.addEventListener('DOMContentLoaded', function() {
    console.log('Dashboard iniciado');
    initializeCharts();
    loadAllData();
    
    // Auto refresh
    setInterval(loadAllData, REFRESH_INTERVAL);
});

// Initialize all charts
function initializeCharts() {
    // Record Type Pie Chart
    const recordTypeCtx = document.getElementById('recordTypeChart');
    if (recordTypeCtx) {
        recordTypeChart = new Chart(recordTypeCtx, {
            type: 'doughnut',
            data: {
                labels: ['Entradas', 'Salidas', 'Denegados'],
                datasets: [{
                    data: [0, 0, 0],
                    backgroundColor: ['#1cc88a', '#36b9cc', '#f6c23e'],
                    borderWidth: 2,
                    borderColor: '#fff'
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: true,
                plugins: {
                    legend: {
                        position: 'bottom'
                    }
                }
            }
        });
    }

    // Hourly Activity Bar Chart
    const hourlyCtx = document.getElementById('hourlyActivityChart');
    if (hourlyCtx) {
        hourlyActivityChart = new Chart(hourlyCtx, {
            type: 'bar',
            data: {
                labels: [],
                datasets: [{
                    label: 'Registros',
                    data: [],
                    backgroundColor: '#4e73df',
                    borderColor: '#4e73df',
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: true,
                scales: {
                    y: {
                        beginAtZero: true,
                        ticks: {
                            precision: 0
                        }
                    }
                },
                plugins: {
                    legend: {
                        display: false
                    }
                }
            }
        });
    }

    // Top Terminals Horizontal Bar Chart
    const topTerminalsCtx = document.getElementById('topTerminalsChart');
    if (topTerminalsCtx) {
        topTerminalsChart = new Chart(topTerminalsCtx, {
            type: 'bar',
            data: {
                labels: [],
                datasets: [{
                    label: 'Registros',
                    data: [],
                    backgroundColor: '#36b9cc',
                    borderColor: '#36b9cc',
                    borderWidth: 1
                }]
            },
            options: {
                indexAxis: 'y',
                responsive: true,
                maintainAspectRatio: true,
                scales: {
                    x: {
                        beginAtZero: true,
                        ticks: {
                            precision: 0
                        }
                    }
                },
                plugins: {
                    legend: {
                        display: false
                    }
                }
            }
        });
    }
}

// Load all dashboard data
async function loadAllData() {
    try {
        await Promise.all([
            loadUserStats(),
            loadTodayStats(),
            loadGeneralStats(),
            loadTerminalStatus(),
            loadRecentRecords()
        ]);
        
        updateLastUpdate();
        updateSystemStatus('Online', 'success');
    } catch (error) {
        console.error('Error cargando datos:', error);
        updateSystemStatus('Error de conexión', 'danger');
    }
}

// Load user statistics
async function loadUserStats() {
    try {
        const response = await fetch(`${API_BASE}/users/stats`);
        if (!response.ok) throw new Error('Error cargando estadísticas de usuarios');
        
        const data = await response.json();
        
        if (data.success && data.data) {
            document.getElementById('total-users').textContent = data.data.total || 0;
        }
    } catch (error) {
        console.error('Error:', error);
        document.getElementById('total-users').textContent = '--';
    }
}

// Load today's statistics
async function loadTodayStats() {
    try {
        const response = await fetch(`${API_BASE}/records/stats/today`);
        if (!response.ok) throw new Error('Error cargando estadísticas del día');
        
        const data = await response.json();
        
        if (data.success && data.data) {
            const stats = data.data;
            document.getElementById('today-records').textContent = stats.total || 0;
            document.getElementById('denied-today').textContent = stats.denied || 0;
            
            // Update pie chart
            if (recordTypeChart) {
                recordTypeChart.data.datasets[0].data = [
                    stats.entry || 0,
                    stats.exit || 0,
                    stats.denied || 0
                ];
                recordTypeChart.update();
            }
        }
    } catch (error) {
        console.error('Error:', error);
        document.getElementById('today-records').textContent = '--';
        document.getElementById('denied-today').textContent = '--';
    }
}

// Load general statistics
async function loadGeneralStats() {
    try {
        const response = await fetch(`${API_BASE}/records/stats`);
        if (!response.ok) throw new Error('Error cargando estadísticas generales');
        
        const data = await response.json();
        
        if (data.success && data.data) {
            const stats = data.data;
            
            // Temperature
            const avgTemp = stats.temperature?.average;
            const tempElement = document.getElementById('avg-temperature');
            if (avgTemp) {
                tempElement.textContent = avgTemp.toFixed(1) + '°C';
                tempElement.className = avgTemp > 37.5 ? 'display-4 mb-3 high' : 'display-4 mb-3 normal';
            } else {
                tempElement.textContent = 'N/A';
            }
            
            document.getElementById('high-temp-count').textContent = stats.temperature?.highCount || 0;
            
            // Top Terminals
            if (stats.topTerminals && topTerminalsChart) {
                const labels = stats.topTerminals.map(t => t.ip);
                const counts = stats.topTerminals.map(t => t.count);
                
                topTerminalsChart.data.labels = labels;
                topTerminalsChart.data.datasets[0].data = counts;
                topTerminalsChart.update();
            }
        }
    } catch (error) {
        console.error('Error:', error);
        document.getElementById('avg-temperature').textContent = '--';
    }
}

// Load terminal status
async function loadTerminalStatus() {
    try {
        const response = await fetch(`${API_BASE}/terminals/status`);
        if (!response.ok) throw new Error('Error cargando estado de terminales');
        
        const data = await response.json();
        
        if (data.success && data.data) {
            const stats = data.data;
            document.getElementById('terminals-online').textContent = 
                `${stats.online}/${stats.total}`;
            
            // Render terminal cards
            renderTerminals(stats.terminals);
        }
    } catch (error) {
        console.error('Error:', error);
        document.getElementById('terminals-online').textContent = '--';
    }
}

// Render terminal status cards
function renderTerminals(terminals) {
    const container = document.getElementById('terminals-status');
    if (!container || !terminals) return;
    
    container.innerHTML = terminals.map(terminal => `
        <div class="col-md-4 mb-3">
            <div class="terminal-card ${terminal.status}">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <h6 class="mb-1">
                            <span class="status-dot ${terminal.status}"></span>
                            ${terminal.terminalIp}
                        </h6>
                        <small class="text-muted">
                            Estado: <span class="badge ${terminal.status === 'online' ? 'bg-success' : 'bg-danger'}">
                                ${terminal.status === 'online' ? 'Online' : 'Offline'}
                            </span>
                        </small>
                    </div>
                    <div>
                        <i class="fas fa-desktop fa-2x ${terminal.status === 'online' ? 'text-success' : 'text-danger'}"></i>
                    </div>
                </div>
            </div>
        </div>
    `).join('');
}

// Load recent records
async function loadRecentRecords() {
    try {
        const response = await fetch(`${API_BASE}/records/recent?limit=10`);
        if (!response.ok) throw new Error('Error cargando registros recientes');
        
        const data = await response.json();
        
        if (data.success && data.data) {
            renderRecentRecords(data.data);
        }
    } catch (error) {
        console.error('Error:', error);
        document.getElementById('recent-records-body').innerHTML = `
            <tr><td colspan="6" class="text-center text-danger">Error cargando registros</td></tr>
        `;
    }
}

// Render recent records table
function renderRecentRecords(records) {
    const tbody = document.getElementById('recent-records-body');
    if (!tbody || !records || records.length === 0) {
        tbody.innerHTML = '<tr><td colspan="6" class="text-center">No hay registros recientes</td></tr>';
        return;
    }
    
    tbody.innerHTML = records.map(record => {
        const date = new Date(record.createdAt);
        const formattedDate = date.toLocaleDateString('es-ES');
        const formattedTime = date.toLocaleTimeString('es-ES');
        
        const userName = record.userId ? 
            `${record.userId.firstName} ${record.userId.lastName}` : 
            'N/A';
        
        const typeClass = {
            'entry': 'success',
            'exit': 'info',
            'denied': 'warning'
        }[record.recordType] || 'secondary';
        
        const typeName = {
            'entry': 'Entrada',
            'exit': 'Salida',
            'denied': 'Denegado'
        }[record.recordType] || record.recordType;
        
        const statusClass = record.status === 'success' ? 'success' : 'danger';
        
        return `
            <tr class="fade-in">
                <td>
                    <small>${formattedDate}</small><br>
                    <strong>${formattedTime}</strong>
                </td>
                <td>${userName}</td>
                <td><code>${record.terminalIp}</code></td>
                <td>
                    <span class="badge bg-${typeClass}">${typeName}</span>
                </td>
                <td>${record.temperature ? record.temperature.toFixed(1) + '°C' : 'N/A'}</td>
                <td>
                    <span class="badge bg-${statusClass}">${record.status}</span>
                </td>
            </tr>
        `;
    }).join('');
}

// Update last update timestamp
function updateLastUpdate() {
    const now = new Date();
    document.getElementById('last-update').textContent = now.toLocaleTimeString('es-ES');
}

// Update system status
function updateSystemStatus(message, type) {
    const statusElement = document.getElementById('system-status');
    if (statusElement) {
        statusElement.textContent = message;
        statusElement.className = `badge bg-${type}`;
    }
}

// Refresh all data manually
function refreshAll() {
    const btn = event.target.closest('button');
    const icon = btn.querySelector('i');
    
    // Animate refresh icon
    icon.classList.add('fa-spin');
    
    loadAllData().finally(() => {
        setTimeout(() => {
            icon.classList.remove('fa-spin');
        }, 1000);
    });
}

// Format number with thousand separators
function formatNumber(num) {
    return new Intl.NumberFormat('es-ES').format(num);
}

// Format date
function formatDate(dateString) {
    const date = new Date(dateString);
    return date.toLocaleDateString('es-ES', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
}
