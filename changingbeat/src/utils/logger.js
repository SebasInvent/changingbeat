const winston = require('winston');
const config = require('../config/env');
const path = require('path');
const fs = require('fs');

// Crear directorio de logs si no existe
const logDir = path.dirname(config.logging.file);
if (!fs.existsSync(logDir)) {
  fs.mkdirSync(logDir, { recursive: true });
}

// Formato personalizado
const customFormat = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.errors({ stack: true }),
  winston.format.printf(({ timestamp, level, message, stack, ...meta }) => {
    let log = `${timestamp} [${level.toUpperCase()}]: ${message}`;
    
    // Agregar metadata si existe
    if (Object.keys(meta).length > 0) {
      log += ` ${JSON.stringify(meta)}`;
    }
    
    // Agregar stack trace si existe
    if (stack) {
      log += `\n${stack}`;
    }
    
    return log;
  })
);

// Crear logger
const logger = winston.createLogger({
  level: config.logging.level,
  format: customFormat,
  transports: [
    // Log de errores
    new winston.transports.File({
      filename: config.logging.errorFile,
      level: 'error',
      maxsize: 5242880, // 5MB
      maxFiles: 5
    }),
    // Log combinado
    new winston.transports.File({
      filename: config.logging.file,
      maxsize: 5242880, // 5MB
      maxFiles: 5
    })
  ],
  // No salir en error no manejado
  exitOnError: false
});

// Si no estamos en producción, log también a consola con colores
if (!config.isProduction) {
  logger.add(new winston.transports.Console({
    format: winston.format.combine(
      winston.format.colorize(),
      winston.format.timestamp({ format: 'HH:mm:ss' }),
      winston.format.printf(({ timestamp, level, message, stack }) => {
        const log = `${timestamp} ${level}: ${message}`;
        return stack ? `${log}\n${stack}` : log;
      })
    )
  }));
}

// Crear método stream para integraciones (ej: morgan)
logger.stream = {
  write: (message) => {
    logger.info(message.trim());
  }
};

module.exports = logger;
