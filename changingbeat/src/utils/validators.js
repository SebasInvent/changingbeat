const Joi = require('joi');
const { REGEX } = require('../config/constants');

/**
 * Esquemas de validación para usuarios
 */
const userSchemas = {
  // Crear usuario
  create: Joi.object({
    firstName: Joi.string().trim().min(2).max(50).required()
      .messages({
        'string.empty': 'El primer nombre es requerido',
        'string.min': 'El primer nombre debe tener al menos 2 caracteres',
        'string.max': 'El primer nombre no puede exceder 50 caracteres'
      }),
    
    secondName: Joi.string().trim().min(2).max(50).allow('', null)
      .messages({
        'string.min': 'El segundo nombre debe tener al menos 2 caracteres',
        'string.max': 'El segundo nombre no puede exceder 50 caracteres'
      }),
    
    lastName: Joi.string().trim().min(2).max(50).required()
      .messages({
        'string.empty': 'El apellido es requerido',
        'string.min': 'El apellido debe tener al menos 2 caracteres',
        'string.max': 'El apellido no puede exceder 50 caracteres'
      }),
    
    secondLastName: Joi.string().trim().min(2).max(50).allow('', null)
      .messages({
        'string.min': 'El segundo apellido debe tener al menos 2 caracteres',
        'string.max': 'El segundo apellido no puede exceder 50 caracteres'
      }),
    
    email: Joi.string().email().lowercase().required()
      .messages({
        'string.empty': 'El email es requerido',
        'string.email': 'Formato de email inválido'
      }),
    
    phone: Joi.string().pattern(REGEX.PHONE).allow('', null)
      .messages({
        'string.pattern.base': 'Formato de teléfono inválido'
      }),
    
    password: Joi.string().min(8).required()
      .messages({
        'string.empty': 'La contraseña es requerida',
        'string.min': 'La contraseña debe tener al menos 8 caracteres'
      }),
    
    photoBase64: Joi.string().allow('', null),
    
    biometricId: Joi.string().allow('', null),
    
    role: Joi.string().valid('user', 'admin', 'operator').default('user')
  }),

  // Actualizar usuario
  update: Joi.object({
    firstName: Joi.string().trim().min(2).max(50),
    secondName: Joi.string().trim().min(2).max(50).allow('', null),
    lastName: Joi.string().trim().min(2).max(50),
    secondLastName: Joi.string().trim().min(2).max(50).allow('', null),
    email: Joi.string().email().lowercase(),
    phone: Joi.string().pattern(REGEX.PHONE).allow('', null),
    photoBase64: Joi.string().allow('', null),
    biometricId: Joi.string().allow('', null),
    isActive: Joi.boolean()
  }).min(1),

  // Login
  login: Joi.object({
    email: Joi.string().email().required()
      .messages({
        'string.empty': 'El email es requerido',
        'string.email': 'Formato de email inválido'
      }),
    
    password: Joi.string().required()
      .messages({
        'string.empty': 'La contraseña es requerida'
      })
  }),

  // Cambiar contraseña
  changePassword: Joi.object({
    currentPassword: Joi.string().required()
      .messages({
        'string.empty': 'La contraseña actual es requerida'
      }),
    
    newPassword: Joi.string().min(8).required()
      .messages({
        'string.empty': 'La nueva contraseña es requerida',
        'string.min': 'La nueva contraseña debe tener al menos 8 caracteres'
      }),
    
    confirmPassword: Joi.string().valid(Joi.ref('newPassword')).required()
      .messages({
        'any.only': 'Las contraseñas no coinciden'
      })
  })
};

/**
 * Esquemas de validación para registros
 */
const recordSchemas = {
  // Crear registro
  create: Joi.object({
    userId: Joi.string().required()
      .messages({
        'string.empty': 'El ID de usuario es requerido'
      }),
    
    terminalIp: Joi.string().ip().required()
      .messages({
        'string.empty': 'La IP del terminal es requerida',
        'string.ip': 'Formato de IP inválido'
      }),
    
    recordType: Joi.string().valid('entry', 'exit', 'denied').default('entry'),
    
    photoBase64: Joi.string().allow('', null),
    
    temperature: Joi.number().min(30).max(45).allow(null)
      .messages({
        'number.min': 'Temperatura fuera de rango',
        'number.max': 'Temperatura fuera de rango'
      }),
    
    qrCode: Joi.string().allow('', null),
    
    metadata: Joi.object().unknown(true)
  }),

  // Query parameters para listar
  list: Joi.object({
    page: Joi.number().integer().min(1).default(1),
    limit: Joi.number().integer().min(1).max(100).default(20),
    userId: Joi.string(),
    terminalIp: Joi.string().ip(),
    recordType: Joi.string().valid('entry', 'exit', 'denied'),
    startDate: Joi.date().iso(),
    endDate: Joi.date().iso().min(Joi.ref('startDate'))
  })
};

/**
 * Esquemas para configuración de terminal
 */
const terminalSchemas = {
  // Configurar callback
  setCallback: Joi.object({
    terminalIp: Joi.string().ip().required(),
    callbackUrl: Joi.string().uri().required()
  }),

  // Enviar mensaje
  sendMessage: Joi.object({
    terminalIp: Joi.string().ip().required(),
    message: Joi.string().min(1).max(200).required()
  }),

  // Registrar usuario en terminal
  registerUser: Joi.object({
    userId: Joi.string().required(),
    terminalIp: Joi.string().ip().required(),
    photoBase64: Joi.string().required()
  })
};

module.exports = {
  userSchemas,
  recordSchemas,
  terminalSchemas
};
