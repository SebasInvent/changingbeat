const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
const { v4: uuidv4 } = require('uuid');
const config = require('../config/env');
const { USER_ROLES } = require('../config/constants');

/**
 * Schema de Usuario
 */
const UserSchema = new mongoose.Schema({
  _id: {
    type: String,
    default: () => uuidv4()
  },
  
  // Información Personal
  firstName: {
    type: String,
    required: [true, 'El primer nombre es requerido'],
    trim: true,
    minlength: [2, 'El primer nombre debe tener al menos 2 caracteres'],
    maxlength: [50, 'El primer nombre no puede exceder 50 caracteres']
  },
  
  secondName: {
    type: String,
    trim: true,
    maxlength: [50, 'El segundo nombre no puede exceder 50 caracteres']
  },
  
  lastName: {
    type: String,
    required: [true, 'El apellido es requerido'],
    trim: true,
    minlength: [2, 'El apellido debe tener al menos 2 caracteres'],
    maxlength: [50, 'El apellido no puede exceder 50 caracteres']
  },
  
  secondLastName: {
    type: String,
    trim: true,
    maxlength: [50, 'El segundo apellido no puede exceder 50 caracteres']
  },
  
  // Información de Contacto
  email: {
    type: String,
    required: [true, 'El email es requerido'],
    unique: true,
    lowercase: true,
    trim: true,
    validate: {
      validator: function(v) {
        return /^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/.test(v);
      },
      message: 'Formato de email inválido'
    }
  },
  
  phone: {
    type: String,
    trim: true,
    validate: {
      validator: function(v) {
        return !v || /^[0-9]{7,15}$/.test(v);
      },
      message: 'Formato de teléfono inválido'
    }
  },
  
  // Seguridad
  password: {
    type: String,
    required: [true, 'La contraseña es requerida'],
    minlength: [8, 'La contraseña debe tener al menos 8 caracteres'],
    select: false // No incluir en queries por defecto
  },
  
  // Datos Biométricos
  photoBase64: {
    type: String
  },
  
  biometricId: {
    type: String,
    sparse: true // Permite múltiples valores null
  },
  
  // Control de Acceso
  role: {
    type: String,
    enum: Object.values(USER_ROLES),
    default: USER_ROLES.USER
  },
  
  isActive: {
    type: Boolean,
    default: true
  },
  
  // Metadata
  lastLogin: {
    type: Date
  },
  
  loginAttempts: {
    type: Number,
    default: 0
  },
  
  lockUntil: {
    type: Date
  }
}, {
  timestamps: true, // Agrega createdAt y updatedAt
  toJSON: {
    transform: function(doc, ret) {
      // No exponer datos sensibles en JSON
      delete ret.password;
      delete ret.__v;
      delete ret.loginAttempts;
      delete ret.lockUntil;
      return ret;
    }
  },
  toObject: {
    transform: function(doc, ret) {
      delete ret.password;
      delete ret.__v;
      return ret;
    }
  }
});

/**
 * Índices
 */
UserSchema.index({ email: 1 });
UserSchema.index({ biometricId: 1 }, { sparse: true });
UserSchema.index({ createdAt: -1 });
UserSchema.index({ isActive: 1 });

/**
 * Virtual: Nombre completo
 */
UserSchema.virtual('fullName').get(function() {
  const parts = [
    this.firstName,
    this.secondName,
    this.lastName,
    this.secondLastName
  ].filter(Boolean);
  return parts.join(' ');
});

/**
 * Pre-save Hook: Hash password
 */
UserSchema.pre('save', async function(next) {
  // Solo hashear si el password fue modificado
  if (!this.isModified('password')) {
    return next();
  }
  
  try {
    const salt = await bcrypt.genSalt(config.bcrypt.rounds);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

/**
 * Método de instancia: Comparar contraseña
 */
UserSchema.methods.comparePassword = async function(candidatePassword) {
  try {
    return await bcrypt.compare(candidatePassword, this.password);
  } catch (error) {
    throw error;
  }
};

/**
 * Método de instancia: Verificar si la cuenta está bloqueada
 */
UserSchema.methods.isLocked = function() {
  return !!(this.lockUntil && this.lockUntil > Date.now());
};

/**
 * Método de instancia: Incrementar intentos de login
 */
UserSchema.methods.incLoginAttempts = function() {
  // Si el bloqueo ha expirado, resetear intentos
  if (this.lockUntil && this.lockUntil < Date.now()) {
    return this.updateOne({
      $set: { loginAttempts: 1 },
      $unset: { lockUntil: 1 }
    });
  }
  
  // Incrementar intentos
  const updates = { $inc: { loginAttempts: 1 } };
  
  // Bloquear cuenta después de 5 intentos (2 horas)
  const maxAttempts = 5;
  const lockTime = 2 * 60 * 60 * 1000; // 2 horas
  
  if (this.loginAttempts + 1 >= maxAttempts && !this.isLocked()) {
    updates.$set = { lockUntil: Date.now() + lockTime };
  }
  
  return this.updateOne(updates);
};

/**
 * Método de instancia: Resetear intentos de login
 */
UserSchema.methods.resetLoginAttempts = function() {
  return this.updateOne({
    $set: { loginAttempts: 0, lastLogin: new Date() },
    $unset: { lockUntil: 1 }
  });
};

/**
 * Método estático: Buscar por email
 */
UserSchema.statics.findByEmail = function(email) {
  return this.findOne({ email: email.toLowerCase() });
};

/**
 * Método estático: Buscar activos
 */
UserSchema.statics.findActive = function(filter = {}) {
  return this.find({ ...filter, isActive: true });
};

module.exports = mongoose.model('User', UserSchema);
