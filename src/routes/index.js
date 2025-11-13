const express = require('express');
const router = express.Router();

// Importar rutas
const authRoutes = require('./auth.routes');
const userRoutes = require('./user.routes');
const recordRoutes = require('./record.routes');
const terminalRoutes = require('./terminal.routes');
const dashboardRoutes = require('./dashboard.routes');
const biometricRoutes = require('./biometric.routes');
const tabletRoutes = require('./tablet.routes');

/**
 * Configurar rutas de la API v1
 */

// Ruta de health check
router.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'API funcionando correctamente',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Rutas de autenticación
router.use('/auth', authRoutes);

// Rutas de usuarios
router.use('/users', userRoutes);

// Rutas de registros
router.use('/records', recordRoutes);

// Rutas de terminales
router.use('/terminals', terminalRoutes);

// Rutas de dashboard
router.use('/dashboard', dashboardRoutes);

// Rutas de verificación biométrica
router.use('/biometric', biometricRoutes);

// Rutas de gestión de tablets
router.use('/tablets', tabletRoutes);

// Ruta 404 para API
router.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: 'Endpoint no encontrado',
    path: req.originalUrl
  });
});

module.exports = router;
