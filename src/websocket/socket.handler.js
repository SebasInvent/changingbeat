const { Server } = require('socket.io');
const logger = require('../utils/logger');
const config = require('../config/env');

/**
 * Manejador de WebSocket con Socket.io
 */
class SocketHandler {
  constructor() {
    this.io = null;
    this.connectedClients = new Map();
  }

  /**
   * Inicializar Socket.io
   */
  initialize(server) {
    this.io = new Server(server, {
      cors: {
        origin: config.security.corsOrigin,
        methods: ['GET', 'POST']
      }
    });

    this.setupEventHandlers();
    logger.info('✅ Socket.io inicializado');
  }

  /**
   * Configurar manejadores de eventos
   */
  setupEventHandlers() {
    this.io.on('connection', (socket) => {
      const clientId = socket.id;
      const clientIp = socket.handshake.address;

      logger.info(`🔌 Cliente conectado: ${clientId} desde ${clientIp}`);
      this.connectedClients.set(clientId, {
        id: clientId,
        ip: clientIp,
        connectedAt: new Date()
      });

      // Enviar estado inicial
      socket.emit('connected', {
        message: 'Conectado al servidor',
        clientId,
        timestamp: new Date()
      });

      // Enviar estadísticas de conexión
      this.emitConnectionStats();

      // Manejar desconexión
      socket.on('disconnect', () => {
        logger.info(`🔌 Cliente desconectado: ${clientId}`);
        this.connectedClients.delete(clientId);
        this.emitConnectionStats();
      });

      // Manejar solicitud de datos
      socket.on('request:data', (data) => {
        logger.debug(`📨 Solicitud de datos de ${clientId}:`, data);
      });

      // Ping/Pong para mantener conexión
      socket.on('ping', () => {
        socket.emit('pong', { timestamp: new Date() });
      });
    });
  }

  /**
   * Emitir nuevo registro de acceso
   */
  emitNewRecord(record) {
    if (!this.io) return;

    logger.info('📤 Emitiendo nuevo registro a todos los clientes');
    
    this.io.emit('record:new', {
      type: 'new_record',
      data: record,
      timestamp: new Date()
    });
  }

  /**
   * Emitir acceso autorizado
   */
  emitAccessGranted(data) {
    if (!this.io) return;

    logger.info(`✅ Acceso autorizado: ${data.userName}`);
    
    this.io.emit('access:granted', {
      type: 'access_granted',
      userName: data.userName,
      userId: data.userId,
      terminalIp: data.terminalIp,
      temperature: data.temperature,
      timestamp: new Date()
    });
  }

  /**
   * Emitir acceso denegado
   */
  emitAccessDenied(data) {
    if (!this.io) return;

    logger.warn(`❌ Acceso denegado: ${data.reason}`);
    
    this.io.emit('access:denied', {
      type: 'access_denied',
      reason: data.reason,
      terminalIp: data.terminalIp,
      temperature: data.temperature,
      timestamp: new Date()
    });
  }

  /**
   * Emitir alerta de temperatura alta
   */
  emitHighTemperature(data) {
    if (!this.io) return;

    logger.warn(`🌡️ Temperatura alta: ${data.temperature}°C`);
    
    this.io.emit('alert:temperature', {
      type: 'high_temperature',
      userName: data.userName,
      temperature: data.temperature,
      terminalIp: data.terminalIp,
      timestamp: new Date()
    });
  }

  /**
   * Emitir cambio de estado de terminal
   */
  emitTerminalStatus(terminalIp, status) {
    if (!this.io) return;

    logger.info(`💻 Terminal ${terminalIp}: ${status}`);
    
    this.io.emit('terminal:status', {
      type: 'terminal_status',
      terminalIp,
      status,
      timestamp: new Date()
    });
  }

  /**
   * Emitir actualización de estadísticas
   */
  emitStatsUpdate(stats) {
    if (!this.io) return;

    this.io.emit('stats:update', {
      type: 'stats_update',
      data: stats,
      timestamp: new Date()
    });
  }

  /**
   * Emitir estadísticas de conexión
   */
  emitConnectionStats() {
    if (!this.io) return;

    this.io.emit('system:clients', {
      type: 'client_count',
      count: this.connectedClients.size,
      timestamp: new Date()
    });
  }

  /**
   * Emitir mensaje personalizado a todos
   */
  broadcast(event, data) {
    if (!this.io) return;

    logger.debug(`📢 Broadcasting: ${event}`);
    this.io.emit(event, data);
  }

  /**
   * Emitir mensaje a un cliente específico
   */
  emitToClient(clientId, event, data) {
    if (!this.io) return;

    const socket = this.io.sockets.sockets.get(clientId);
    if (socket) {
      socket.emit(event, data);
    }
  }

  /**
   * Obtener número de clientes conectados
   */
  getConnectedClientsCount() {
    return this.connectedClients.size;
  }

  /**
   * Obtener información de clientes conectados
   */
  getConnectedClients() {
    return Array.from(this.connectedClients.values());
  }
}

// Exportar instancia única (Singleton)
module.exports = new SocketHandler();
