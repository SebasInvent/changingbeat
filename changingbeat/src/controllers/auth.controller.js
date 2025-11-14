const { authService } = require('../services');
const { successResponse } = require('../utils/response');
const { asyncHandler } = require('../middlewares');
const { SUCCESS_MESSAGES } = require('../config/constants');

/**
 * Controlador de Autenticación
 */
class AuthController {
  /**
   * Registrar nuevo usuario
   * POST /api/v1/auth/register
   */
  register = asyncHandler(async (req, res) => {
    const result = await authService.register(req.body);
    
    return successResponse(
      res,
      result,
      SUCCESS_MESSAGES.USER_CREATED,
      201
    );
  });

  /**
   * Iniciar sesión
   * POST /api/v1/auth/login
   */
  login = asyncHandler(async (req, res) => {
    const { email, password } = req.body;
    const result = await authService.login(email, password);
    
    return successResponse(
      res,
      result,
      SUCCESS_MESSAGES.LOGIN_SUCCESS
    );
  });

  /**
   * Refrescar token
   * POST /api/v1/auth/refresh
   */
  refreshToken = asyncHandler(async (req, res) => {
    const { refreshToken } = req.body;
    const result = await authService.refreshToken(refreshToken);
    
    return successResponse(
      res,
      result,
      'Token refrescado exitosamente'
    );
  });

  /**
   * Cambiar contraseña
   * POST /api/v1/auth/change-password
   */
  changePassword = asyncHandler(async (req, res) => {
    const { currentPassword, newPassword } = req.body;
    const result = await authService.changePassword(
      req.userId,
      currentPassword,
      newPassword
    );
    
    return successResponse(
      res,
      result,
      'Contraseña actualizada exitosamente'
    );
  });

  /**
   * Solicitar reseteo de contraseña
   * POST /api/v1/auth/forgot-password
   */
  forgotPassword = asyncHandler(async (req, res) => {
    const { email } = req.body;
    const result = await authService.requestPasswordReset(email);
    
    return successResponse(res, result);
  });

  /**
   * Verificar token
   * GET /api/v1/auth/verify
   */
  verifyToken = asyncHandler(async (req, res) => {
    const token = req.headers.authorization?.split(' ')[1];
    const result = await authService.verifyToken(token);
    
    return successResponse(
      res,
      result,
      'Token válido'
    );
  });

  /**
   * Cerrar sesión
   * POST /api/v1/auth/logout
   */
  logout = asyncHandler(async (req, res) => {
    const result = await authService.logout(req.userId);
    
    return successResponse(
      res,
      result,
      SUCCESS_MESSAGES.LOGOUT_SUCCESS
    );
  });

  /**
   * Obtener perfil del usuario autenticado
   * GET /api/v1/auth/me
   */
  getProfile = asyncHandler(async (req, res) => {
    return successResponse(
      res,
      { user: req.user },
      'Perfil obtenido exitosamente'
    );
  });
}

module.exports = new AuthController();
