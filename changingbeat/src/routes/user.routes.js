const express = require('express');
const router = express.Router();
const { userController } = require('../controllers');
const { 
  authenticate, 
  authorize, 
  validate,
  createLimiter
} = require('../middlewares');
const { userSchemas } = require('../utils/validators');
const { USER_ROLES } = require('../config/constants');

/**
 * @route   POST /api/v1/users
 * @desc    Crear nuevo usuario (solo admin)
 * @access  Private/Admin
 */
router.post('/',
  authenticate,
  authorize(USER_ROLES.ADMIN),
  createLimiter,
  validate(userSchemas.create),
  userController.create
);

/**
 * @route   GET /api/v1/users
 * @desc    Listar usuarios con paginación
 * @access  Private
 */
router.get('/',
  authenticate,
  userController.list
);

/**
 * @route   GET /api/v1/users/search
 * @desc    Buscar usuarios
 * @access  Private
 */
router.get('/search',
  authenticate,
  userController.search
);

/**
 * @route   GET /api/v1/users/stats
 * @desc    Obtener estadísticas de usuarios
 * @access  Public (para dashboard)
 */
router.get('/stats',
  userController.getStats
);

/**
 * @route   GET /api/v1/users/email/:email
 * @desc    Obtener usuario por email
 * @access  Private
 */
router.get('/email/:email',
  authenticate,
  userController.getByEmail
);

/**
 * @route   GET /api/v1/users/biometric/:id
 * @desc    Obtener usuario por ID biométrico
 * @access  Private
 */
router.get('/biometric/:id',
  authenticate,
  userController.getByBiometricId
);

/**
 * @route   GET /api/v1/users/:id
 * @desc    Obtener usuario por ID
 * @access  Private
 */
router.get('/:id',
  authenticate,
  userController.getById
);

/**
 * @route   PATCH /api/v1/users/:id
 * @desc    Actualizar usuario
 * @access  Private
 */
router.patch('/:id',
  authenticate,
  validate(userSchemas.update),
  userController.update
);

/**
 * @route   DELETE /api/v1/users/:id
 * @desc    Eliminar usuario (soft delete)
 * @access  Private/Admin
 */
router.delete('/:id',
  authenticate,
  authorize(USER_ROLES.ADMIN),
  userController.delete
);

/**
 * @route   PATCH /api/v1/users/:id/toggle-status
 * @desc    Activar/desactivar usuario
 * @access  Private/Admin
 */
router.patch('/:id/toggle-status',
  authenticate,
  authorize(USER_ROLES.ADMIN),
  userController.toggleStatus
);

/**
 * @route   PATCH /api/v1/users/:id/photo
 * @desc    Actualizar foto del usuario
 * @access  Private
 */
router.patch('/:id/photo',
  authenticate,
  userController.updatePhoto
);

/**
 * @route   PATCH /api/v1/users/:id/biometric
 * @desc    Actualizar ID biométrico
 * @access  Private/Admin
 */
router.patch('/:id/biometric',
  authenticate,
  authorize(USER_ROLES.ADMIN),
  userController.updateBiometricId
);

module.exports = router;
