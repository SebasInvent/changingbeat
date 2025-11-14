const { HTTP_STATUS } = require('../config/constants');

/**
 * Clase de error personalizada para la aplicación
 */
class AppError extends Error {
  constructor(message, statusCode = HTTP_STATUS.INTERNAL_SERVER_ERROR, errors = []) {
    super(message);
    this.statusCode = statusCode;
    this.errors = errors;
    this.isOperational = true;
    
    Error.captureStackTrace(this, this.constructor);
  }
}

/**
 * Error de validación
 */
class ValidationError extends AppError {
  constructor(message, errors = []) {
    super(message, HTTP_STATUS.BAD_REQUEST, errors);
    this.name = 'ValidationError';
  }
}

/**
 * Error de autenticación
 */
class AuthenticationError extends AppError {
  constructor(message = 'No autorizado') {
    super(message, HTTP_STATUS.UNAUTHORIZED);
    this.name = 'AuthenticationError';
  }
}

/**
 * Error de autorización
 */
class AuthorizationError extends AppError {
  constructor(message = 'Acceso denegado') {
    super(message, HTTP_STATUS.FORBIDDEN);
    this.name = 'AuthorizationError';
  }
}

/**
 * Error de recurso no encontrado
 */
class NotFoundError extends AppError {
  constructor(message = 'Recurso no encontrado') {
    super(message, HTTP_STATUS.NOT_FOUND);
    this.name = 'NotFoundError';
  }
}

/**
 * Error de conflicto (recurso ya existe)
 */
class ConflictError extends AppError {
  constructor(message = 'El recurso ya existe') {
    super(message, HTTP_STATUS.CONFLICT);
    this.name = 'ConflictError';
  }
}

/**
 * Error de base de datos
 */
class DatabaseError extends AppError {
  constructor(message = 'Error en la base de datos', originalError) {
    super(message, HTTP_STATUS.INTERNAL_SERVER_ERROR);
    this.name = 'DatabaseError';
    this.originalError = originalError;
  }
}

module.exports = {
  AppError,
  ValidationError,
  AuthenticationError,
  AuthorizationError,
  NotFoundError,
  ConflictError,
  DatabaseError
};
