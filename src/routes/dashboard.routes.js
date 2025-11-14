const express = require('express');
const router = express.Router();
const { dashboardController } = require('../controllers');
const { optionalAuth } = require('../middlewares');

/**
 * @route   GET /api/v1/dashboard/metrics
 * @desc    Obtener todas las métricas del dashboard
 * @access  Public (sin auth para el dashboard público)
 */
router.get('/metrics',
  optionalAuth,
  dashboardController.getMetrics
);

/**
 * @route   GET /api/v1/dashboard/hourly-activity
 * @desc    Obtener actividad por hora
 * @access  Public
 */
router.get('/hourly-activity',
  optionalAuth,
  dashboardController.getHourlyActivity
);

/**
 * @route   GET /api/v1/dashboard/summary
 * @desc    Obtener resumen ejecutivo
 * @access  Public
 */
router.get('/summary',
  optionalAuth,
  dashboardController.getSummary
);

module.exports = router;
