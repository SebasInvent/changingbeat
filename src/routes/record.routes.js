const express = require('express');
const router = express.Router();
const { recordController } = require('../controllers');
const { 
  authenticate, 
  authorize,
  validate,
  validateQuery
} = require('../middlewares');
const { recordSchemas } = require('../utils/validators');
const { USER_ROLES } = require('../config/constants');

/**
 * @route   POST /api/v1/records
 * @desc    Crear nuevo registro
 * @access  Private
 */
router.post('/',
  authenticate,
  validate(recordSchemas.create),
  recordController.create
);

/**
 * @route   GET /api/v1/records
 * @desc    Listar registros con paginación y filtros
 * @access  Private
 */
router.get('/',
  authenticate,
  validateQuery(recordSchemas.list),
  recordController.list
);

/**
 * @route   GET /api/v1/records/stats/today
 * @desc    Obtener estadísticas del día
 * @access  Public (para dashboard)
 */
router.get('/stats/today',
  recordController.getTodayStats
);

/**
 * @route   GET /api/v1/records/stats
 * @desc    Obtener estadísticas generales
 * @access  Public (para dashboard)
 */
router.get('/stats',
  recordController.getStats
);

/**
 * @route   GET /api/v1/records/recent
 * @desc    Obtener registros recientes
 * @access  Public (para dashboard)
 */
router.get('/recent',
  recordController.getRecent
);

/**
 * @route   GET /api/v1/records/high-temperature
 * @desc    Obtener registros con temperatura alta
 * @access  Private
 */
router.get('/high-temperature',
  authenticate,
  recordController.getHighTemperature
);

/**
 * @route   GET /api/v1/records/denied
 * @desc    Obtener registros denegados
 * @access  Private
 */
router.get('/denied',
  authenticate,
  recordController.getDenied
);

/**
 * @route   GET /api/v1/records/export
 * @desc    Exportar registros
 * @access  Private/Admin
 */
router.get('/export',
  authenticate,
  authorize(USER_ROLES.ADMIN),
  recordController.export
);

/**
 * @route   POST /api/v1/records/entry
 * @desc    Registrar entrada manual
 * @access  Private
 */
router.post('/entry',
  authenticate,
  recordController.registerEntry
);

/**
 * @route   POST /api/v1/records/exit
 * @desc    Registrar salida manual
 * @access  Private
 */
router.post('/exit',
  authenticate,
  recordController.registerExit
);

/**
 * @route   GET /api/v1/records/user/:userId
 * @desc    Obtener registros por usuario
 * @access  Private
 */
router.get('/user/:userId',
  authenticate,
  recordController.getByUser
);

/**
 * @route   GET /api/v1/records/terminal/:terminalIp
 * @desc    Obtener registros por terminal
 * @access  Private
 */
router.get('/terminal/:terminalIp',
  authenticate,
  recordController.getByTerminal
);

/**
 * @route   GET /api/v1/records/:id
 * @desc    Obtener registro por ID
 * @access  Private
 */
router.get('/:id',
  authenticate,
  recordController.getById
);

module.exports = router;
