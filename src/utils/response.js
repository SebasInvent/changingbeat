const { HTTP_STATUS } = require('../config/constants');

/**
 * Formato estándar de respuesta exitosa
 */
const successResponse = (res, data = null, message = 'Operación exitosa', statusCode = HTTP_STATUS.OK) => {
  return res.status(statusCode).json({
    success: true,
    message,
    data
  });
};

/**
 * Formato estándar de respuesta de error
 */
const errorResponse = (res, message = 'Error en la operación', statusCode = HTTP_STATUS.INTERNAL_SERVER_ERROR, errors = []) => {
  return res.status(statusCode).json({
    success: false,
    message,
    errors
  });
};

/**
 * Respuesta paginada
 */
const paginatedResponse = (res, data, pagination, message = 'Operación exitosa') => {
  return res.status(HTTP_STATUS.OK).json({
    success: true,
    message,
    data,
    pagination: {
      page: pagination.page,
      limit: pagination.limit,
      total: pagination.total,
      pages: pagination.pages,
      hasNext: pagination.page < pagination.pages,
      hasPrev: pagination.page > 1
    }
  });
};

module.exports = {
  successResponse,
  errorResponse,
  paginatedResponse
};
