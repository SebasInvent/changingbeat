const { userService } = require('../services');
const { successResponse, paginatedResponse } = require('../utils/response');
const { asyncHandler } = require('../middlewares');
const { SUCCESS_MESSAGES } = require('../config/constants');

/**
 * Controlador de Usuarios
 */
class UserController {
  /**
   * Crear usuario
   * POST /api/v1/users
   */
  create = asyncHandler(async (req, res) => {
    const user = await userService.createUser(req.body);
    
    return successResponse(
      res,
      user,
      SUCCESS_MESSAGES.USER_CREATED,
      201
    );
  });

  /**
   * Obtener usuario por ID
   * GET /api/v1/users/:id
   */
  getById = asyncHandler(async (req, res) => {
    const user = await userService.getUserById(req.params.id);
    
    return successResponse(
      res,
      user,
      'Usuario obtenido exitosamente'
    );
  });

  /**
   * Actualizar usuario
   * PATCH /api/v1/users/:id
   */
  update = asyncHandler(async (req, res) => {
    const user = await userService.updateUser(req.params.id, req.body);
    
    return successResponse(
      res,
      user,
      SUCCESS_MESSAGES.USER_UPDATED
    );
  });

  /**
   * Eliminar usuario (soft delete)
   * DELETE /api/v1/users/:id
   */
  delete = asyncHandler(async (req, res) => {
    const result = await userService.deleteUser(req.params.id);
    
    return successResponse(
      res,
      result,
      SUCCESS_MESSAGES.USER_DELETED
    );
  });

  /**
   * Listar usuarios con paginación
   * GET /api/v1/users
   */
  list = asyncHandler(async (req, res) => {
    const { page, limit, ...filters } = req.query;
    const result = await userService.listUsers(filters, page, limit);
    
    return paginatedResponse(
      res,
      result.users,
      result.pagination,
      'Usuarios obtenidos exitosamente'
    );
  });

  /**
   * Buscar usuarios
   * GET /api/v1/users/search
   */
  search = asyncHandler(async (req, res) => {
    const { q, limit } = req.query;
    const users = await userService.searchUsers(q, limit);
    
    return successResponse(
      res,
      users,
      'Búsqueda completada'
    );
  });

  /**
   * Obtener estadísticas de usuarios
   * GET /api/v1/users/stats
   */
  getStats = asyncHandler(async (req, res) => {
    const stats = await userService.getUserStats();
    
    return successResponse(
      res,
      stats,
      'Estadísticas obtenidas exitosamente'
    );
  });

  /**
   * Activar/desactivar usuario
   * PATCH /api/v1/users/:id/toggle-status
   */
  toggleStatus = asyncHandler(async (req, res) => {
    const user = await userService.toggleUserStatus(req.params.id);
    
    return successResponse(
      res,
      user,
      `Usuario ${user.isActive ? 'activado' : 'desactivado'} exitosamente`
    );
  });

  /**
   * Actualizar foto del usuario
   * PATCH /api/v1/users/:id/photo
   */
  updatePhoto = asyncHandler(async (req, res) => {
    const { photoBase64 } = req.body;
    const user = await userService.updatePhoto(req.params.id, photoBase64);
    
    return successResponse(
      res,
      user,
      'Foto actualizada exitosamente'
    );
  });

  /**
   * Actualizar ID biométrico
   * PATCH /api/v1/users/:id/biometric
   */
  updateBiometricId = asyncHandler(async (req, res) => {
    const { biometricId } = req.body;
    const user = await userService.updateBiometricId(req.params.id, biometricId);
    
    return successResponse(
      res,
      user,
      'ID biométrico actualizado exitosamente'
    );
  });

  /**
   * Obtener usuario por email
   * GET /api/v1/users/email/:email
   */
  getByEmail = asyncHandler(async (req, res) => {
    const user = await userService.getUserByEmail(req.params.email);
    
    return successResponse(
      res,
      user,
      'Usuario obtenido exitosamente'
    );
  });

  /**
   * Obtener usuario por ID biométrico
   * GET /api/v1/users/biometric/:id
   */
  getByBiometricId = asyncHandler(async (req, res) => {
    const user = await userService.getUserByBiometricId(req.params.id);
    
    return successResponse(
      res,
      user,
      'Usuario obtenido exitosamente'
    );
  });
}

module.exports = new UserController();
