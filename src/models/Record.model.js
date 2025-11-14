const mongoose = require('mongoose');
const { RECORD_TYPES } = require('../config/constants');
const config = require('../config/env');

/**
 * Schema de Registro de Acceso
 */
const RecordSchema = new mongoose.Schema({
  // Relación con Usuario
  userId: {
    type: String,
    ref: 'User',
    required: [true, 'El ID de usuario es requerido'],
    index: true
  },
  
  // Información del Terminal
  terminalIp: {
    type: String,
    required: [true, 'La IP del terminal es requerida'],
    index: true,
    validate: {
      validator: function(v) {
        // Validar formato IP
        return /^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/.test(v);
      },
      message: 'Formato de IP inválido'
    }
  },
  
  // Tipo de Registro
  recordType: {
    type: String,
    enum: Object.values(RECORD_TYPES),
    default: RECORD_TYPES.ENTRY,
    index: true
  },
  
  // Datos Biométricos
  photoBase64: {
    type: String
  },
  
  // Datos de Salud
  temperature: {
    type: Number,
    min: [30, 'Temperatura fuera de rango'],
    max: [45, 'Temperatura fuera de rango']
  },
  
  // Código QR (si aplica)
  qrCode: {
    type: String
  },
  
  // Estado del Registro
  status: {
    type: String,
    enum: ['success', 'failed', 'pending'],
    default: 'success'
  },
  
  // Razón de denegación (si aplica)
  denialReason: {
    type: String
  },
  
  // Metadata adicional
  metadata: {
    type: mongoose.Schema.Types.Mixed
  }
}, {
  timestamps: true, // Agrega createdAt y updatedAt
  toJSON: {
    transform: function(doc, ret) {
      delete ret.__v;
      // Truncar photoBase64 para logs (solo primeros 50 chars)
      if (ret.photoBase64 && ret.photoBase64.length > 50) {
        ret.photoBase64 = ret.photoBase64.substring(0, 50) + '...';
      }
      return ret;
    }
  }
});

/**
 * Índices compuestos para consultas frecuentes
 */
RecordSchema.index({ userId: 1, createdAt: -1 });
RecordSchema.index({ terminalIp: 1, createdAt: -1 });
RecordSchema.index({ recordType: 1, createdAt: -1 });
RecordSchema.index({ createdAt: -1 }); // Para queries por fecha

/**
 * Virtual: Ajustar fecha para timezone local
 */
RecordSchema.virtual('localDate').get(function() {
  if (this.createdAt) {
    return new Date(this.createdAt.getTime() + config.timezone.offsetMs);
  }
  return null;
});

/**
 * Método de instancia: Verificar si el registro es reciente (últimas 24h)
 */
RecordSchema.methods.isRecent = function() {
  const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
  return this.createdAt > oneDayAgo;
};

/**
 * Método de instancia: Verificar temperatura alta
 */
RecordSchema.methods.hasHighTemperature = function() {
  const { TEMPERATURE } = require('../config/constants');
  return this.temperature && this.temperature > TEMPERATURE.MAX_NORMAL;
};

/**
 * Método estático: Obtener registros por usuario
 */
RecordSchema.statics.findByUser = function(userId, options = {}) {
  const { page = 1, limit = 20, startDate, endDate } = options;
  const skip = (page - 1) * limit;
  
  const query = { userId };
  
  // Filtro por rango de fechas
  if (startDate || endDate) {
    query.createdAt = {};
    if (startDate) query.createdAt.$gte = new Date(startDate);
    if (endDate) query.createdAt.$lte = new Date(endDate);
  }
  
  return this.find(query)
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(limit)
    .populate('userId', 'firstName lastName email');
};

/**
 * Método estático: Obtener registros por terminal
 */
RecordSchema.statics.findByTerminal = function(terminalIp, options = {}) {
  const { page = 1, limit = 20, startDate, endDate } = options;
  const skip = (page - 1) * limit;
  
  const query = { terminalIp };
  
  // Filtro por rango de fechas
  if (startDate || endDate) {
    query.createdAt = {};
    if (startDate) query.createdAt.$gte = new Date(startDate);
    if (endDate) query.createdAt.$lte = new Date(endDate);
  }
  
  return this.find(query)
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(limit)
    .populate('userId', 'firstName lastName email');
};

/**
 * Método estático: Estadísticas de hoy
 */
RecordSchema.statics.getTodayStats = async function() {
  const startOfDay = new Date();
  startOfDay.setHours(0, 0, 0, 0);
  
  const stats = await this.aggregate([
    {
      $match: {
        createdAt: { $gte: startOfDay }
      }
    },
    {
      $group: {
        _id: '$recordType',
        count: { $sum: 1 }
      }
    }
  ]);
  
  // Formatear resultado
  const result = {
    total: 0,
    entry: 0,
    exit: 0,
    denied: 0
  };
  
  stats.forEach(stat => {
    result[stat._id] = stat.count;
    result.total += stat.count;
  });
  
  return result;
};

/**
 * Pre-save Hook: Validaciones adicionales
 */
RecordSchema.pre('save', function(next) {
  // Si es denegado, requiere razón
  if (this.recordType === RECORD_TYPES.DENIED && !this.denialReason) {
    this.denialReason = 'No especificada';
  }
  
  next();
});

module.exports = mongoose.model('Record', RecordSchema);
