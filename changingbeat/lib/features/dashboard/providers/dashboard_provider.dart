import 'package:flutter/foundation.dart';
import '../../../data/services/api_service.dart';
import '../../../data/models/biometric_record_model.dart';

/// Provider para gestionar el estado del Dashboard
class DashboardProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Estado de carga
  bool _isLoading = false;
  String? _errorMessage;

  // Estadísticas
  int _totalRecords = 0;
  int _todayRecords = 0;
  int _successfulRecords = 0;
  int _failedRecords = 0;

  // Registros recientes
  List<BiometricRecordModel> _recentRecords = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalRecords => _totalRecords;
  int get todayRecords => _todayRecords;
  int get successfulRecords => _successfulRecords;
  int get failedRecords => _failedRecords;
  List<BiometricRecordModel> get recentRecords => _recentRecords;

  /// Cargar estadísticas del dashboard
  Future<void> loadDashboardData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Cargar registros recientes (últimos 10)
      final recordsResponse = await _apiService.getRecords(
        limit: 10,
        skip: 0,
      );

      if (recordsResponse.success && recordsResponse.data != null) {
        _recentRecords = recordsResponse.data!;
        _totalRecords = recordsResponse.data!.length;

        // Calcular estadísticas
        _calculateStatistics();
      } else {
        _errorMessage = recordsResponse.error ?? 'Error al cargar datos';
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: $e';
      debugPrint('Error loading dashboard data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Calcular estadísticas basadas en los registros
  void _calculateStatistics() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _todayRecords = 0;
    _successfulRecords = 0;
    _failedRecords = 0;

    for (var record in _recentRecords) {
      // Contar registros de hoy
      final recordDate = DateTime(
        record.createdAt.year,
        record.createdAt.month,
        record.createdAt.day,
      );
      if (recordDate.isAtSameMomentAs(today)) {
        _todayRecords++;
      }

      // Contar exitosos vs fallidos
      if (record.status == 'approved' || record.status == 'success') {
        _successfulRecords++;
      } else if (record.status == 'rejected' || record.status == 'failed') {
        _failedRecords++;
      }
    }
  }

  /// Refrescar datos
  Future<void> refresh() async {
    await loadDashboardData();
  }

  /// Limpiar mensaje de error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Resetear estadísticas
  void reset() {
    _totalRecords = 0;
    _todayRecords = 0;
    _successfulRecords = 0;
    _failedRecords = 0;
    _recentRecords = [];
    _errorMessage = null;
    notifyListeners();
  }
}
