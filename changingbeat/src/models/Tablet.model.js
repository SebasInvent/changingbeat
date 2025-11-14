const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');

/**
 * Schema de Tablet
 * Representa cada dispositivo Android conectado al sistema
 */
const TabletSchema = new mongoose.Schema({
  _id: {
    type: String,
    default: () => uuidv4()
  },
  
  // Identificación
  tabletId: {
    type: String,
    required: [true, 'El ID de tablet es requerido'],
    unique: true,
    index: true
  },
  
  name: {
    type: String,
    required: [true, 'El nombre de la tablet es requerido'],
    trim: true
  },
  
  // Información del dispositivo
  deviceInfo: {
    manufacturer: String,
    model: String,
    osVersion: String,
    androidVersion: String,
    screenResolution: String,
    serialNumber: String
  },
  
  // Información de la APK instalada
  appInfo: {
    version: String,
    buildNumber: String,
    installedAt: Date,
    lastUpdated: Date
  },
  
  // Ubicación física
  location: {
    name: String, // Ej: "Entrada Principal", "Recepción Piso 2"
    address: String,
    coordinates: {
      latitude: Number,
      longitude: Number
    },
    building: String,
    floor: String,
    zone: String
  },
  
  // Estado de conexión
  connectionStatus: {
    isOnline: {
      type: Boolean,
      default: false
    },
    lastSeen: Date,
    ipAddress: String,
    macAddress: String,
    signalStrength: Number // WiFi signal %
  },
  
  // Configuración específica
  configuration: {
    // Modos de operación
    operationMode: {
      type: String,
      enum: ['REGISTRATION', 'VERIFICATION', 'BOTH'],
      default: 'BOTH'
    },
    
    // Validaciones habilitadas
    enabledValidations: {
      facial: { type: Boolean, default: true },
      fingerprint: { type: Boolean, default: false },
      document: { type: Boolean, default: true }
    },
    
    // Timeouts
    timeouts: {
      captureTimeout: { type: Number, default: 30000 }, // ms
      validationTimeout: { type: Number, default: 60000 }
    },
    
    // UI personalizada
    ui: {
      theme: { type: String, default: 'light' },
      language: { type: String, default: 'es' },
      showLogo: { type: Boolean, default: true },
      customMessage: String
    },
    
    // Horarios de operación
    schedule: {
      enabled: { type: Boolean, default: false },
      timezone: { type: String, default: 'America/Bogota' },
      workingHours: [{
        day: { type: String, enum: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'] },
        startTime: String, // HH:mm
        endTime: String
      }]
    }
  },
  
  // Estadísticas de uso
  statistics: {
    totalRegistrations: { type: Number, default: 0 },
    totalVerifications: { type: Number, default: 0 },
    successfulValidations: { type: Number, default: 0 },
    failedValidations: { type: Number, default: 0 },
    averageProcessingTime: { type: Number, default: 0 }, // ms
    lastRegistration: Date,
    lastVerification: Date
  },
  
  // Estado del hardware
  hardware: {
    // Cámara
    camera: {
      available: { type: Boolean, default: true },
      resolution: String,
      lastCheck: Date
    },
    
    // Lector de huellas (si está conectado)
    fingerprint: {
      available: { type: Boolean, default: false },
      model: String,
      port: String,
      lastCheck: Date
    },
    
    // Batería
    battery: {
      level: Number, // 0-100
      isCharging: Boolean,
      lastUpdate: Date
    },
    
    // Almacenamiento
    storage: {
      total: Number, // bytes
      available: Number,
      used: Number,
      lastCheck: Date
    }
  },
  
  // Logs y eventos
  recentEvents: [{
    type: {
      type: String,
      enum: ['REGISTRATION', 'VERIFICATION', 'ERROR', 'WARNING', 'INFO', 'SYSTEM']
    },
    message: String,
    timestamp: { type: Date, default: Date.now },
    data: mongoose.Schema.Types.Mixed
  }],
  
  // Estado general
  status: {
    type: String,
    enum: ['ACTIVE', 'INACTIVE', 'MAINTENANCE', 'ERROR'],
    default: 'ACTIVE'
  },
  
  isEnabled: {
    type: Boolean,
    default: true
  },
  
  // Notas del administrador
  notes: String,
  
  // Responsable
  assignedTo: {
    name: String,
    email: String,
    phone: String
  }
  
}, {
  timestamps: true,
  toJSON: {
    virtuals: true,
    transform: function(doc, ret) {
      delete ret.__v;
      return ret;
    }
  }
});

/**
 * Índices
 */
TabletSchema.index({ tabletId: 1 });
TabletSchema.index({ 'connectionStatus.isOnline': 1 });
TabletSchema.index({ status: 1 });
TabletSchema.index({ createdAt: -1 });

/**
 * Virtual: Uptime percentage
 */
TabletSchema.virtual('uptimePercentage').get(function() {
  if (!this.createdAt || !this.connectionStatus.lastSeen) return 0;
  
  const totalTime = Date.now() - this.createdAt.getTime();
  const onlineTime = this.connectionStatus.lastSeen.getTime() - this.createdAt.getTime();
  
  return Math.min(100, Math.max(0, (onlineTime / totalTime) * 100));
});

/**
 * Virtual: Success rate
 */
TabletSchema.virtual('successRate').get(function() {
  const total = this.statistics.successfulValidations + this.statistics.failedValidations;
  if (total === 0) return 0;
  
  return (this.statistics.successfulValidations / total) * 100;
});

/**
 * Método de instancia: Actualizar estado de conexión
 */
TabletSchema.methods.updateConnectionStatus = function(isOnline, ipAddress) {
  this.connectionStatus.isOnline = isOnline;
  this.connectionStatus.lastSeen = new Date();
  if (ipAddress) this.connectionStatus.ipAddress = ipAddress;
  return this.save();
};

/**
 * Método de instancia: Agregar evento
 */
TabletSchema.methods.addEvent = function(type, message, data = null) {
  this.recentEvents.unshift({
    type,
    message,
    timestamp: new Date(),
    data
  });
  
  // Mantener solo los últimos 100 eventos
  if (this.recentEvents.length > 100) {
    this.recentEvents = this.recentEvents.slice(0, 100);
  }
  
  return this.save();
};

/**
 * Método de instancia: Incrementar estadísticas
 */
TabletSchema.methods.incrementStats = function(type, success = true) {
  if (type === 'REGISTRATION') {
    this.statistics.totalRegistrations++;
    this.statistics.lastRegistration = new Date();
  } else if (type === 'VERIFICATION') {
    this.statistics.totalVerifications++;
    this.statistics.lastVerification = new Date();
  }
  
  if (success) {
    this.statistics.successfulValidations++;
  } else {
    this.statistics.failedValidations++;
  }
  
  return this.save();
};

/**
 * Método estático: Obtener tablets online
 */
TabletSchema.statics.getOnlineTablets = function() {
  return this.find({ 
    'connectionStatus.isOnline': true,
    isEnabled: true
  });
};

/**
 * Método estático: Obtener estadísticas globales
 */
TabletSchema.statics.getGlobalStats = async function() {
  const stats = await this.aggregate([
    {
      $group: {
        _id: null,
        totalTablets: { $sum: 1 },
        onlineTablets: {
          $sum: { $cond: ['$connectionStatus.isOnline', 1, 0] }
        },
        totalRegistrations: { $sum: '$statistics.totalRegistrations' },
        totalVerifications: { $sum: '$statistics.totalVerifications' },
        successfulValidations: { $sum: '$statistics.successfulValidations' },
        failedValidations: { $sum: '$statistics.failedValidations' }
      }
    }
  ]);
  
  return stats[0] || {
    totalTablets: 0,
    onlineTablets: 0,
    totalRegistrations: 0,
    totalVerifications: 0,
    successfulValidations: 0,
    failedValidations: 0
  };
};

module.exports = mongoose.model('Tablet', TabletSchema);
