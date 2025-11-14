const axios = require('axios');
const config = require('../config/env');
const logger = require('../utils/logger');
const { AppError } = require('../utils/errors');
const userService = require('./user.service');

/**
 * Servicio de Integración con Terminales Biométricos
 */
class BiometricService {
  constructor() {
    this.terminalBaseUrl = config.terminals.baseUrl;
    this.terminalIps = config.terminals.ips;
  }

  /**
   * Construir URL para terminal específico
   */
  buildTerminalUrl(terminalIp, endpoint) {
    return `http://${terminalIp}:8090${endpoint}`;
  }

  /**
   * Hacer petición HTTP a terminal
   */
  async makeTerminalRequest(terminalIp, endpoint, method = 'get', data = null) {
    try {
      const url = this.buildTerminalUrl(terminalIp, endpoint);
      
      const options = {
        method,
        url,
        timeout: 10000 // 10 segundos
      };

      if (data) {
        options.data = data;
        options.headers = {
          'Content-Type': 'application/json'
        };
      }

      logger.debug(`Petición a terminal: ${method.toUpperCase()} ${url}`);

      const response = await axios(options);
      return response.data;
    } catch (error) {
      logger.error(`Error en petición a terminal ${terminalIp}:`, error.message);
      throw new AppError(
        `Error comunicándose con terminal ${terminalIp}`,
        500
      );
    }
  }

  /**
   * Configurar callback URL en terminal
   */
  async setCallback(terminalIp, callbackUrl) {
    try {
      const endpoint = '/setIdentifyCallBack';
      const data = { url: callbackUrl };

      const response = await this.makeTerminalRequest(
        terminalIp,
        endpoint,
        'post',
        data
      );

      logger.info('Callback configurado', { terminalIp, callbackUrl });

      return {
        success: true,
        terminalIp,
        callbackUrl,
        response
      };
    } catch (error) {
      logger.error('Error configurando callback:', error);
      throw error;
    }
  }

  /**
   * Configurar callbacks en todos los terminales
   */
  async setAllCallbacks(callbackUrl) {
    try {
      const results = await Promise.allSettled(
        this.terminalIps.map(ip => this.setCallback(ip, callbackUrl))
      );

      const successful = results.filter(r => r.status === 'fulfilled');
      const failed = results.filter(r => r.status === 'rejected');

      logger.info('Callbacks configurados', {
        total: this.terminalIps.length,
        successful: successful.length,
        failed: failed.length
      });

      return {
        total: this.terminalIps.length,
        successful: successful.length,
        failed: failed.length,
        results
      };
    } catch (error) {
      logger.error('Error configurando callbacks:', error);
      throw error;
    }
  }

  /**
   * Registrar usuario en terminal biométrico
   */
  async registerUserInTerminal(userId, terminalIp, photoBase64) {
    try {
      // Obtener información del usuario
      const user = await userService.getUserById(userId);

      const endpoint = '/face/create';
      const data = {
        id: userId,
        name: `${user.firstName} ${user.lastName}`,
        imgBase64: photoBase64
      };

      const response = await this.makeTerminalRequest(
        terminalIp,
        endpoint,
        'post',
        data
      );

      // Actualizar biometricId del usuario
      await userService.updateBiometricId(userId, userId);

      logger.info('Usuario registrado en terminal', { 
        userId, 
        terminalIp 
      });

      return {
        success: true,
        userId,
        terminalIp,
        response
      };
    } catch (error) {
      logger.error('Error registrando usuario en terminal:', error);
      throw error;
    }
  }

  /**
   * Registrar usuario en todos los terminales
   */
  async registerUserInAllTerminals(userId, photoBase64) {
    try {
      const results = await Promise.allSettled(
        this.terminalIps.map(ip => 
          this.registerUserInTerminal(userId, ip, photoBase64)
        )
      );

      const successful = results.filter(r => r.status === 'fulfilled');
      const failed = results.filter(r => r.status === 'rejected');

      logger.info('Usuario registrado en terminales', {
        userId,
        successful: successful.length,
        failed: failed.length
      });

      return {
        userId,
        total: this.terminalIps.length,
        successful: successful.length,
        failed: failed.length,
        results
      };
    } catch (error) {
      logger.error('Error registrando usuario en terminales:', error);
      throw error;
    }
  }

  /**
   * Eliminar usuario de terminal
   */
  async deleteUserFromTerminal(userId, terminalIp) {
    try {
      const endpoint = '/person/delete';
      const data = { personId: userId };

      const response = await this.makeTerminalRequest(
        terminalIp,
        endpoint,
        'post',
        data
      );

      logger.info('Usuario eliminado de terminal', { 
        userId, 
        terminalIp 
      });

      return {
        success: true,
        userId,
        terminalIp,
        response
      };
    } catch (error) {
      logger.error('Error eliminando usuario de terminal:', error);
      throw error;
    }
  }

  /**
   * Eliminar usuario de todos los terminales
   */
  async deleteUserFromAllTerminals(userId) {
    try {
      const results = await Promise.allSettled(
        this.terminalIps.map(ip => 
          this.deleteUserFromTerminal(userId, ip)
        )
      );

      const successful = results.filter(r => r.status === 'fulfilled');
      const failed = results.filter(r => r.status === 'rejected');

      // Limpiar biometricId del usuario
      await userService.updateBiometricId(userId, null);

      logger.info('Usuario eliminado de terminales', {
        userId,
        successful: successful.length,
        failed: failed.length
      });

      return {
        userId,
        total: this.terminalIps.length,
        successful: successful.length,
        failed: failed.length,
        results
      };
    } catch (error) {
      logger.error('Error eliminando usuario de terminales:', error);
      throw error;
    }
  }

  /**
   * Enviar mensaje a terminal
   */
  async sendMessageToTerminal(terminalIp, message) {
    try {
      const endpoint = '/api/v2/device/showMessage';
      const data = { message };

      const response = await this.makeTerminalRequest(
        terminalIp,
        endpoint,
        'post',
        data
      );

      logger.info('Mensaje enviado a terminal', { 
        terminalIp, 
        message 
      });

      return {
        success: true,
        terminalIp,
        message,
        response
      };
    } catch (error) {
      logger.warn(`No se pudo enviar mensaje a terminal ${terminalIp} (puede estar offline)`, {
        message,
        error: error.message
      });
      // No lanzar error, solo retornar que falló
      return {
        success: false,
        terminalIp,
        message,
        error: error.message
      };
    }
  }

  /**
   * Obtener estado del terminal
   */
  async getTerminalStatus(terminalIp) {
    try {
      const endpoint = '/api/v2/device/status';
      
      const response = await this.makeTerminalRequest(
        terminalIp,
        endpoint,
        'get'
      );

      return {
        terminalIp,
        status: 'online',
        data: response
      };
    } catch (error) {
      return {
        terminalIp,
        status: 'offline',
        error: error.message
      };
    }
  }

  /**
   * Obtener estado de todos los terminales
   */
  async getAllTerminalsStatus() {
    try {
      const results = await Promise.allSettled(
        this.terminalIps.map(ip => this.getTerminalStatus(ip))
      );

      const statuses = results.map((result, index) => {
        if (result.status === 'fulfilled') {
          return result.value;
        }
        return {
          terminalIp: this.terminalIps[index],
          status: 'offline',
          error: 'No responde'
        };
      });

      const online = statuses.filter(s => s.status === 'online').length;
      const offline = statuses.filter(s => s.status === 'offline').length;

      return {
        total: this.terminalIps.length,
        online,
        offline,
        terminals: statuses
      };
    } catch (error) {
      logger.error('Error obteniendo estado de terminales:', error);
      throw error;
    }
  }

  /**
   * Procesar identificación desde terminal
   */
  async processIdentification(identificationData) {
    try {
      const { personId, terminalIp, temperature, photoBase64 } = identificationData;

      logger.info('Procesando identificación', { 
        personId, 
        terminalIp 
      });

      // Buscar usuario
      let user;
      try {
        user = await userService.getUserById(personId);
      } catch (error) {
        logger.warn('Usuario no encontrado en identificación', { personId });
        return {
          success: false,
          message: 'Usuario no encontrado'
        };
      }

      // Validar que el usuario esté activo
      if (!user.isActive) {
        await this.sendMessageToTerminal(
          terminalIp,
          'Acceso denegado: Usuario inactivo'
        );
        return {
          success: false,
          message: 'Usuario inactivo'
        };
      }

      // Validar temperatura si está presente
      const TEMPERATURE = require('../config/constants').TEMPERATURE;
      if (temperature && temperature > TEMPERATURE.MAX_ALLOWED) {
        await this.sendMessageToTerminal(
          terminalIp,
          'Acceso denegado: Temperatura elevada'
        );
        return {
          success: false,
          message: 'Temperatura elevada',
          temperature
        };
      }

      // Enviar mensaje de bienvenida
      await this.sendMessageToTerminal(
        terminalIp,
        `Bienvenido ${user.firstName}`
      );

      return {
        success: true,
        user,
        temperature,
        message: 'Acceso autorizado'
      };
    } catch (error) {
      logger.error('Error procesando identificación:', error);
      throw error;
    }
  }

  /**
   * Configurar latido (heartbeat) del terminal
   */
  async setHeartbeat(terminalIp, heartbeatUrl) {
    try {
      const endpoint = '/setHeartbeat';
      const data = { url: heartbeatUrl };

      const response = await this.makeTerminalRequest(
        terminalIp,
        endpoint,
        'post',
        data
      );

      logger.info('Heartbeat configurado', { terminalIp, heartbeatUrl });

      return {
        success: true,
        terminalIp,
        heartbeatUrl,
        response
      };
    } catch (error) {
      logger.error('Error configurando heartbeat:', error);
      throw error;
    }
  }

  /**
   * Sincronizar todos los usuarios con un terminal
   */
  async syncUsersToTerminal(terminalIp) {
    try {
      logger.info('Iniciando sincronización de usuarios', { terminalIp });

      // Obtener todos los usuarios activos con foto
      const { users } = await userService.listUsers(
        { isActive: true },
        1,
        1000 // Límite alto para sync completo
      );

      const usersWithPhoto = users.filter(u => u.photoBase64);

      const results = await Promise.allSettled(
        usersWithPhoto.map(user => 
          this.registerUserInTerminal(user._id, terminalIp, user.photoBase64)
        )
      );

      const successful = results.filter(r => r.status === 'fulfilled').length;
      const failed = results.filter(r => r.status === 'rejected').length;

      logger.info('Sincronización completada', {
        terminalIp,
        total: usersWithPhoto.length,
        successful,
        failed
      });

      return {
        terminalIp,
        total: usersWithPhoto.length,
        successful,
        failed
      };
    } catch (error) {
      logger.error('Error en sincronización:', error);
      throw error;
    }
  }
}

module.exports = new BiometricService();
