/**
 * Exportar todos los middlewares desde un solo punto
 */

const { authenticate, authorize, optionalAuth, checkOwnership } = require('./auth.middleware');
const { validate, validateQuery, validateParams } = require('./validation.middleware');
const { errorHandler, notFound, asyncHandler } = require('./error.middleware');
const { 
  generalLimiter, 
  authLimiter, 
  createLimiter, 
  publicApiLimiter 
} = require('./rateLimiter.middleware');

module.exports = {
  // Auth
  authenticate,
  authorize,
  optionalAuth,
  checkOwnership,
  
  // Validation
  validate,
  validateQuery,
  validateParams,
  
  // Error handling
  errorHandler,
  notFound,
  asyncHandler,
  
  // Rate limiting
  generalLimiter,
  authLimiter,
  createLimiter,
  publicApiLimiter
};
