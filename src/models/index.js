/**
 * Exportar todos los modelos desde un solo punto
 */

const User = require('./User.model');
const Record = require('./Record.model');
const BiometricRegistration = require('./BiometricRegistration');
const Tablet = require('./Tablet.model');

module.exports = {
  User,
  Record,
  BiometricRegistration,
  Tablet
};
