const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');

/**
 * Schema de Registro Biométrico
 * Almacena los registros de validación facial y cédula con Registraduría/ANI
 */
const BiometricRegistrationSchema = new mongoose.Schema({
  _id: {
    type: String,
    default: () => uuidv4()
  },
  
  // Información del Documento
  documentNumber: {
    type: String,
    required: [true, 'El número de documento es requerido'],
    unique: true,
    trim: true,
    index: true
  },
  
  documentType: {
    type: String,
    default: 'CC', // Cédula de Ciudadanía
    enum: ['CC', 'TI', 'CE', 'PEP', 'PPT']
  },
  
  expeditionDate: {
    type: Date,
    required: [true, 'La fecha de expedición es requerida']
  },
  
  // Información personal (extraída del documento)
  personalInfo: {
    fullName: String,
    firstName: String,
    lastName: String,
    dateOfBirth: Date,
    gender: {
      type: String,
      enum: ['M', 'F', 'O']
    },
    nationality: String,
    placeOfBirth: String,
    
    // Datos obligatorios capturados
    phone: {
      type: String,
      required: [true, 'El celular es obligatorio'],
      trim: true
    },
    eps: {
      type: String,
      required: [true, 'La EPS es obligatoria'],
      trim: true
    },
    arl: {
      type: String,
      required: [true, 'La ARL es obligatoria'],
      trim: true
    }
  },
  
  // Datos de verificación con Registraduría
  registraduriaValidation: {
    isValid: {
      type: Boolean,
      required: true
    },
    status: {
      type: String,
      enum: ['VIGENTE', 'NO_VIGENTE', 'SUSPENDIDA', 'ERROR'],
      default: 'ERROR'
    },
    validatedAt: {
      type: Date,
      default: Date.now
    },
    validationData: {
      area: String,
      city: String,
      resolution: String,
      dateResolution: Date
    },
    requestId: String, // ID de la petición en Apitude
    errorMessage: String
  },
  
  // Datos de verificación biométrica facial
  facialVerification: {
    isValid: {
      type: Boolean,
      required: true
    },
    matchScore: {
      type: Number,
      min: 0,
      max: 100
    },
    livenessDetected: Boolean,
    emotionDetected: String,
    faceFeatures: {
      age: Number,
      gender: String,
      race: String
    },
    validatedAt: {
      type: Date,
      default: Date.now
    },
    requestId: String,
    errorMessage: String
  },
  
  // Imágenes almacenadas (Base64)
  images: {
    frontDocument: {
      type: String,
      required: true
    },
    backDocument: {
      type: String,
      required: true
    },
    selfie: {
      type: String,
      required: true
    }
  },
  
  // Aceptación de términos y condiciones
  termsAcceptance: {
    accepted: {
      type: Boolean,
      required: true,
      default: false
    },
    acceptedAt: {
      type: Date
    },
    ipAddress: String,
    userAgent: String,
    version: String // Versión de los T&C aceptados
  },
  
  // Estado del registro
  status: {
    type: String,
    enum: ['PENDING', 'VALIDATED', 'REJECTED', 'EXPIRED'],
    default: 'PENDING'
  },
  
  // Usuario asociado (si ya existe en el sistema)
  userId: {
    type: String,
    ref: 'User',
    index: true
  },
  
  // Metadata de auditoría
  deviceInfo: {
    deviceId: String,
    deviceModel: String,
    osVersion: String,
    appVersion: String
  },
  
  // Datos de registro desde tablet
  tabletInfo: {
    tabletId: String,
    location: {
      latitude: Number,
      longitude: Number
    },
    registeredBy: String // ID del operador si aplica
  },
  
  // Flags de seguridad
  securityFlags: {
    documentAltered: Boolean,
    photoManipulated: Boolean,
    livenessCheckFailed: Boolean,
    internationalAlerts: [String] // Alertas de Interpol, FBI, etc.
  },
  
  // Notas adicionales
  notes: String,
  
  // Fecha de expiración del registro
  expiresAt: {
    type: Date,
    index: true
  }
  
}, {
  timestamps: true,
  toJSON: {
    transform: function(doc, ret) {
      // No exponer imágenes completas en JSON (son muy pesadas)
      if (ret.images) {
        ret.images = {
          frontDocument: ret.images.frontDocument ? '[BASE64_DATA]' : null,
          backDocument: ret.images.backDocument ? '[BASE64_DATA]' : null,
          selfie: ret.images.selfie ? '[BASE64_DATA]' : null
        };
      }
      delete ret.__v;
      return ret;
    }
  }
});

/**
 * Índices compuestos
 */
BiometricRegistrationSchema.index({ documentNumber: 1, documentType: 1 });
BiometricRegistrationSchema.index({ status: 1, createdAt: -1 });
BiometricRegistrationSchema.index({ 'registraduriaValidation.isValid': 1 });
BiometricRegistrationSchema.index({ 'facialVerification.isValid': 1 });
BiometricRegistrationSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 }); // TTL index

/**
 * Virtual: Validación completa exitosa
 */
BiometricRegistrationSchema.virtual('isFullyValidated').get(function() {
  return this.registraduriaValidation.isValid && 
         this.facialVerification.isValid && 
         this.termsAcceptance.accepted &&
         this.status === 'VALIDATED';
});

/**
 * Virtual: Nombre completo
 */
BiometricRegistrationSchema.virtual('fullName').get(function() {
  if (this.personalInfo && this.personalInfo.fullName) {
    return this.personalInfo.fullName;
  }
  const parts = [
    this.personalInfo?.firstName,
    this.personalInfo?.secondName,
    this.personalInfo?.lastName,
    this.personalInfo?.secondLastName
  ].filter(Boolean);
  return parts.join(' ')

;
});

/**
 * Método de instancia: Obtener imágenes completas
 */
BiometricRegistrationSchema.methods.getFullImages = function() {
  return {
    frontDocument: this.images.frontDocument,
    backDocument: this.images.backDocument,
    selfie: this.images.selfie
  };
};

/**
 * Método de instancia: Validar si el registro está activo
 */
BiometricRegistrationSchema.methods.isActive = function() {
  if (this.status !== 'VALIDATED') return false;
  if (this.expiresAt && this.expiresAt < new Date()) return false;
  return true;
};

/**
 * Método estático: Buscar por documento
 */
BiometricRegistrationSchema.statics.findByDocument = function(documentNumber, documentType = 'CC') {
  return this.findOne({ documentNumber, documentType });
};

/**
 * Método estático: Buscar registros validados
 */
BiometricRegistrationSchema.statics.findValidated = function(filter = {}) {
  return this.find({ 
    ...filter, 
    status: 'VALIDATED',
    'registraduriaValidation.isValid': true,
    'facialVerification.isValid': true
  });
};

/**
 * Método estático: Estadísticas de validación
 */
BiometricRegistrationSchema.statics.getStats = async function(startDate, endDate) {
  const match = {};
  if (startDate || endDate) {
    match.createdAt = {};
    if (startDate) match.createdAt.$gte = new Date(startDate);
    if (endDate) match.createdAt.$lte = new Date(endDate);
  }
  
  return this.aggregate([
    { $match: match },
    {
      $group: {
        _id: null,
        total: { $sum: 1 },
        validated: {
          $sum: {
            $cond: [{ $eq: ['$status', 'VALIDATED'] }, 1, 0]
          }
        },
        rejected: {
          $sum: {
            $cond: [{ $eq: ['$status', 'REJECTED'] }, 1, 0]
          }
        },
        pending: {
          $sum: {
            $cond: [{ $eq: ['$status', 'PENDING'] }, 1, 0]
          }
        },
        avgMatchScore: {
          $avg: '$facialVerification.matchScore'
        }
      }
    }
  ]);
};

module.exports = mongoose.model('BiometricRegistration', BiometricRegistrationSchema);