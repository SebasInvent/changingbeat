const express = require('express');
const router = express.Router();
const { terminalController } = require('../controllers');
const { 
  authenticate, 
  authorize,
  validate,
  publicApiLimiter
} = require('../middlewares');
const { terminalSchemas } = require('../utils/validators');
const { USER_ROLES } = require('../config/constants');

/**
 * @route   GET /api/v1/terminals
 * @desc    Listar terminales configurados
 * @access  Private
 */
router.get('/',
  authenticate,
  terminalController.listTerminals
);

/**
 * @route   GET /api/v1/terminals/status
 * @desc    Obtener estado de todos los terminales
 * @access  Public (para dashboard)
 */
router.get('/status',
  terminalController.getAllStatus
);

/**
 * @route   POST /api/v1/terminals/callback
 * @desc    Configurar callback en terminal específico
 * @access  Private/Admin
 */
router.post('/callback',
  authenticate,
  authorize(USER_ROLES.ADMIN),
  validate(terminalSchemas.setCallback),
  terminalController.setCallback
);

/**
 * @route   POST /api/v1/terminals/callback/all
 * @desc    Configurar callback en todos los terminales
 * @access  Private/Admin
 */
router.post('/callback/all',
  authenticate,
  authorize(USER_ROLES.ADMIN),
  terminalController.setAllCallbacks
);

/**
 * @route   POST /api/v1/terminals/register-user
 * @desc    Registrar usuario en terminal específico
 * @access  Private/Admin
 */
router.post('/register-user',
  authenticate,
  authorize(USER_ROLES.ADMIN),
  validate(terminalSchemas.registerUser),
  terminalController.registerUser
);

/**
 * @route   POST /api/v1/terminals/register-user/all
 * @desc    Registrar usuario en todos los terminales
 * @access  Private/Admin
 */
router.post('/register-user/all',
  authenticate,
  authorize(USER_ROLES.ADMIN),
  terminalController.registerUserAll
);

/**
 * @route   POST /api/v1/terminals/message
 * @desc    Enviar mensaje a terminal
 * @access  Private/Admin
 */
router.post('/message',
  authenticate,
  authorize(USER_ROLES.ADMIN),
  validate(terminalSchemas.sendMessage),
  terminalController.sendMessage
);

/**
 * @route   POST /api/v1/terminals/heartbeat/config
 * @desc    Configurar heartbeat en terminal
 * @access  Private/Admin
 */
router.post('/heartbeat/config',
  authenticate,
  authorize(USER_ROLES.ADMIN),
  terminalController.setHeartbeat
);

/**
 * @route   DELETE /api/v1/terminals/user/:userId
 * @desc    Eliminar usuario de todos los terminales
 * @access  Private/Admin
 */
router.delete('/user/:userId',
  authenticate,
  authorize(USER_ROLES.ADMIN),
  terminalController.deleteUserAll
);

/**
 * @route   GET /api/v1/terminals/:terminalIp/status
 * @desc    Obtener estado de terminal específico
 * @access  Private
 */
router.get('/:terminalIp/status',
  authenticate,
  terminalController.getStatus
);

/**
 * @route   POST /api/v1/terminals/:terminalIp/sync
 * @desc    Sincronizar usuarios con terminal
 * @access  Private/Admin
 */
router.post('/:terminalIp/sync',
  authenticate,
  authorize(USER_ROLES.ADMIN),
  terminalController.syncUsers
);

/**
 * @route   DELETE /api/v1/terminals/:terminalIp/user/:userId
 * @desc    Eliminar usuario de terminal específico
 * @access  Private/Admin
 */
router.delete('/:terminalIp/user/:userId',
  authenticate,
  authorize(USER_ROLES.ADMIN),
  terminalController.deleteUser
);

// ===== RUTAS PÚBLICAS (Callbacks desde terminales) =====

/**
 * @route   POST /api/v1/terminals/identify-callback
 * @desc    Callback de identificación desde terminal
 * @access  Public (con rate limiting)
 */
router.post('/identify-callback',
  publicApiLimiter,
  terminalController.identifyCallback
);

/**
 * @route   POST /api/v1/terminals/heartbeat
 * @desc    Callback de heartbeat desde terminal
 * @access  Public (con rate limiting)
 */
router.post('/heartbeat',
  publicApiLimiter,
  terminalController.heartbeatCallback
);

// ===== RUTAS PARA TABLETAS ATAIDENTIFICA =====

/**
 * @route   POST /api/v1/terminals/llamada
 * @desc    Callback de identificación desde tableta ATAIdentifica
 * @access  Public (con rate limiting)
 */
router.post('/llamada',
  publicApiLimiter,
  terminalController.identifyCallback
);

/**
 * @route   POST /api/v1/terminals/latido
 * @desc    Callback de heartbeat/latido desde tableta ATAIdentifica
 * @access  Public (con rate limiting)
 */
router.post('/latido',
  publicApiLimiter,
  terminalController.heartbeatCallback
);

/**
 * @route   POST /api/v1/terminals/url
 * @desc    Callback genérico desde tableta ATAIdentifica
 * @access  Public (con rate limiting)
 */
router.post('/url',
  publicApiLimiter,
  terminalController.identifyCallback
);

module.exports = router;
