const logger = require('../utils/logger');
const config = require('../config/env');
const { HTTP_STATUS } = require('../config/constants');

/**
 * Middleware de manejo de errores global
 */
const errorHandler = (err, req, res, next) => {
  // Log del error
  logger.error('Error capturado:', {
    name: err.name,
    message: err.message,
    statusCode: err.statusCode,
    stack: err.stack,
    url: req.url,
    method: req.method,
    ip: req.ip,
    userId: req.userId
  });
  
  // Determinar código de estado
  let statusCode = err.statusCode || HTTP_STATUS.INTERNAL_SERVER_ERROR;
  let message = err.message || 'Error interno del servidor';
  let errors = err.errors || [];
  
  // Manejar errores específicos de Mongoose
  if (err.name === 'ValidationError') {
    statusCode = HTTP_STATUS.BAD_REQUEST;
    message = 'Error de validación';
    errors = Object.values(err.errors).map(e => ({
      field: e.path,
      message: e.message
    }));
  }
  
  if (err.name === 'CastError') {
    statusCode = HTTP_STATUS.BAD_REQUEST;
    message = 'ID inválido';
  }
  
  if (err.code === 11000) {
    // Duplicate key error
    statusCode = HTTP_STATUS.CONFLICT;
    message = 'El recurso ya existe';
    const field = Object.keys(err.keyPattern)[0];
    errors = [{
      field,
      message: `El ${field} ya está en uso`
    }];
  }
  
  // Respuesta de error
  const response = {
    success: false,
    message,
    errors
  };
  
  // Incluir stack trace solo en desarrollo
  if (config.isDevelopment) {
    response.stack = err.stack;
    response.details = {
      name: err.name,
      isOperational: err.isOperational
    };
  }
  
  res.status(statusCode).json(response);
};

/**
 * Middleware para rutas no encontradas
 */
const notFound = (req, res, next) => {
  const error = new Error(`Ruta no encontrada: ${req.originalUrl}`);
  error.statusCode = HTTP_STATUS.NOT_FOUND;
  next(error);
};

/**
 * Middleware para errores asíncronos
 * Envuelve controladores async para capturar errores
 */
const asyncHandler = (fn) => {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};

module.exports = {
  errorHandler,
  notFound,
  asyncHandler
};
