/**
 * Exportar todos los modelos desde un solo punto
 */

const User = require('./User.model');
const Record = require('./Record.model');

module.exports = {
  User,
  Record
};
