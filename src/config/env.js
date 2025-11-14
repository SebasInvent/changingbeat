require('dotenv').config();

const config = {
  // Environment
  env: process.env.NODE_ENV || 'development',
  isProduction: process.env.NODE_ENV === 'production',
  isDevelopment: process.env.NODE_ENV === 'development',

  // Server
  server: {
    port: parseInt(process.env.PORT) || 3000,
    host: process.env.HOST || '0.0.0.0'
  },

  // Database
  database: {
    uri: process.env.MONGODB_URI || 'mongodb://localhost:27017/autoregistro',
    options: {
      autoIndex: false,
      maxPoolSize: parseInt(process.env.MONGODB_POOL_SIZE) || 10,
      serverSelectionTimeoutMS: parseInt(process.env.MONGODB_TIMEOUT) || 5000,
      socketTimeoutMS: 45000,
      family: 4
    }
  },

  // JWT
  jwt: {
    secret: process.env.JWT_SECRET || 'your_secret_key',
    expiration: process.env.JWT_EXPIRATION || '24h',
    refreshExpiration: process.env.JWT_REFRESH_EXPIRATION || '7d'
  },

  // Bcrypt
  bcrypt: {
    rounds: parseInt(process.env.BCRYPT_ROUNDS) || 10
  },

  // Serial Port
  serialPort: {
    path: process.env.SERIAL_PORT || 'COM8',
    baudRate: parseInt(process.env.SERIAL_BAUDRATE) || 115200
  },

  // Terminals
  terminals: {
    ips: process.env.TERMINAL_IPS ? 
      process.env.TERMINAL_IPS.split(',').map(ip => ip.trim()) : 
      ['192.168.1.201', '192.168.1.202', '192.168.1.208'],
    baseUrl: process.env.TERMINAL_BASE_URL || 'http://192.168.1.201:8090'
  },

  // External Services
  externalServices: {
    callbackBaseUrl: process.env.CALLBACK_BASE_URL || 'http://192.168.1.2:3000'
  },

  // Security
  security: {
    rateLimit: {
      windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
      maxRequests: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100
    },
    corsOrigin: process.env.CORS_ORIGIN || '*'
  },

  // Logging
  logging: {
    level: process.env.LOG_LEVEL || 'info',
    file: process.env.LOG_FILE || 'logs/combined.log',
    errorFile: process.env.LOG_ERROR_FILE || 'logs/error.log'
  },

  // File Upload
  upload: {
    maxSize: parseInt(process.env.MAX_FILE_SIZE) || 5 * 1024 * 1024, // 5MB
    directory: process.env.UPLOAD_DIR || 'uploads'
  },

  // Timezone
  timezone: {
    offset: parseInt(process.env.TIMEZONE_OFFSET) || -5,
    offsetMs: (parseInt(process.env.TIMEZONE_OFFSET) || -5) * 60 * 60 * 1000
  }
};

module.exports = config;
