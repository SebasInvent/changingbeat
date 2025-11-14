const mongoose = require('mongoose');
const config = require('./env');
const logger = require('../utils/logger');

/**
 * Configuración y conexión a MongoDB
 */
class Database {
  constructor() {
    this.connection = null;
  }

  /**
   * Conectar a MongoDB
   */
  async connect() {
    try {
      console.log('[DEBUG] Iniciando conexión a MongoDB...');
      console.log('[DEBUG] URI:', config.database.uri);
      console.log('[DEBUG] Opciones:', JSON.stringify(config.database.options));
      
      // Configurar mongoose
      mongoose.set('strictQuery', false);

      console.log('[DEBUG] Llamando a mongoose.connect()...');
      // Conectar
      this.connection = await mongoose.connect(
        config.database.uri,
        config.database.options
      );

      console.log('[DEBUG] mongoose.connect() completado');
      logger.info('✅ Conectado a MongoDB exitosamente', {
        host: this.connection.connection.host,
        database: this.connection.connection.name
      });

      // Manejar eventos de conexión
      this.setupEventHandlers();

      return this.connection;
    } catch (error) {
      console.error('[DEBUG] Error en catch:', error);
      logger.error('❌ Error conectando a MongoDB:', error);
      throw error;
    }
  }

  /**
   * Desconectar de MongoDB
   */
  async disconnect() {
    try {
      await mongoose.disconnect();
      logger.info('Desconectado de MongoDB');
    } catch (error) {
      logger.error('Error desconectando de MongoDB:', error);
      throw error;
    }
  }

  /**
   * Configurar manejadores de eventos
   */
  setupEventHandlers() {
    mongoose.connection.on('connected', () => {
      logger.info('Mongoose conectado a MongoDB');
    });

    mongoose.connection.on('error', (err) => {
      logger.error('Error en conexión de Mongoose:', err);
    });

    mongoose.connection.on('disconnected', () => {
      logger.warn('Mongoose desconectado de MongoDB');
    });

    // Manejo de terminación del proceso
    process.on('SIGINT', async () => {
      await this.disconnect();
      process.exit(0);
    });
  }

  /**
   * Obtener estado de la conexión
   */
  getConnectionState() {
    const states = {
      0: 'disconnected',
      1: 'connected',
      2: 'connecting',
      3: 'disconnecting'
    };
    return states[mongoose.connection.readyState];
  }
}

module.exports = new Database();
