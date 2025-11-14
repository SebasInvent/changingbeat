/**
 * Application Constants
 */

module.exports = {
  // User Roles
  USER_ROLES: {
    ADMIN: 'admin',
    USER: 'user',
    OPERATOR: 'operator'
  },

  // Record Types
  RECORD_TYPES: {
    ENTRY: 'entry',
    EXIT: 'exit',
    DENIED: 'denied'
  },

  // Terminal Status
  TERMINAL_STATUS: {
    ONLINE: 'online',
    OFFLINE: 'offline',
    ERROR: 'error'
  },

  // MRZ Types
  MRZ_TYPES: {
    TD1: 'TD1',  // ID Cards (3 lines, 30 chars each)
    TD2: 'TD2',  // Some ID Cards (2 lines, 36 chars each)
    TD3: 'TD3'   // Passports (2 lines, 44 chars each)
  },

  // HTTP Status Codes
  HTTP_STATUS: {
    OK: 200,
    CREATED: 201,
    NO_CONTENT: 204,
    BAD_REQUEST: 400,
    UNAUTHORIZED: 401,
    FORBIDDEN: 403,
    NOT_FOUND: 404,
    CONFLICT: 409,
    UNPROCESSABLE_ENTITY: 422,
    TOO_MANY_REQUESTS: 429,
    INTERNAL_SERVER_ERROR: 500,
    SERVICE_UNAVAILABLE: 503
  },

  // Error Messages
  ERROR_MESSAGES: {
    INVALID_CREDENTIALS: 'Usuario o contraseña incorrectos',
    USER_NOT_FOUND: 'Usuario no encontrado',
    USER_EXISTS: 'El usuario ya existe',
    UNAUTHORIZED: 'No autorizado',
    FORBIDDEN: 'Acceso denegado',
    INVALID_TOKEN: 'Token inválido',
    EXPIRED_TOKEN: 'Token expirado',
    VALIDATION_ERROR: 'Error de validación',
    DATABASE_ERROR: 'Error en la base de datos',
    INTERNAL_ERROR: 'Error interno del servidor'
  },

  // Success Messages
  SUCCESS_MESSAGES: {
    USER_CREATED: 'Usuario creado exitosamente',
    USER_UPDATED: 'Usuario actualizado exitosamente',
    USER_DELETED: 'Usuario eliminado exitosamente',
    RECORD_CREATED: 'Registro creado exitosamente',
    LOGIN_SUCCESS: 'Inicio de sesión exitoso',
    LOGOUT_SUCCESS: 'Sesión cerrada exitosamente'
  },

  // Pagination Defaults
  PAGINATION: {
    DEFAULT_PAGE: 1,
    DEFAULT_LIMIT: 20,
    MAX_LIMIT: 100
  },

  // Temperature Ranges (Celsius)
  TEMPERATURE: {
    MIN_NORMAL: 35.0,
    MAX_NORMAL: 37.5,
    MAX_ALLOWED: 38.0
  },

  // Socket.io Events
  SOCKET_EVENTS: {
    CONNECTION: 'connection',
    DISCONNECT: 'disconnect',
    ERROR: 'error',
    
    // Custom events
    ENTRY_REGISTERED: 'entry:registered',
    TERMINAL_STATUS: 'terminal:status',
    USER_UPDATED: 'user:updated',
    ALERT: 'alert',
    HEARTBEAT: 'heartbeat'
  },

  // Regex Patterns
  REGEX: {
    EMAIL: /^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/,
    PHONE: /^[0-9]{7,15}$/,
    PASSWORD: /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$/
  }
};
