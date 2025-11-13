const express = require('express');
const router = express.Router();
const tabletController = require('../controllers/tablet.controller');
const { validate } = require('../middlewares/validation.middleware');
const Joi = require('joi');

/**
 * Esquemas de validación
 */
const schemas = {
  register: Joi.object({
    tabletId: Joi.string().required(),
    name: Joi.string().required(),
    deviceInfo: Joi.object({
      manufacturer: Joi.string(),
      model: Joi.string(),
      osVersion: Joi.string(),
      androidVersion: Joi.string(),
      screenResolution: Joi.string(),
      serialNumber: Joi.string()
    }),
    appInfo: Joi.object({
      version: Joi.string(),
      buildNumber: Joi.string(),
      installedAt: Joi.date(),
      lastUpdated: Joi.date()
    }),
    location: Joi.object({
      name: Joi.string(),
      address: Joi.string(),
      coordinates: Joi.object({
        latitude: Joi.number(),
        longitude: Joi.number()
      }),
      building: Joi.string(),
      floor: Joi.string(),
      zone: Joi.string()
    })
  }),

  heartbeat: Joi.object({
    battery: Joi.object({
      level: Joi.number().min(0).max(100),
      isCharging: Joi.boolean()
    }),
    storage: Joi.object({
      total: Joi.number(),
      available: Joi.number(),
      used: Joi.number()
    }),
    signalStrength: Joi.number().min(0).max(100)
  }),

  event: Joi.object({
    type: Joi.string().valid('REGISTRATION', 'VERIFICATION', 'ERROR', 'WARNING', 'INFO', 'SYSTEM').required(),
    message: Joi.string().required(),
    data: Joi.any()
  }),

  configuration: Joi.object({
    operationMode: Joi.string().valid('REGISTRATION', 'VERIFICATION', 'BOTH'),
    enabledValidations: Joi.object({
      facial: Joi.boolean(),
      fingerprint: Joi.boolean(),
      document: Joi.boolean()
    }),
    timeouts: Joi.object({
      captureTimeout: Joi.number(),
      validationTimeout: Joi.number()
    }),
    ui: Joi.object({
      theme: Joi.string(),
      language: Joi.string(),
      showLogo: Joi.boolean(),
      customMessage: Joi.string()
    }),
    schedule: Joi.object({
      enabled: Joi.boolean(),
      timezone: Joi.string(),
      workingHours: Joi.array().items(Joi.object({
        day: Joi.string().valid('MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'),
        startTime: Joi.string(),
        endTime: Joi.string()
      }))
    })
  }),

  toggle: Joi.object({
    isEnabled: Joi.boolean().required()
  })
};

/**
 * Rutas
 */

// Registrar tablet
router.post(
  '/register',
  validate(schemas.register),
  tabletController.register
);

// Heartbeat
router.post(
  '/:tabletId/heartbeat',
  validate(schemas.heartbeat),
  tabletController.heartbeat
);

// Reportar evento
router.post(
  '/:tabletId/event',
  validate(schemas.event),
  tabletController.reportEvent
);

// Estadísticas globales
router.get('/stats/global', tabletController.getGlobalStats);

// Listar tablets
router.get('/', tabletController.list);

// Obtener tablet específica
router.get('/:tabletId', tabletController.getById);

// Estadísticas de tablet
router.get('/:tabletId/stats', tabletController.getTabletStats);

// Actualizar configuración
router.patch(
  '/:tabletId/configuration',
  validate(schemas.configuration),
  tabletController.updateConfiguration
);

// Habilitar/Deshabilitar
router.patch(
  '/:tabletId/toggle',
  validate(schemas.toggle),
  tabletController.toggleStatus
);

// Eliminar tablet
router.delete('/:tabletId', tabletController.delete);

module.exports = router;
