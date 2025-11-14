require('dotenv').config();
const http = require('http');
const createApp = require('./app');
const database = require('./config/database');
const config = require('./config/env');
const logger = require('./utils/logger');
const { serialService } = require('./services');

/**
 * Inicializar y arrancar el servidor
 */
const startServer = async () => {
  try {
    // Banner
    logger.info('=====================================');
    logger.info('Sistema de Control de Acceso v2.0');
    logger.info('=====================================');

    // Conectar a MongoDB
    logger.info('Conectando a MongoDB...');
    await database.connect();

    // Crear app Express
    const app = createApp();

    // Crear servidor HTTP
    const server = http.createServer(app);

    // Inicializar WebSocket
    const socketHandler = require('./websocket/socket.handler');
    socketHandler.initialize(server);
    logger.info('WebSocket inicializado');

    // Inicializar puerto serial (si está configurado)
    if (config.serialPort.path) {
      try {
        logger.info('Inicializando puerto serial...');
        await serialService.initialize();
        
        // Configurar callback para datos del serial
        serialService.onData((data) => {
          logger.info('Datos MRZ recibidos:', data);
          // TODO: Emitir evento WebSocket si está configurado
        });
      } catch (error) {
        logger.warn('No se pudo inicializar puerto serial:', error.message);
        logger.warn('El sistema continuará sin lectura de cédulas');
      }
    }

    // Iniciar servidor
    server.listen(config.server.port, config.server.host, () => {
      logger.info(`🚀 Servidor corriendo en http://${config.server.host}:${config.server.port}`);
      logger.info(`📚 Documentación API: http://${config.server.host}:${config.server.port}/api-docs`);
      logger.info(`💚 Health check: http://${config.server.host}:${config.server.port}/api/v1/health`);
      logger.info(`🌍 Ambiente: ${config.env}`);
      logger.info('=====================================');
    });

    // Manejo de señales de terminación
    const gracefulShutdown = async (signal) => {
      logger.info(`\n${signal} recibido. Cerrando servidor gracefully...`);

      server.close(async () => {
        logger.info('Servidor HTTP cerrado');

        try {
          // Cerrar conexión a BD
          await database.disconnect();
          
          // Cerrar puerto serial si está abierto
          if (serialService.isConnected) {
            await serialService.close();
          }

          logger.info('✅ Shutdown completo');
          process.exit(0);
        } catch (error) {
          logger.error('Error durante shutdown:', error);
          process.exit(1);
        }
      });

      // Forzar cierre después de 10 segundos
      setTimeout(() => {
        logger.error('Forzando cierre después de timeout');
        process.exit(1);
      }, 10000);
    };

    // Listeners de señales
    process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
    process.on('SIGINT', () => gracefulShutdown('SIGINT'));

    // Manejo de errores no capturados
    process.on('uncaughtException', (error) => {
      logger.error('Uncaught Exception:', error);
      gracefulShutdown('uncaughtException');
    });

    process.on('unhandledRejection', (reason, promise) => {
      logger.error('Unhandled Rejection at:', promise, 'reason:', reason);
      gracefulShutdown('unhandledRejection');
    });

  } catch (error) {
    logger.error('Error fatal al iniciar servidor:', error);
    process.exit(1);
  }
};

// Iniciar servidor
startServer();

module.exports = startServer;
