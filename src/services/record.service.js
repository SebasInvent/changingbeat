const { Record, User } = require('../models');
const logger = require('../utils/logger');
const config = require('../config/env');
const { 
  NotFoundError, 
  ValidationError,
  DatabaseError 
} = require('../utils/errors');
const { PAGINATION, RECORD_TYPES, TEMPERATURE } = require('../config/constants');

/**
 * Servicio de Registros de Acceso
 */
class RecordService {
  /**
   * Crear nuevo registro
   */
  async createRecord(recordData) {
    try {
      // Verificar que el usuario existe
      const user = await User.findById(recordData.userId);
      if (!user) {
        throw new NotFoundError('Usuario no encontrado');
      }

      // Validar temperatura si existe
      if (recordData.temperature) {
        if (recordData.temperature > TEMPERATURE.MAX_ALLOWED) {
          recordData.recordType = RECORD_TYPES.DENIED;
          recordData.denialReason = 'Temperatura elevada';
          recordData.status = 'failed';
        }
      }

      // Ajustar fecha para timezone
      const now = new Date();
      
      // Crear registro
      const record = new Record(recordData);
      await record.save();

      logger.info('Registro creado', { 
        recordId: record._id, 
        userId: recordData.userId,
        type: recordData.recordType 
      });

      // Poblar información del usuario
      await record.populate('userId', 'firstName lastName email');

      return record;
    } catch (error) {
      logger.error('Error creando registro:', error);
      throw error;
    }
  }

  /**
   * Obtener registro por ID
   */
  async getRecordById(recordId) {
    try {
      const record = await Record.findById(recordId)
        .populate('userId', 'firstName lastName email photoBase64');

      if (!record) {
        throw new NotFoundError('Registro no encontrado');
      }

      return record;
    } catch (error) {
      if (error.name === 'CastError') {
        throw new NotFoundError('Registro no encontrado');
      }
      throw error;
    }
  }

  /**
   * Listar registros con paginación y filtros
   */
  async listRecords(filters = {}, page = 1, limit = 20) {
    try {
      // Asegurar límites razonables
      page = Math.max(1, parseInt(page));
      limit = Math.min(
        Math.max(1, parseInt(limit)), 
        PAGINATION.MAX_LIMIT
      );

      const skip = (page - 1) * limit;

      // Construir query
      const query = {};

      // Filtros
      if (filters.userId) {
        query.userId = filters.userId;
      }

      if (filters.terminalIp) {
        query.terminalIp = filters.terminalIp;
      }

      if (filters.recordType) {
        query.recordType = filters.recordType;
      }

      if (filters.status) {
        query.status = filters.status;
      }

      // Rango de fechas
      if (filters.startDate || filters.endDate) {
        query.createdAt = {};
        if (filters.startDate) {
          query.createdAt.$gte = new Date(filters.startDate);
        }
        if (filters.endDate) {
          query.createdAt.$lte = new Date(filters.endDate);
        }
      }

      // Ejecutar queries en paralelo
      const [records, total] = await Promise.all([
        Record.find(query)
          .populate('userId', 'firstName lastName email')
          .sort({ createdAt: -1 })
          .skip(skip)
          .limit(limit)
          .lean(),
        Record.countDocuments(query)
      ]);

      const pages = Math.ceil(total / limit);

      return {
        records,
        pagination: {
          page,
          limit,
          total,
          pages,
          hasNext: page < pages,
          hasPrev: page > 1
        }
      };
    } catch (error) {
      logger.error('Error listando registros:', error);
      throw new DatabaseError('Error al listar registros', error);
    }
  }

  /**
   * Obtener registros por usuario
   */
  async getRecordsByUser(userId, options = {}) {
    try {
      const { page = 1, limit = 20, startDate, endDate } = options;

      return this.listRecords(
        { userId, startDate, endDate },
        page,
        limit
      );
    } catch (error) {
      logger.error('Error obteniendo registros por usuario:', error);
      throw error;
    }
  }

  /**
   * Obtener registros por terminal
   */
  async getRecordsByTerminal(terminalIp, options = {}) {
    try {
      const { page = 1, limit = 20, startDate, endDate } = options;

      return this.listRecords(
        { terminalIp, startDate, endDate },
        page,
        limit
      );
    } catch (error) {
      logger.error('Error obteniendo registros por terminal:', error);
      throw error;
    }
  }

  /**
   * Obtener estadísticas del día actual
   */
  async getTodayStats() {
    try {
      const stats = await Record.getTodayStats();
      return stats;
    } catch (error) {
      logger.error('Error obteniendo estadísticas del día:', error);
      throw error;
    }
  }

  /**
   * Obtener estadísticas generales
   */
  async getGeneralStats(startDate, endDate) {
    try {
      const query = {};

      // Rango de fechas
      if (startDate || endDate) {
        query.createdAt = {};
        if (startDate) query.createdAt.$gte = new Date(startDate);
        if (endDate) query.createdAt.$lte = new Date(endDate);
      }

      const [total, byType, byTerminal, avgTemperature, highTemp] = await Promise.all([
        Record.countDocuments(query),
        
        // Por tipo
        Record.aggregate([
          { $match: query },
          {
            $group: {
              _id: '$recordType',
              count: { $sum: 1 }
            }
          }
        ]),
        
        // Por terminal
        Record.aggregate([
          { $match: query },
          {
            $group: {
              _id: '$terminalIp',
              count: { $sum: 1 }
            }
          },
          { $sort: { count: -1 } },
          { $limit: 10 }
        ]),
        
        // Temperatura promedio
        Record.aggregate([
          { 
            $match: { 
              ...query, 
              temperature: { $exists: true, $ne: null } 
            } 
          },
          {
            $group: {
              _id: null,
              avg: { $avg: '$temperature' }
            }
          }
        ]),
        
        // Temperaturas altas
        Record.countDocuments({
          ...query,
          temperature: { $gt: TEMPERATURE.MAX_NORMAL }
        })
      ]);

      // Formatear resultados
      const typeStats = {};
      byType.forEach(item => {
        typeStats[item._id] = item.count;
      });

      const terminalStats = byTerminal.map(item => ({
        ip: item._id,
        count: item.count
      }));

      return {
        total,
        byType: typeStats,
        topTerminals: terminalStats,
        temperature: {
          average: avgTemperature[0]?.avg || null,
          highCount: highTemp
        }
      };
    } catch (error) {
      logger.error('Error obteniendo estadísticas generales:', error);
      throw error;
    }
  }

  /**
   * Obtener últimos registros
   */
  async getRecentRecords(limit = 10) {
    try {
      const records = await Record.find()
        .populate('userId', 'firstName lastName email photoBase64')
        .sort({ createdAt: -1 })
        .limit(limit)
        .lean();

      return records;
    } catch (error) {
      logger.error('Error obteniendo registros recientes:', error);
      throw error;
    }
  }

  /**
   * Obtener registros con temperatura alta
   */
  async getHighTemperatureRecords(options = {}) {
    try {
      const { page = 1, limit = 20 } = options;

      return this.listRecords(
        { 
          temperature: { $gt: TEMPERATURE.MAX_NORMAL } 
        },
        page,
        limit
      );
    } catch (error) {
      logger.error('Error obteniendo registros con temperatura alta:', error);
      throw error;
    }
  }

  /**
   * Obtener registros denegados
   */
  async getDeniedRecords(options = {}) {
    try {
      const { page = 1, limit = 20, startDate, endDate } = options;

      return this.listRecords(
        { 
          recordType: RECORD_TYPES.DENIED,
          startDate,
          endDate
        },
        page,
        limit
      );
    } catch (error) {
      logger.error('Error obteniendo registros denegados:', error);
      throw error;
    }
  }

  /**
   * Registrar entrada manual
   */
  async registerEntry(userId, terminalIp, additionalData = {}) {
    try {
      const recordData = {
        userId,
        terminalIp,
        recordType: RECORD_TYPES.ENTRY,
        status: 'success',
        ...additionalData
      };

      return this.createRecord(recordData);
    } catch (error) {
      logger.error('Error registrando entrada:', error);
      throw error;
    }
  }

  /**
   * Registrar salida manual
   */
  async registerExit(userId, terminalIp, additionalData = {}) {
    try {
      const recordData = {
        userId,
        terminalIp,
        recordType: RECORD_TYPES.EXIT,
        status: 'success',
        ...additionalData
      };

      return this.createRecord(recordData);
    } catch (error) {
      logger.error('Error registrando salida:', error);
      throw error;
    }
  }

  /**
   * Exportar registros (formato básico)
   */
  async exportRecords(filters = {}) {
    try {
      const query = {};

      // Aplicar filtros
      if (filters.userId) query.userId = filters.userId;
      if (filters.terminalIp) query.terminalIp = filters.terminalIp;
      if (filters.recordType) query.recordType = filters.recordType;
      
      if (filters.startDate || filters.endDate) {
        query.createdAt = {};
        if (filters.startDate) query.createdAt.$gte = new Date(filters.startDate);
        if (filters.endDate) query.createdAt.$lte = new Date(filters.endDate);
      }

      const records = await Record.find(query)
        .populate('userId', 'firstName lastName email')
        .sort({ createdAt: -1 })
        .lean();

      // Formatear para exportación
      const exportData = records.map(record => ({
        fecha: record.createdAt,
        usuario: `${record.userId?.firstName} ${record.userId?.lastName}`,
        email: record.userId?.email,
        terminal: record.terminalIp,
        tipo: record.recordType,
        temperatura: record.temperature || 'N/A',
        estado: record.status
      }));

      return exportData;
    } catch (error) {
      logger.error('Error exportando registros:', error);
      throw error;
    }
  }

  /**
   * Eliminar registros antiguos (limpieza)
   */
  async cleanupOldRecords(daysOld = 90) {
    try {
      const cutoffDate = new Date();
      cutoffDate.setDate(cutoffDate.getDate() - daysOld);

      const result = await Record.deleteMany({
        createdAt: { $lt: cutoffDate }
      });

      logger.info(`Limpieza de registros: ${result.deletedCount} eliminados`, {
        daysOld,
        cutoffDate
      });

      return {
        deleted: result.deletedCount,
        cutoffDate
      };
    } catch (error) {
      logger.error('Error en limpieza de registros:', error);
      throw error;
    }
  }
}

module.exports = new RecordService();
