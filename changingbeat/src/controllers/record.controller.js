const { recordService } = require('../services');
const { successResponse, paginatedResponse } = require('../utils/response');
const { asyncHandler } = require('../middlewares');
const { SUCCESS_MESSAGES } = require('../config/constants');

/**
 * Controlador de Registros
 */
class RecordController {
  /**
   * Crear registro
   * POST /api/v1/records
   */
  create = asyncHandler(async (req, res) => {
    const record = await recordService.createRecord(req.body);
    
    return successResponse(
      res,
      record,
      SUCCESS_MESSAGES.RECORD_CREATED,
      201
    );
  });

  /**
   * Obtener registro por ID
   * GET /api/v1/records/:id
   */
  getById = asyncHandler(async (req, res) => {
    const record = await recordService.getRecordById(req.params.id);
    
    return successResponse(
      res,
      record,
      'Registro obtenido exitosamente'
    );
  });

  /**
   * Listar registros con paginación y filtros
   * GET /api/v1/records
   */
  list = asyncHandler(async (req, res) => {
    const { page, limit, ...filters } = req.query;
    const result = await recordService.listRecords(filters, page, limit);
    
    return paginatedResponse(
      res,
      result.records,
      result.pagination,
      'Registros obtenidos exitosamente'
    );
  });

  /**
   * Obtener registros por usuario
   * GET /api/v1/records/user/:userId
   */
  getByUser = asyncHandler(async (req, res) => {
    const { userId } = req.params;
    const { page, limit, startDate, endDate } = req.query;
    
    const result = await recordService.getRecordsByUser(userId, {
      page,
      limit,
      startDate,
      endDate
    });
    
    return paginatedResponse(
      res,
      result.records,
      result.pagination,
      'Registros del usuario obtenidos'
    );
  });

  /**
   * Obtener registros por terminal
   * GET /api/v1/records/terminal/:terminalIp
   */
  getByTerminal = asyncHandler(async (req, res) => {
    const { terminalIp } = req.params;
    const { page, limit, startDate, endDate } = req.query;
    
    const result = await recordService.getRecordsByTerminal(terminalIp, {
      page,
      limit,
      startDate,
      endDate
    });
    
    return paginatedResponse(
      res,
      result.records,
      result.pagination,
      'Registros del terminal obtenidos'
    );
  });

  /**
   * Obtener estadísticas del día
   * GET /api/v1/records/stats/today
   */
  getTodayStats = asyncHandler(async (req, res) => {
    const stats = await recordService.getTodayStats();
    
    return successResponse(
      res,
      stats,
      'Estadísticas del día obtenidas'
    );
  });

  /**
   * Obtener estadísticas generales
   * GET /api/v1/records/stats
   */
  getStats = asyncHandler(async (req, res) => {
    const { startDate, endDate } = req.query;
    const stats = await recordService.getGeneralStats(startDate, endDate);
    
    return successResponse(
      res,
      stats,
      'Estadísticas obtenidas exitosamente'
    );
  });

  /**
   * Obtener registros recientes
   * GET /api/v1/records/recent
   */
  getRecent = asyncHandler(async (req, res) => {
    const { limit = 10 } = req.query;
    const records = await recordService.getRecentRecords(limit);
    
    return successResponse(
      res,
      records,
      'Registros recientes obtenidos'
    );
  });

  /**
   * Obtener registros con temperatura alta
   * GET /api/v1/records/high-temperature
   */
  getHighTemperature = asyncHandler(async (req, res) => {
    const { page, limit } = req.query;
    const result = await recordService.getHighTemperatureRecords({ page, limit });
    
    return paginatedResponse(
      res,
      result.records,
      result.pagination,
      'Registros con temperatura alta obtenidos'
    );
  });

  /**
   * Obtener registros denegados
   * GET /api/v1/records/denied
   */
  getDenied = asyncHandler(async (req, res) => {
    const { page, limit, startDate, endDate } = req.query;
    const result = await recordService.getDeniedRecords({ 
      page, 
      limit,
      startDate,
      endDate 
    });
    
    return paginatedResponse(
      res,
      result.records,
      result.pagination,
      'Registros denegados obtenidos'
    );
  });

  /**
   * Registrar entrada manual
   * POST /api/v1/records/entry
   */
  registerEntry = asyncHandler(async (req, res) => {
    const { userId, terminalIp, ...additionalData } = req.body;
    const record = await recordService.registerEntry(
      userId,
      terminalIp,
      additionalData
    );
    
    return successResponse(
      res,
      record,
      'Entrada registrada exitosamente',
      201
    );
  });

  /**
   * Registrar salida manual
   * POST /api/v1/records/exit
   */
  registerExit = asyncHandler(async (req, res) => {
    const { userId, terminalIp, ...additionalData } = req.body;
    const record = await recordService.registerExit(
      userId,
      terminalIp,
      additionalData
    );
    
    return successResponse(
      res,
      record,
      'Salida registrada exitosamente',
      201
    );
  });

  /**
   * Exportar registros
   * GET /api/v1/records/export
   */
  export = asyncHandler(async (req, res) => {
    const filters = req.query;
    const data = await recordService.exportRecords(filters);
    
    return successResponse(
      res,
      data,
      'Datos exportados exitosamente'
    );
  });
}

module.exports = new RecordController();
