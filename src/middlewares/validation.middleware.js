const { ValidationError } = require('../utils/errors');

/**
 * Middleware de validación usando schemas de Joi
 */
const validate = (schema) => {
  return (req, res, next) => {
    try {
      // Validar body
      const { error, value } = schema.validate(req.body, {
        abortEarly: false, // Retornar todos los errores, no solo el primero
        stripUnknown: true // Remover campos no definidos en el schema
      });
      
      if (error) {
        // Formatear errores
        const errors = error.details.map(detail => ({
          field: detail.path.join('.'),
          message: detail.message.replace(/['"]/g, ''),
          type: detail.type
        }));
        
        throw new ValidationError('Datos inválidos', errors);
      }
      
      // Reemplazar req.body con el valor validado y sanitizado
      req.body = value;
      
      next();
    } catch (err) {
      next(err);
    }
  };
};

/**
 * Validar query parameters
 */
const validateQuery = (schema) => {
  return (req, res, next) => {
    try {
      const { error, value } = schema.validate(req.query, {
        abortEarly: false,
        stripUnknown: true
      });
      
      if (error) {
        const errors = error.details.map(detail => ({
          field: detail.path.join('.'),
          message: detail.message.replace(/['"]/g, ''),
          type: detail.type
        }));
        
        throw new ValidationError('Query parameters inválidos', errors);
      }
      
      req.query = value;
      next();
    } catch (err) {
      next(err);
    }
  };
};

/**
 * Validar params de URL
 */
const validateParams = (schema) => {
  return (req, res, next) => {
    try {
      const { error, value } = schema.validate(req.params, {
        abortEarly: false
      });
      
      if (error) {
        const errors = error.details.map(detail => ({
          field: detail.path.join('.'),
          message: detail.message.replace(/['"]/g, ''),
          type: detail.type
        }));
        
        throw new ValidationError('Parámetros de URL inválidos', errors);
      }
      
      req.params = value;
      next();
    } catch (err) {
      next(err);
    }
  };
};

module.exports = {
  validate,
  validateQuery,
  validateParams
};
