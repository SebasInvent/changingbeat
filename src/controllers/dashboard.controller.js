const { recordService, userService } = require('../services');
const { successResponse } = require('../utils/response');
const { asyncHandler } = require('../middlewares');

/**
 * Controlador del Dashboard
 */
class DashboardController {
  /**
   * Obtener métricas completas del dashboard
   * GET /api/v1/dashboard/metrics
   */
  getMetrics = asyncHandler(async (req, res) => {
    const [userStats, todayStats, generalStats] = await Promise.all([
      userService.getUserStats(),
      recordService.getTodayStats(),
      recordService.getGeneralStats()
    ]);

    const metrics = {
      users: userStats,
      today: todayStats,
      general: generalStats,
      timestamp: new Date().toISOString()
    };

    return successResponse(
      res,
      metrics,
      'Métricas del dashboard obtenidas'
    );
  });

  /**
   * Obtener actividad por hora del día actual
   * GET /api/v1/dashboard/hourly-activity
   */
  getHourlyActivity = asyncHandler(async (req, res) => {
    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);

    const records = await recordService.listRecords({
      startDate: startOfDay.toISOString()
    }, 1, 1000); // Obtener muchos registros para procesar

    // Agrupar por hora
    const hourlyData = new Array(24).fill(0);
    
    if (records.records) {
      records.records.forEach(record => {
        const hour = new Date(record.createdAt).getHours();
        hourlyData[hour]++;
      });
    }

    const labels = [];
    for (let i = 0; i < 24; i++) {
      labels.push(`${i}:00`);
    }

    return successResponse(
      res,
      {
        labels,
        data: hourlyData
      },
      'Actividad por hora obtenida'
    );
  });

  /**
   * Obtener resumen ejecutivo
   * GET /api/v1/dashboard/summary
   */
  getSummary = asyncHandler(async (req, res) => {
    const [
      userStats,
      todayStats,
      generalStats,
      recentRecords
    ] = await Promise.all([
      userService.getUserStats(),
      recordService.getTodayStats(),
      recordService.getGeneralStats(),
      recordService.getRecentRecords(5)
    ]);

    const summary = {
      totalUsers: userStats.total,
      activeUsers: userStats.active,
      todayTotal: todayStats.total,
      todayEntry: todayStats.entry,
      todayExit: todayStats.exit,
      todayDenied: todayStats.denied,
      avgTemperature: generalStats.temperature?.average,
      highTempCount: generalStats.temperature?.highCount,
      recentActivity: recentRecords,
      generatedAt: new Date().toISOString()
    };

    return successResponse(
      res,
      summary,
      'Resumen ejecutivo obtenido'
    );
  });
}

module.exports = new DashboardController();
