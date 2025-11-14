const express = require('express');
const router = express.Router();
const biometricController = require('../controllers/biometric.controller');
const { validate } = require('../middlewares/validation.middleware');
const Joi = require('joi');

/**
 * Esquemas de validación
 */
const schemas = {
  register: Joi.object({
    documentNumber: Joi.string().required().min(6).max(15),
    documentType: Joi.string().valid('CC', 'TI', 'CE', 'PEP', 'PPT').default('CC'),
    expeditionDate: Joi.string().isoDate().required(),
    selfieBase64: Joi.string().required(),
    frontDocumentBase64: Joi.string().required(),
    backDocumentBase64: Joi.string().required(),
    termsAccepted: Joi.boolean().required().valid(true),
    emotion: Joi.string().valid('neutral', 'happy', 'sad', 'angry', 'surprise').default('neutral'),
    
    // Datos obligatorios
    phone: Joi.string().required().length(10).pattern(/^[0-9]+$/),
    eps: Joi.string().required().min(3).max(100),
    arl: Joi.string().required().min(3).max(100),
    
    deviceInfo: Joi.object({
      deviceId: Joi.string(),
      deviceModel: Joi.string(),
      osVersion: Joi.string(),
      appVersion: Joi.string()
    }),
    tabletInfo: Joi.object({
      tabletId: Joi.string(),
      location: Joi.object({
        latitude: Joi.number(),
        longitude: Joi.number()
      }),
      registeredBy: Joi.string()
    })
  }),

  validate: Joi.object({
    documentNumber: Joi.string().required().min(6).max(15),
    documentType: Joi.string().valid('CC', 'TI', 'CE', 'PEP', 'PPT').default('CC')
  })
};

/**
 * Rutas
 */

// Crear nuevo registro biométrico
router.post(
  '/register',
  validate(schemas.register),
  biometricController.register
);

// Validar si un documento existe y está validado
router.post(
  '/validate',
  validate(schemas.validate),
  biometricController.validate
);

// Obtener estadísticas
router.get('/stats', biometricController.getStats);

// Listar registros
router.get('/', biometricController.list);

// Obtener registro por ID
router.get('/:id', biometricController.getById);

// Obtener registro por documento
router.get('/document/:documentNumber', biometricController.getByDocument);

module.exports = router;