const express = require('express');
const router = express.Router();
const { authController } = require('../controllers');
const { 
  authenticate, 
  validate, 
  authLimiter 
} = require('../middlewares');
const { userSchemas } = require('../utils/validators');

/**
 * @route   POST /api/v1/auth/register
 * @desc    Registrar nuevo usuario
 * @access  Public
 */
router.post('/register',
  authLimiter,
  validate(userSchemas.create),
  authController.register
);

/**
 * @route   POST /api/v1/auth/login
 * @desc    Iniciar sesión
 * @access  Public
 */
router.post('/login',
  authLimiter,
  validate(userSchemas.login),
  authController.login
);

/**
 * @route   POST /api/v1/auth/refresh
 * @desc    Refrescar token JWT
 * @access  Public
 */
router.post('/refresh',
  authController.refreshToken
);

/**
 * @route   POST /api/v1/auth/change-password
 * @desc    Cambiar contraseña del usuario autenticado
 * @access  Private
 */
router.post('/change-password',
  authenticate,
  validate(userSchemas.changePassword),
  authController.changePassword
);

/**
 * @route   POST /api/v1/auth/forgot-password
 * @desc    Solicitar reseteo de contraseña
 * @access  Public
 */
router.post('/forgot-password',
  authLimiter,
  authController.forgotPassword
);

/**
 * @route   GET /api/v1/auth/verify
 * @desc    Verificar token JWT
 * @access  Public
 */
router.get('/verify',
  authController.verifyToken
);

/**
 * @route   POST /api/v1/auth/logout
 * @desc    Cerrar sesión
 * @access  Private
 */
router.post('/logout',
  authenticate,
  authController.logout
);

/**
 * @route   GET /api/v1/auth/me
 * @desc    Obtener perfil del usuario autenticado
 * @access  Private
 */
router.get('/me',
  authenticate,
  authController.getProfile
);

module.exports = router;
