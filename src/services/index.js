/**
 * Exportar todos los servicios desde un solo punto
 */

const authService = require('./auth.service');
const userService = require('./user.service');
const recordService = require('./record.service');
const biometricService = require('./biometric.service');
const serialService = require('./serial.service');

module.exports = {
  authService,
  userService,
  recordService,
  biometricService,
  serialService
};
