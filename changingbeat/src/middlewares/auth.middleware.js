const jwt = require('jsonwebtoken');
const config = require('../config/env');
const { User } = require('../models');
const { AuthenticationError, AuthorizationError } = require('../utils/errors');
const { ERROR_MESSAGES } = require('../config/constants');

/**
 * Middleware de autenticación JWT
 */
const authenticate = async (req, res, next) => {
  try {
    // Obtener token del header
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new AuthenticationError('Token no proporcionado');
    }
    
    const token = authHeader.split(' ')[1];
    
    // Verificar token
    let decoded;
    try {
      decoded = jwt.verify(token, config.jwt.secret);
    } catch (error) {
      if (error.name === 'JsonWebTokenError') {
        throw new AuthenticationError(ERROR_MESSAGES.INVALID_TOKEN);
      } else if (error.name === 'TokenExpiredError') {
        throw new AuthenticationError(ERROR_MESSAGES.EXPIRED_TOKEN);
      }
      throw error;
    }
    
    // Buscar usuario
    const user = await User.findById(decoded.userId);
    
    if (!user) {
      throw new AuthenticationError(ERROR_MESSAGES.USER_NOT_FOUND);
    }
    
    if (!user.isActive) {
      throw new AuthenticationError('Cuenta desactivada');
    }
    
    if (user.isLocked()) {
      throw new AuthenticationError('Cuenta bloqueada temporalmente');
    }
    
    // Agregar usuario al request
    req.user = user;
    req.userId = user._id;
    
    next();
  } catch (error) {
    next(error);
  }
};

/**
 * Middleware de autorización por roles
 */
const authorize = (...allowedRoles) => {
  return (req, res, next) => {
    try {
      if (!req.user) {
        throw new AuthenticationError(ERROR_MESSAGES.UNAUTHORIZED);
      }
      
      if (!allowedRoles.includes(req.user.role)) {
        throw new AuthorizationError(ERROR_MESSAGES.FORBIDDEN);
      }
      
      next();
    } catch (error) {
      next(error);
    }
  };
};

/**
 * Middleware opcional de autenticación
 * No falla si no hay token, solo lo agrega si existe
 */
const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return next();
    }
    
    const token = authHeader.split(' ')[1];
    
    try {
      const decoded = jwt.verify(token, config.jwt.secret);
      const user = await User.findById(decoded.userId);
      
      if (user && user.isActive && !user.isLocked()) {
        req.user = user;
        req.userId = user._id;
      }
    } catch (error) {
      // Ignorar errores de token en auth opcional
    }
    
    next();
  } catch (error) {
    next(error);
  }
};

/**
 * Middleware para verificar ownership
 * El usuario solo puede acceder a sus propios recursos
 */
const checkOwnership = (resourceUserIdField = 'userId') => {
  return (req, res, next) => {
    try {
      const resourceUserId = req.params[resourceUserIdField] || req.body[resourceUserIdField];
      
      // Admins pueden acceder a todo
      if (req.user.role === 'admin') {
        return next();
      }
      
      // Usuarios normales solo pueden acceder a sus recursos
      if (resourceUserId && resourceUserId !== req.userId) {
        throw new AuthorizationError('No tienes permiso para acceder a este recurso');
      }
      
      next();
    } catch (error) {
      next(error);
    }
  };
};

module.exports = {
  authenticate,
  authorize,
  optionalAuth,
  checkOwnership
};
