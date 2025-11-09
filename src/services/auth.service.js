const jwt = require('jsonwebtoken');
const { User } = require('../models');
const config = require('../config/env');
const logger = require('../utils/logger');
const { 
  AuthenticationError, 
  ConflictError, 
  ValidationError 
} = require('../utils/errors');
const { ERROR_MESSAGES, SUCCESS_MESSAGES } = require('../config/constants');

/**
 * Servicio de Autenticación
 */
class AuthService {
  /**
   * Generar token JWT
   */
  generateToken(userId, role) {
    return jwt.sign(
      { userId, role },
      config.jwt.secret,
      { expiresIn: config.jwt.expiration }
    );
  }

  /**
   * Generar refresh token
   */
  generateRefreshToken(userId) {
    return jwt.sign(
      { userId, type: 'refresh' },
      config.jwt.secret,
      { expiresIn: config.jwt.refreshExpiration }
    );
  }

  /**
   * Registrar nuevo usuario
   */
  async register(userData) {
    try {
      // Verificar si el email ya existe
      const existingUser = await User.findByEmail(userData.email);
      if (existingUser) {
        throw new ConflictError('El email ya está registrado');
      }

      // Crear usuario
      const user = new User(userData);
      await user.save();

      logger.info('Usuario registrado exitosamente', { 
        userId: user._id, 
        email: user.email 
      });

      // Generar tokens
      const token = this.generateToken(user._id, user.role);
      const refreshToken = this.generateRefreshToken(user._id);

      return {
        user,
        token,
        refreshToken
      };
    } catch (error) {
      logger.error('Error en registro de usuario:', error);
      throw error;
    }
  }

  /**
   * Iniciar sesión
   */
  async login(email, password) {
    try {
      // Buscar usuario con password incluido
      const user = await User.findOne({ email: email.toLowerCase() })
        .select('+password');

      if (!user) {
        throw new AuthenticationError(ERROR_MESSAGES.INVALID_CREDENTIALS);
      }

      // Verificar si la cuenta está activa
      if (!user.isActive) {
        throw new AuthenticationError('Cuenta desactivada');
      }

      // Verificar si la cuenta está bloqueada
      if (user.isLocked()) {
        throw new AuthenticationError(
          'Cuenta bloqueada temporalmente por múltiples intentos fallidos'
        );
      }

      // Verificar contraseña
      const isPasswordValid = await user.comparePassword(password);

      if (!isPasswordValid) {
        // Incrementar intentos fallidos
        await user.incLoginAttempts();
        throw new AuthenticationError(ERROR_MESSAGES.INVALID_CREDENTIALS);
      }

      // Resetear intentos de login
      await user.resetLoginAttempts();

      logger.info('Inicio de sesión exitoso', { 
        userId: user._id, 
        email: user.email 
      });

      // Generar tokens
      const token = this.generateToken(user._id, user.role);
      const refreshToken = this.generateRefreshToken(user._id);

      // Remover password del objeto de respuesta
      user.password = undefined;

      return {
        user,
        token,
        refreshToken
      };
    } catch (error) {
      logger.error('Error en inicio de sesión:', error);
      throw error;
    }
  }

  /**
   * Refrescar token
   */
  async refreshToken(refreshToken) {
    try {
      // Verificar refresh token
      const decoded = jwt.verify(refreshToken, config.jwt.secret);

      if (decoded.type !== 'refresh') {
        throw new AuthenticationError('Token inválido');
      }

      // Buscar usuario
      const user = await User.findById(decoded.userId);

      if (!user || !user.isActive) {
        throw new AuthenticationError(ERROR_MESSAGES.USER_NOT_FOUND);
      }

      // Generar nuevo token
      const newToken = this.generateToken(user._id, user.role);
      const newRefreshToken = this.generateRefreshToken(user._id);

      return {
        token: newToken,
        refreshToken: newRefreshToken
      };
    } catch (error) {
      if (error.name === 'JsonWebTokenError' || error.name === 'TokenExpiredError') {
        throw new AuthenticationError(ERROR_MESSAGES.INVALID_TOKEN);
      }
      throw error;
    }
  }

  /**
   * Cambiar contraseña
   */
  async changePassword(userId, currentPassword, newPassword) {
    try {
      // Buscar usuario con password
      const user = await User.findById(userId).select('+password');

      if (!user) {
        throw new AuthenticationError(ERROR_MESSAGES.USER_NOT_FOUND);
      }

      // Verificar contraseña actual
      const isPasswordValid = await user.comparePassword(currentPassword);

      if (!isPasswordValid) {
        throw new AuthenticationError('Contraseña actual incorrecta');
      }

      // Actualizar contraseña
      user.password = newPassword;
      await user.save();

      logger.info('Contraseña cambiada exitosamente', { userId: user._id });

      return { message: 'Contraseña actualizada exitosamente' };
    } catch (error) {
      logger.error('Error cambiando contraseña:', error);
      throw error;
    }
  }

  /**
   * Solicitar reseteo de contraseña (placeholder)
   */
  async requestPasswordReset(email) {
    try {
      const user = await User.findByEmail(email);

      if (!user) {
        // Por seguridad, no revelar si el email existe
        logger.warn('Intento de reset para email no existente:', email);
        return { 
          message: 'Si el email existe, recibirás instrucciones para resetear tu contraseña' 
        };
      }

      // TODO: Implementar lógica de envío de email
      logger.info('Solicitud de reset de contraseña', { userId: user._id });

      return { 
        message: 'Si el email existe, recibirás instrucciones para resetear tu contraseña' 
      };
    } catch (error) {
      logger.error('Error en solicitud de reset:', error);
      throw error;
    }
  }

  /**
   * Verificar token
   */
  async verifyToken(token) {
    try {
      const decoded = jwt.verify(token, config.jwt.secret);
      const user = await User.findById(decoded.userId);

      if (!user || !user.isActive) {
        throw new AuthenticationError('Usuario no válido');
      }

      return { valid: true, user };
    } catch (error) {
      throw new AuthenticationError(ERROR_MESSAGES.INVALID_TOKEN);
    }
  }

  /**
   * Logout (invalidar token - requeriría blacklist en producción)
   */
  async logout(userId) {
    try {
      logger.info('Usuario cerró sesión', { userId });
      
      // TODO: En producción, agregar token a blacklist o usar Redis
      
      return { message: SUCCESS_MESSAGES.LOGOUT_SUCCESS };
    } catch (error) {
      logger.error('Error en logout:', error);
      throw error;
    }
  }
}

module.exports = new AuthService();
