const { User } = require('../models');
const logger = require('../utils/logger');
const { 
  NotFoundError, 
  ConflictError, 
  DatabaseError 
} = require('../utils/errors');
const { ERROR_MESSAGES, PAGINATION } = require('../config/constants');

/**
 * Servicio de Usuarios
 */
class UserService {
  /**
   * Crear nuevo usuario
   */
  async createUser(userData) {
    try {
      // Verificar si el email ya existe
      const existingUser = await User.findByEmail(userData.email);
      if (existingUser) {
        throw new ConflictError('El email ya está registrado');
      }

      // Verificar biometricId si existe
      if (userData.biometricId) {
        const existingBiometric = await User.findOne({ 
          biometricId: userData.biometricId 
        });
        if (existingBiometric) {
          throw new ConflictError('El ID biométrico ya está registrado');
        }
      }

      // Crear usuario
      const user = new User(userData);
      await user.save();

      logger.info('Usuario creado exitosamente', { 
        userId: user._id, 
        email: user.email 
      });

      return user;
    } catch (error) {
      logger.error('Error creando usuario:', error);
      throw error;
    }
  }

  /**
   * Obtener usuario por ID
   */
  async getUserById(userId) {
    try {
      const user = await User.findById(userId);

      if (!user) {
        throw new NotFoundError(ERROR_MESSAGES.USER_NOT_FOUND);
      }

      return user;
    } catch (error) {
      if (error.name === 'CastError') {
        throw new NotFoundError(ERROR_MESSAGES.USER_NOT_FOUND);
      }
      throw error;
    }
  }

  /**
   * Obtener usuario por email
   */
  async getUserByEmail(email) {
    try {
      const user = await User.findByEmail(email);

      if (!user) {
        throw new NotFoundError(ERROR_MESSAGES.USER_NOT_FOUND);
      }

      return user;
    } catch (error) {
      throw error;
    }
  }

  /**
   * Obtener usuario por biometricId
   */
  async getUserByBiometricId(biometricId) {
    try {
      const user = await User.findOne({ biometricId });

      if (!user) {
        throw new NotFoundError('Usuario biométrico no encontrado');
      }

      return user;
    } catch (error) {
      throw error;
    }
  }

  /**
   * Actualizar usuario
   */
  async updateUser(userId, updates) {
    try {
      // Verificar que el usuario existe
      const user = await User.findById(userId);
      if (!user) {
        throw new NotFoundError(ERROR_MESSAGES.USER_NOT_FOUND);
      }

      // Si se actualiza el email, verificar que no exista
      if (updates.email && updates.email !== user.email) {
        const existingUser = await User.findByEmail(updates.email);
        if (existingUser) {
          throw new ConflictError('El email ya está en uso');
        }
      }

      // Si se actualiza biometricId, verificar que no exista
      if (updates.biometricId && updates.biometricId !== user.biometricId) {
        const existingBiometric = await User.findOne({ 
          biometricId: updates.biometricId 
        });
        if (existingBiometric) {
          throw new ConflictError('El ID biométrico ya está en uso');
        }
      }

      // No permitir actualizar password directamente (usar changePassword)
      if (updates.password) {
        delete updates.password;
      }

      // Actualizar usuario
      Object.assign(user, updates);
      await user.save();

      logger.info('Usuario actualizado exitosamente', { userId: user._id });

      return user;
    } catch (error) {
      logger.error('Error actualizando usuario:', error);
      throw error;
    }
  }

  /**
   * Eliminar usuario (soft delete)
   */
  async deleteUser(userId) {
    try {
      const user = await User.findById(userId);

      if (!user) {
        throw new NotFoundError(ERROR_MESSAGES.USER_NOT_FOUND);
      }

      // Soft delete: desactivar usuario
      user.isActive = false;
      await user.save();

      logger.info('Usuario desactivado', { userId: user._id });

      return { message: 'Usuario eliminado exitosamente' };
    } catch (error) {
      logger.error('Error eliminando usuario:', error);
      throw error;
    }
  }

  /**
   * Eliminar usuario permanentemente
   */
  async hardDeleteUser(userId) {
    try {
      const user = await User.findByIdAndDelete(userId);

      if (!user) {
        throw new NotFoundError(ERROR_MESSAGES.USER_NOT_FOUND);
      }

      logger.warn('Usuario eliminado permanentemente', { userId });

      return { message: 'Usuario eliminado permanentemente' };
    } catch (error) {
      logger.error('Error eliminando usuario permanentemente:', error);
      throw error;
    }
  }

  /**
   * Listar usuarios con paginación y filtros
   */
  async listUsers(filters = {}, page = 1, limit = 20) {
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

      // Filtros opcionales
      if (filters.role) {
        query.role = filters.role;
      }

      if (filters.isActive !== undefined) {
        query.isActive = filters.isActive === 'true' || filters.isActive === true;
      }

      if (filters.search) {
        // Búsqueda por nombre o email
        const searchRegex = new RegExp(filters.search, 'i');
        query.$or = [
          { firstName: searchRegex },
          { lastName: searchRegex },
          { email: searchRegex }
        ];
      }

      // Ejecutar queries en paralelo
      const [users, total] = await Promise.all([
        User.find(query)
          .select('-password')
          .sort({ createdAt: -1 })
          .skip(skip)
          .limit(limit)
          .lean(),
        User.countDocuments(query)
      ]);

      const pages = Math.ceil(total / limit);

      return {
        users,
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
      logger.error('Error listando usuarios:', error);
      throw new DatabaseError('Error al listar usuarios', error);
    }
  }

  /**
   * Listar solo usuarios activos
   */
  async listActiveUsers(page = 1, limit = 20) {
    return this.listUsers({ isActive: true }, page, limit);
  }

  /**
   * Buscar usuarios por nombre
   */
  async searchUsers(searchTerm, limit = 10) {
    try {
      const searchRegex = new RegExp(searchTerm, 'i');

      const users = await User.find({
        $or: [
          { firstName: searchRegex },
          { lastName: searchRegex },
          { email: searchRegex }
        ],
        isActive: true
      })
        .select('firstName secondName lastName secondLastName email photoBase64')
        .limit(limit)
        .lean();

      return users;
    } catch (error) {
      logger.error('Error buscando usuarios:', error);
      throw error;
    }
  }

  /**
   * Obtener estadísticas de usuarios
   */
  async getUserStats() {
    try {
      const [total, active, inactive, byRole] = await Promise.all([
        User.countDocuments(),
        User.countDocuments({ isActive: true }),
        User.countDocuments({ isActive: false }),
        User.aggregate([
          {
            $group: {
              _id: '$role',
              count: { $sum: 1 }
            }
          }
        ])
      ]);

      const roleStats = {};
      byRole.forEach(item => {
        roleStats[item._id] = item.count;
      });

      return {
        total,
        active,
        inactive,
        byRole: roleStats
      };
    } catch (error) {
      logger.error('Error obteniendo estadísticas:', error);
      throw error;
    }
  }

  /**
   * Activar/desactivar usuario
   */
  async toggleUserStatus(userId) {
    try {
      const user = await User.findById(userId);

      if (!user) {
        throw new NotFoundError(ERROR_MESSAGES.USER_NOT_FOUND);
      }

      user.isActive = !user.isActive;
      await user.save();

      logger.info(`Usuario ${user.isActive ? 'activado' : 'desactivado'}`, { 
        userId: user._id 
      });

      return user;
    } catch (error) {
      logger.error('Error cambiando estado de usuario:', error);
      throw error;
    }
  }

  /**
   * Actualizar foto biométrica
   */
  async updatePhoto(userId, photoBase64) {
    try {
      const user = await User.findById(userId);

      if (!user) {
        throw new NotFoundError(ERROR_MESSAGES.USER_NOT_FOUND);
      }

      user.photoBase64 = photoBase64;
      await user.save();

      logger.info('Foto actualizada', { userId: user._id });

      return user;
    } catch (error) {
      logger.error('Error actualizando foto:', error);
      throw error;
    }
  }

  /**
   * Actualizar ID biométrico
   */
  async updateBiometricId(userId, biometricId) {
    try {
      const user = await User.findById(userId);

      if (!user) {
        throw new NotFoundError(ERROR_MESSAGES.USER_NOT_FOUND);
      }

      // Verificar que el biometricId no esté en uso
      if (biometricId) {
        const existing = await User.findOne({ biometricId });
        if (existing && existing._id.toString() !== userId) {
          throw new ConflictError('El ID biométrico ya está en uso');
        }
      }

      user.biometricId = biometricId;
      await user.save();

      logger.info('ID biométrico actualizado', { userId: user._id });

      return user;
    } catch (error) {
      logger.error('Error actualizando ID biométrico:', error);
      throw error;
    }
  }
}

module.exports = new UserService();
