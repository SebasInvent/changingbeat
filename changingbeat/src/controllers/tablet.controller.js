const { Tablet } = require('../models');
const logger = require('../utils/logger');

/**
 * Controlador de Tablets
 */
class TabletController {
  
  /**
   * Registrar o actualizar tablet
   * POST /api/v1/tablets/register
   */
  async register(req, res) {
    try {
      const {
        tabletId,
        name,
        deviceInfo,
        appInfo,
        location
      } = req.body;

      logger.info(`📱 Registrando tablet: ${tabletId}`);

      // Buscar si ya existe
      let tablet = await Tablet.findOne({ tabletId });

      if (tablet) {
        // Actualizar tablet existente
        tablet.name = name || tablet.name;
        tablet.deviceInfo = { ...tablet.deviceInfo, ...deviceInfo };
        tablet.appInfo = { ...tablet.appInfo, ...appInfo };
        tablet.location = { ...tablet.location, ...location };
        tablet.connectionStatus.isOnline = true;
        tablet.connectionStatus.lastSeen = new Date();
        tablet.connectionStatus.ipAddress = req.ip;
        
        await tablet.save();
        
        logger.info(`✅ Tablet actualizada: ${tabletId}`);
      } else {
        // Crear nueva tablet
        tablet = new Tablet({
          tabletId,
          name,
          deviceInfo,
          appInfo,
          location,
          connectionStatus: {
            isOnline: true,
            lastSeen: new Date(),
            ipAddress: req.ip
          }
        });
        
        await tablet.save();
        
        logger.info(`✅ Nueva tablet registrada: ${tabletId}`);
      }

      res.status(200).json({
        success: true,
        message: 'Tablet registrada exitosamente',
        data: tablet
      });

    } catch (error) {
      logger.error('❌ Error registrando tablet:', error);
      res.status(500).json({
        success: false,
        message: 'Error al registrar tablet',
        error: error.message
      });
    }
  }

  /**
   * Heartbeat - Mantener conexión activa
   * POST /api/v1/tablets/:tabletId/heartbeat
   */
  async heartbeat(req, res) {
    try {
      const { tabletId } = req.params;
      const { battery, storage, signalStrength } = req.body;

      const tablet = await Tablet.findOne({ tabletId });

      if (!tablet) {
        return res.status(404).json({
          success: false,
          message: 'Tablet no encontrada'
        });
      }

      // Actualizar estado
      tablet.connectionStatus.isOnline = true;
      tablet.connectionStatus.lastSeen = new Date();
      tablet.connectionStatus.ipAddress = req.ip;
      tablet.connectionStatus.signalStrength = signalStrength;

      if (battery) {
        tablet.hardware.battery = {
          ...battery,
          lastUpdate: new Date()
        };
      }

      if (storage) {
        tablet.hardware.storage = {
          ...storage,
          lastCheck: new Date()
        };
      }

      await tablet.save();

      res.json({
        success: true,
        message: 'Heartbeat recibido',
        configuration: tablet.configuration // Enviar configuración actualizada
      });

    } catch (error) {
      logger.error('❌ Error en heartbeat:', error);
      res.status(500).json({
        success: false,
        message: 'Error en heartbeat',
        error: error.message
      });
    }
  }

  /**
   * Reportar evento
   * POST /api/v1/tablets/:tabletId/event
   */
  async reportEvent(req, res) {
    try {
      const { tabletId } = req.params;
      const { type, message, data } = req.body;

      const tablet = await Tablet.findOne({ tabletId });

      if (!tablet) {
        return res.status(404).json({
          success: false,
          message: 'Tablet no encontrada'
        });
      }

      await tablet.addEvent(type, message, data);

      logger.info(`📝 Evento de ${tabletId}: ${type} - ${message}`);

      res.json({
        success: true,
        message: 'Evento registrado'
      });

    } catch (error) {
      logger.error('❌ Error reportando evento:', error);
      res.status(500).json({
        success: false,
        message: 'Error al reportar evento',
        error: error.message
      });
    }
  }

  /**
   * Listar todas las tablets
   * GET /api/v1/tablets
   */
  async list(req, res) {
    try {
      const { status, isOnline } = req.query;

      const query = {};
      if (status) query.status = status;
      if (isOnline !== undefined) query['connectionStatus.isOnline'] = isOnline === 'true';

      const tablets = await Tablet.find(query).sort({ createdAt: -1 });

      res.json({
        success: true,
        data: tablets
      });

    } catch (error) {
      logger.error('❌ Error listando tablets:', error);
      res.status(500).json({
        success: false,
        message: 'Error al listar tablets',
        error: error.message
      });
    }
  }

  /**
   * Obtener tablet por ID
   * GET /api/v1/tablets/:tabletId
   */
  async getById(req, res) {
    try {
      const { tabletId } = req.params;

      const tablet = await Tablet.findOne({ tabletId });

      if (!tablet) {
        return res.status(404).json({
          success: false,
          message: 'Tablet no encontrada'
        });
      }

      res.json({
        success: true,
        data: tablet
      });

    } catch (error) {
      logger.error('❌ Error obteniendo tablet:', error);
      res.status(500).json({
        success: false,
        message: 'Error al obtener tablet',
        error: error.message
      });
    }
  }

  /**
   * Actualizar configuración de tablet
   * PATCH /api/v1/tablets/:tabletId/configuration
   */
  async updateConfiguration(req, res) {
    try {
      const { tabletId } = req.params;
      const configuration = req.body;

      const tablet = await Tablet.findOne({ tabletId });

      if (!tablet) {
        return res.status(404).json({
          success: false,
          message: 'Tablet no encontrada'
        });
      }

      tablet.configuration = {
        ...tablet.configuration,
        ...configuration
      };

      await tablet.save();

      logger.info(`⚙️  Configuración actualizada para ${tabletId}`);

      res.json({
        success: true,
        message: 'Configuración actualizada',
        data: tablet.configuration
      });

    } catch (error) {
      logger.error('❌ Error actualizando configuración:', error);
      res.status(500).json({
        success: false,
        message: 'Error al actualizar configuración',
        error: error.message
      });
    }
  }

  /**
   * Obtener estadísticas globales
   * GET /api/v1/tablets/stats/global
   */
  async getGlobalStats(req, res) {
    try {
      const stats = await Tablet.getGlobalStats();

      res.json({
        success: true,
        data: stats
      });

    } catch (error) {
      logger.error('❌ Error obteniendo estadísticas:', error);
      res.status(500).json({
        success: false,
        message: 'Error al obtener estadísticas',
        error: error.message
      });
    }
  }

  /**
   * Obtener estadísticas de una tablet
   * GET /api/v1/tablets/:tabletId/stats
   */
  async getTabletStats(req, res) {
    try {
      const { tabletId } = req.params;

      const tablet = await Tablet.findOne({ tabletId });

      if (!tablet) {
        return res.status(404).json({
          success: false,
          message: 'Tablet no encontrada'
        });
      }

      res.json({
        success: true,
        data: {
          statistics: tablet.statistics,
          successRate: tablet.successRate,
          uptimePercentage: tablet.uptimePercentage,
          hardware: tablet.hardware,
          recentEvents: tablet.recentEvents.slice(0, 20)
        }
      });

    } catch (error) {
      logger.error('❌ Error obteniendo estadísticas de tablet:', error);
      res.status(500).json({
        success: false,
        message: 'Error al obtener estadísticas',
        error: error.message
      });
    }
  }

  /**
   * Habilitar/Deshabilitar tablet
   * PATCH /api/v1/tablets/:tabletId/toggle
   */
  async toggleStatus(req, res) {
    try {
      const { tabletId } = req.params;
      const { isEnabled } = req.body;

      const tablet = await Tablet.findOne({ tabletId });

      if (!tablet) {
        return res.status(404).json({
          success: false,
          message: 'Tablet no encontrada'
        });
      }

      tablet.isEnabled = isEnabled;
      tablet.status = isEnabled ? 'ACTIVE' : 'INACTIVE';
      
      await tablet.save();

      logger.info(`${isEnabled ? '✅' : '❌'} Tablet ${tabletId} ${isEnabled ? 'habilitada' : 'deshabilitada'}`);

      res.json({
        success: true,
        message: `Tablet ${isEnabled ? 'habilitada' : 'deshabilitada'}`,
        data: tablet
      });

    } catch (error) {
      logger.error('❌ Error cambiando estado de tablet:', error);
      res.status(500).json({
        success: false,
        message: 'Error al cambiar estado',
        error: error.message
      });
    }
  }

  /**
   * Eliminar tablet
   * DELETE /api/v1/tablets/:tabletId
   */
  async delete(req, res) {
    try {
      const { tabletId } = req.params;

      const tablet = await Tablet.findOneAndDelete({ tabletId });

      if (!tablet) {
        return res.status(404).json({
          success: false,
          message: 'Tablet no encontrada'
        });
      }

      logger.info(`🗑️  Tablet eliminada: ${tabletId}`);

      res.json({
        success: true,
        message: 'Tablet eliminada exitosamente'
      });

    } catch (error) {
      logger.error('❌ Error eliminando tablet:', error);
      res.status(500).json({
        success: false,
        message: 'Error al eliminar tablet',
        error: error.message
      });
    }
  }
}

module.exports = new TabletController();
