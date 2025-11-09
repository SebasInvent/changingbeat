// WebSocket Client para Dashboard

// Variables globales
let socket = null;
let liveEventCounter = 0;
const MAX_LIVE_EVENTS = 20;

/**
 * Inicializar conexión WebSocket
 */
function initializeWebSocket() {
  console.log('🔌 Inicializando WebSocket...');
  
  // Conectar a Socket.io
  socket = io({
    reconnection: true,
    reconnectionDelay: 1000,
    reconnectionAttempts: 5
  });

  // Evento: Conectado
  socket.on('connected', (data) => {
    console.log('✅ WebSocket conectado:', data);
    updateWebSocketStatus(true);
    showNotification('Conectado al servidor', 'success');
  });

  // Evento: Desconectado
  socket.on('disconnect', () => {
    console.log('❌ WebSocket desconectado');
    updateWebSocketStatus(false);
  });

  // Evento: Error
  socket.on('connect_error', (error) => {
    console.error('❌ Error de conexión WebSocket:', error);
    updateWebSocketStatus(false);
  });

  // Evento: Reconectando
  socket.on('reconnecting', (attemptNumber) => {
    console.log(`🔄 Reconectando... Intento ${attemptNumber}`);
  });

  // Evento: Nuevo registro
  socket.on('record:new', (data) => {
    console.log('📝 Nuevo registro:', data);
    handleNewRecord(data);
  });

  // Evento: Acceso autorizado
  socket.on('access:granted', (data) => {
    console.log('✅ Acceso autorizado:', data);
    handleAccessGranted(data);
  });

  // Evento: Acceso denegado
  socket.on('access:denied', (data) => {
    console.log('❌ Acceso denegado:', data);
    handleAccessDenied(data);
  });

  // Evento: Alerta de temperatura
  socket.on('alert:temperature', (data) => {
    console.log('🌡️ Alerta de temperatura:', data);
    handleTemperatureAlert(data);
  });

  // Evento: Estado de terminal
  socket.on('terminal:status', (data) => {
    console.log('💻 Estado de terminal:', data);
    handleTerminalStatus(data);
  });

  // Evento: Actualización de estadísticas
  socket.on('stats:update', (data) => {
    console.log('📊 Actualización de estadísticas:', data);
    // Recargar estadísticas
    loadAllData();
  });

  // Evento: Número de clientes conectados
  socket.on('system:clients', (data) => {
    console.log(`👥 Clientes conectados: ${data.count}`);
  });
}

/**
 * Actualizar estado de WebSocket en UI
 */
function updateWebSocketStatus(connected) {
  const statusIcon = document.querySelector('#websocket-status .fa-circle');
  const statusText = document.getElementById('ws-status-text');
  const systemStatus = document.getElementById('system-status');

  if (connected) {
    statusIcon.className = 'fas fa-circle connected';
    statusText.textContent = 'WebSocket Conectado';
    systemStatus.textContent = 'Online';
    systemStatus.className = 'badge bg-success';
  } else {
    statusIcon.className = 'fas fa-circle text-danger';
    statusText.textContent = 'WebSocket Desconectado';
    systemStatus.textContent = 'Offline';
    systemStatus.className = 'badge bg-danger';
  }
}

/**
 * Manejar nuevo registro
 */
function handleNewRecord(data) {
  // Actualizar contador de eventos
  liveEventCounter++;
  document.getElementById('live-counter').textContent = `${liveEventCounter} eventos`;

  // Agregar al stream de actividad
  addToLiveStream(data);

  // Actualizar tabla de registros recientes
  loadRecentRecords();

  // Actualizar estadísticas
  loadTodayStats();
}

/**
 * Manejar acceso autorizado
 */
function handleAccessGranted(data) {
  const { userName, terminalIp, temperature } = data;

  // Mostrar notificación
  showNotification(
    `✅ Acceso Autorizado`,
    'success',
    `${userName} - Terminal ${terminalIp}${temperature ? ` - ${temperature}°C` : ''}`
  );

  // Reproducir sonido (opcional)
  playNotificationSound('success');

  // Agregar al stream
  addActivityToStream({
    type: 'success',
    icon: 'fa-check-circle',
    title: 'Acceso Autorizado',
    user: userName,
    terminal: terminalIp,
    temperature,
    timestamp: new Date()
  });
}

/**
 * Manejar acceso denegado
 */
function handleAccessDenied(data) {
  const { reason, terminalIp, temperature } = data;

  // Mostrar notificación
  showNotification(
    `❌ Acceso Denegado`,
    'danger',
    `${reason} - Terminal ${terminalIp}${temperature ? ` - ${temperature}°C` : ''}`
  );

  // Reproducir sonido de alerta
  playNotificationSound('error');

  // Agregar al stream
  addActivityToStream({
    type: 'danger',
    icon: 'fa-times-circle',
    title: 'Acceso Denegado',
    user: reason,
    terminal: terminalIp,
    temperature,
    timestamp: new Date()
  });
}

/**
 * Manejar alerta de temperatura
 */
function handleTemperatureAlert(data) {
  const { userName, temperature, terminalIp } = data;

  // Mostrar notificación prominente
  showNotification(
    `🌡️ ALERTA: Temperatura Elevada`,
    'warning',
    `${userName}: ${temperature}°C - Terminal ${terminalIp}`,
    10000 // Duración más larga
  );

  // Reproducir sonido de alerta
  playNotificationSound('warning');

  // Agregar al stream
  addActivityToStream({
    type: 'warning',
    icon: 'fa-thermometer-full',
    title: 'Temperatura Elevada',
    user: userName,
    terminal: terminalIp,
    temperature,
    timestamp: new Date()
  });
}

/**
 * Manejar estado de terminal
 */
function handleTerminalStatus(data) {
  const { terminalIp, status } = data;

  // Mostrar notificación
  const statusText = status === 'online' ? 'Conectado' : 'Desconectado';
  const type = status === 'online' ? 'success' : 'warning';

  showNotification(
    `💻 Terminal ${statusText}`,
    type,
    `Terminal ${terminalIp}`
  );

  // Actualizar estado de terminales
  loadTerminalStatus();
}

/**
 * Agregar evento al stream de actividad
 */
function addActivityToStream(activity) {
  const stream = document.getElementById('live-activity-stream');
  
  // Limpiar mensaje de "esperando"
  if (stream.querySelector('.text-muted')) {
    stream.innerHTML = '';
  }

  const time = new Date(activity.timestamp).toLocaleTimeString('es-ES');
  const tempText = activity.temperature ? `${activity.temperature}°C` : 'N/A';

  const item = document.createElement('div');
  item.className = `activity-item new ${activity.type}`;
  item.innerHTML = `
    <div class="d-flex align-items-center">
      <i class="fas ${activity.icon} fa-lg me-3 text-${activity.type}"></i>
      <div class="flex-grow-1">
        <strong>${activity.title}</strong>
        <div class="small text-muted">
          ${activity.user} | Terminal ${activity.terminal} | ${tempText}
        </div>
      </div>
      <div class="text-end">
        <small class="text-muted">${time}</small>
      </div>
    </div>
  `;

  // Agregar al inicio
  stream.insertBefore(item, stream.firstChild);

  // Limitar número de eventos mostrados
  while (stream.children.length > MAX_LIVE_EVENTS) {
    stream.removeChild(stream.lastChild);
  }

  // Scroll automático si está cerca del top
  if (stream.scrollTop < 50) {
    stream.scrollTop = 0;
  }
}

/**
 * Mostrar notificación toast
 */
function showNotification(title, type = 'info', message = '', duration = 5000) {
  const container = document.getElementById('notifications-container');
  
  const notification = document.createElement('div');
  notification.className = `notification-toast ${type}`;
  notification.innerHTML = `
    <div class="d-flex align-items-start">
      <div class="flex-grow-1">
        <strong>${title}</strong>
        ${message ? `<div class="small mt-1">${message}</div>` : ''}
      </div>
      <button type="button" class="btn-close btn-close-sm ms-2" onclick="this.parentElement.parentElement.remove()"></button>
    </div>
  `;

  container.appendChild(notification);

  // Auto-remover después de la duración
  setTimeout(() => {
    notification.style.animation = 'slideOutRight 0.3s ease-out';
    setTimeout(() => notification.remove(), 300);
  }, duration);
}

/**
 * Reproducir sonido de notificación
 */
function playNotificationSound(type) {
  // Crear contexto de audio
  const audioContext = new (window.AudioContext || window.webkitAudioContext)();
  const oscillator = audioContext.createOscillator();
  const gainNode = audioContext.createGain();

  oscillator.connect(gainNode);
  gainNode.connect(audioContext.destination);

  // Configurar frecuencia según tipo
  const frequencies = {
    success: 800,
    error: 400,
    warning: 600
  };

  oscillator.frequency.value = frequencies[type] || 600;
  oscillator.type = 'sine';

  // Configurar volumen
  gainNode.gain.setValueAtTime(0.1, audioContext.currentTime);
  gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.1);

  // Reproducir
  oscillator.start(audioContext.currentTime);
  oscillator.stop(audioContext.currentTime + 0.1);
}

/**
 * Solicitar permiso para notificaciones del navegador
 */
function requestNotificationPermission() {
  if ('Notification' in window && Notification.permission === 'default') {
    Notification.requestPermission().then(permission => {
      if (permission === 'granted') {
        console.log('✅ Permisos de notificación otorgados');
      }
    });
  }
}

/**
 * Mostrar notificación del navegador
 */
function showBrowserNotification(title, options = {}) {
  if ('Notification' in window && Notification.permission === 'granted') {
    new Notification(title, {
      icon: '/favicon.ico',
      badge: '/favicon.ico',
      ...options
    });
  }
}

// Inicializar WebSocket cuando el DOM esté listo
document.addEventListener('DOMContentLoaded', function() {
  initializeWebSocket();
  requestNotificationPermission();
});
