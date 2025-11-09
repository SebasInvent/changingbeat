const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const bodyParser = require('body-parser');
const path = require('path');
const config = require('./config/env');
const logger = require('./utils/logger');
const { errorHandler, notFound, generalLimiter } = require('./middlewares');
const routes = require('./routes');
const { setupSwagger } = require('./docs/swagger');

/**
 * Crear y configurar aplicación Express
 */
const createApp = () => {
  const app = express();

  // ===== SECURITY MIDDLEWARES =====
  
  // Helmet - Headers de seguridad
  app.use(helmet({
    contentSecurityPolicy: false, // Desactivar para desarrollo
    crossOriginEmbedderPolicy: false
  }));

  // CORS
  app.use(cors({
    origin: config.security.corsOrigin,
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization']
  }));

  // Rate Limiting general
  app.use('/api', generalLimiter);

  // ===== BODY PARSING =====
  
  // JSON y URL encoded con límites
  app.use(bodyParser.json({ limit: '10mb' }));
  app.use(bodyParser.urlencoded({ extended: true, limit: '10mb' }));

  // Compresión de respuestas
  app.use(compression());

  // ===== LOGGING =====
  
  // Log de requests (solo en desarrollo)
  if (config.isDevelopment) {
    app.use((req, res, next) => {
      logger.debug(`${req.method} ${req.path}`, {
        query: req.query,
        ip: req.ip
      });
      next();
    });
  }

  // ===== ARCHIVOS ESTÁTICOS =====
  
  // Servir archivos estáticos del dashboard
  app.use(express.static('public'));

  // ===== RUTAS =====
  
  // Ruta raíz - servir dashboard
  app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, '../public/index.html'));
  });

  // Ruta API info
  app.get('/api', (req, res) => {
    res.json({
      success: true,
      message: 'Sistema de Control de Acceso Biométrico API',
      version: '2.0.0',
      dashboard: '/',
      documentation: '/api-docs',
      health: '/api/v1/health'
    });
  });

  // API v1
  app.use('/api/v1', routes);

  // Documentación Swagger
  setupSwagger(app);

  // ===== ERROR HANDLING =====
  
  // 404 - Ruta no encontrada
  app.use(notFound);

  // Manejador global de errores
  app.use(errorHandler);

  return app;
};

module.exports = createApp;
