/**
 * Exportar todos los controladores desde un solo punto
 */

const authController = require('./auth.controller');
const userController = require('./user.controller');
const recordController = require('./record.controller');
const terminalController = require('./terminal.controller');
const dashboardController = require('./dashboard.controller');

module.exports = {
  authController,
  userController,
  recordController,
  terminalController,
  dashboardController
};
