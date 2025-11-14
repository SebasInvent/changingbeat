const rateLimit = require('express-rate-limit');
const config = require('../config/env');

/**
 * Rate limiter general para todas las rutas
 */
const generalLimiter = rateLimit({
  windowMs: config.security.rateLimit.windowMs,
  max: config.security.rateLimit.maxRequests,
  message: {
    success: false,
    message: 'Demasiadas peticiones, por favor intenta más tarde'
  },
  standardHeaders: true,
  legacyHeaders: false,
  // Función para generar ID único por cliente
  keyGenerator: (req) => {
    return req.ip || req.headers['x-forwarded-for'] || 'unknown';
  }
});

/**
 * Rate limiter estricto para rutas de autenticación
 */
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutos
  max: 5, // Máximo 5 intentos
  message: {
    success: false,
    message: 'Demasiados intentos de inicio de sesión. Intenta nuevamente en 15 minutos'
  },
  standardHeaders: true,
  legacyHeaders: false,
  skipSuccessfulRequests: true, // No contar peticiones exitosas
  keyGenerator: (req) => {
    // Usar email + IP para rate limiting más específico
    const email = req.body?.email || '';
    return `${email}-${req.ip}`;
  }
});

/**
 * Rate limiter para creación de recursos
 */
const createLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minuto
  max: 10, // Máximo 10 creaciones por minuto
  message: {
    success: false,
    message: 'Demasiadas operaciones de creación. Intenta más tarde'
  },
  standardHeaders: true,
  legacyHeaders: false
});

/**
 * Rate limiter para API pública
 */
const publicApiLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minuto
  max: 30, // 30 peticiones por minuto
  message: {
    success: false,
    message: 'Límite de API alcanzado. Intenta más tarde'
  },
  standardHeaders: true,
  legacyHeaders: false
});

module.exports = {
  generalLimiter,
  authLimiter,
  createLimiter,
  publicApiLimiter
};
