const { biometricService, recordService } = require('../services');
const { successResponse } = require('../utils/response');
const { asyncHandler } = require('../middlewares');
const logger = require('../utils/logger');
const socketHandler = require('../websocket/socket.handler');

/**
 * Controlador de Terminales Biométricos
 */
class TerminalController {
  /**
   * Configurar callback en terminal
   * POST /api/v1/terminals/callback
   */
  setCallback = asyncHandler(async (req, res) => {
    const { terminalIp, callbackUrl } = req.body;
    const result = await biometricService.setCallback(terminalIp, callbackUrl);
    
    return successResponse(
      res,
      result,
      'Callback configurado exitosamente'
    );
  });

  /**
   * Configurar callbacks en todos los terminales
   * POST /api/v1/terminals/callback/all
   */
  setAllCallbacks = asyncHandler(async (req, res) => {
    const { callbackUrl } = req.body;
    const result = await biometricService.setAllCallbacks(callbackUrl);
    
    return successResponse(
      res,
      result,
      'Callbacks configurados en todos los terminales'
    );
  });

  /**
   * Registrar usuario en terminal
   * POST /api/v1/terminals/register-user
   */
  registerUser = asyncHandler(async (req, res) => {
    const { userId, terminalIp, photoBase64 } = req.body;
    const result = await biometricService.registerUserInTerminal(
      userId,
      terminalIp,
      photoBase64
    );
    
    return successResponse(
      res,
      result,
      'Usuario registrado en terminal exitosamente'
    );
  });

  /**
   * Registrar usuario en todos los terminales
   * POST /api/v1/terminals/register-user/all
   */
  registerUserAll = asyncHandler(async (req, res) => {
    const { userId, photoBase64 } = req.body;
    const result = await biometricService.registerUserInAllTerminals(
      userId,
      photoBase64
    );
    
    return successResponse(
      res,
      result,
      'Usuario registrado en todos los terminales'
    );
  });

  /**
   * Eliminar usuario de terminal
   * DELETE /api/v1/terminals/:terminalIp/user/:userId
   */
  deleteUser = asyncHandler(async (req, res) => {
    const { terminalIp, userId } = req.params;
    const result = await biometricService.deleteUserFromTerminal(
      userId,
      terminalIp
    );
    
    return successResponse(
      res,
      result,
      'Usuario eliminado del terminal'
    );
  });

  /**
   * Eliminar usuario de todos los terminales
   * DELETE /api/v1/terminals/user/:userId
   */
  deleteUserAll = asyncHandler(async (req, res) => {
    const { userId } = req.params;
    const result = await biometricService.deleteUserFromAllTerminals(userId);
    
    return successResponse(
      res,
      result,
      'Usuario eliminado de todos los terminales'
    );
  });

  /**
   * Enviar mensaje a terminal
   * POST /api/v1/terminals/message
   */
  sendMessage = asyncHandler(async (req, res) => {
    const { terminalIp, message } = req.body;
    const result = await biometricService.sendMessageToTerminal(
      terminalIp,
      message
    );
    
    return successResponse(
      res,
      result,
      'Mensaje enviado exitosamente'
    );
  });

  /**
   * Obtener estado de terminal
   * GET /api/v1/terminals/:terminalIp/status
   */
  getStatus = asyncHandler(async (req, res) => {
    const { terminalIp } = req.params;
    const status = await biometricService.getTerminalStatus(terminalIp);
    
    return successResponse(
      res,
      status,
      'Estado del terminal obtenido'
    );
  });

  /**
   * Obtener estado de todos los terminales
   * GET /api/v1/terminals/status
   */
  getAllStatus = asyncHandler(async (req, res) => {
    const statuses = await biometricService.getAllTerminalsStatus();
    
    return successResponse(
      res,
      statuses,
      'Estado de todos los terminales obtenido'
    );
  });

  /**
   * Callback de identificación desde terminal
   * POST /api/v1/terminals/identify-callback
   */
  identifyCallback = asyncHandler(async (req, res) => {
    logger.info('Callback de identificación recibido', req.body);

    const { personId, ip, temp, imgBase64 } = req.body;

    // Procesar identificación
    const identificationResult = await biometricService.processIdentification({
      personId,
      terminalIp: ip,
      temperature: temp,
      photoBase64: imgBase64
    });

    // Crear registro si la identificación fue exitosa
    if (identificationResult.success) {
      try {
        const record = await recordService.createRecord({
          userId: personId,
          terminalIp: ip,
          recordType: 'entry',
          temperature: temp,
          photoBase64: imgBase64,
          status: 'success'
        });

        // Emitir evento WebSocket de acceso autorizado
        socketHandler.emitAccessGranted({
          userName: identificationResult.user ? 
            `${identificationResult.user.firstName} ${identificationResult.user.lastName}` : 
            'Usuario',
          userId: personId,
          terminalIp: ip,
          temperature: temp
        });

        // Emitir el nuevo registro
        socketHandler.emitNewRecord(record);

        // Si temperatura alta, emitir alerta
        if (temp && temp > 37.5) {
          socketHandler.emitHighTemperature({
            userName: identificationResult.user ? 
              `${identificationResult.user.firstName} ${identificationResult.user.lastName}` : 
              'Usuario',
            temperature: temp,
            terminalIp: ip
          });
        }
      } catch (error) {
        logger.error('Error creando registro desde callback:', error);
      }
    } else {
      // Crear registro de acceso denegado
      try {
        const record = await recordService.createRecord({
          userId: personId || 'unknown',
          terminalIp: ip,
          recordType: 'denied',
          temperature: temp,
          photoBase64: imgBase64,
          status: 'failed',
          denialReason: identificationResult.message
        });

        // Emitir evento WebSocket de acceso denegado
        socketHandler.emitAccessDenied({
          reason: identificationResult.message,
          terminalIp: ip,
          temperature: temp
        });

        // Emitir el nuevo registro
        socketHandler.emitNewRecord(record);
      } catch (error) {
        logger.error('Error creando registro denegado:', error);
      }
    }

    return successResponse(
      res,
      identificationResult,
      'Identificación procesada'
    );
  });

  /**
   * Callback de latido (heartbeat) desde terminal
   * POST /api/v1/terminals/heartbeat
   */
  heartbeatCallback = asyncHandler(async (req, res) => {
    const { ip, status } = req.body;
    
    logger.debug('Heartbeat recibido', { ip, status });

    // Aquí podrías actualizar el estado del terminal en base de datos
    // o realizar acciones basadas en el heartbeat

    return successResponse(
      res,
      { received: true },
      'Heartbeat recibido'
    );
  });

  /**
   * Configurar heartbeat en terminal
   * POST /api/v1/terminals/heartbeat/config
   */
  setHeartbeat = asyncHandler(async (req, res) => {
    const { terminalIp, heartbeatUrl } = req.body;
    const result = await biometricService.setHeartbeat(
      terminalIp,
      heartbeatUrl
    );
    
    return successResponse(
      res,
      result,
      'Heartbeat configurado exitosamente'
    );
  });

  /**
   * Sincronizar usuarios con terminal
   * POST /api/v1/terminals/:terminalIp/sync
   */
  syncUsers = asyncHandler(async (req, res) => {
    const { terminalIp } = req.params;
    const result = await biometricService.syncUsersToTerminal(terminalIp);
    
    return successResponse(
      res,
      result,
      'Sincronización completada'
    );
  });

  /**
   * Listar IPs de terminales configurados
   * GET /api/v1/terminals
   */
  listTerminals = asyncHandler(async (req, res) => {
    const config = require('../config/env');
    const terminals = config.terminals.ips.map(ip => ({
      ip,
      baseUrl: `http://${ip}:8090`
    }));
    
    return successResponse(
      res,
      { terminals },
      'Terminales configurados obtenidos'
    );
  });
}

module.exports = new TerminalController();
