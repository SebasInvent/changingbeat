import 'package:flutter/foundation.dart';
import '../../../data/services/api_service.dart';
import '../../../data/models/biometric_record_model.dart';

/// Provider para gestionar el estado de los registros
class RecordsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Estado de carga
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  // Datos
  List<BiometricRecordModel> _records = [];
  bool _hasMoreRecords = true;
  int _currentPage = 0;
  final int _pageSize = 20;

  // Filtros
  String? _statusFilter;
  String? _searchQuery;
  DateTime? _startDate;
  DateTime? _endDate;

  // Getters
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  List<BiometricRecordModel> get records => _records;
  bool get hasMoreRecords => _hasMoreRecords;
  String? get statusFilter => _statusFilter;
  String? get searchQuery => _searchQuery;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  /// Cargar registros (primera página)
  Future<void> loadRecords() async {
    _isLoading = true;
    _errorMessage = null;
    _currentPage = 0;
    _hasMoreRecords = true;
    notifyListeners();

    try {
      final response = await _apiService.getRecords(
        limit: _pageSize,
        skip: 0,
        status: _statusFilter,
      );

      if (response.success && response.data != null) {
        _records = response.data!;
        _hasMoreRecords = response.data!.length >= _pageSize;
        _currentPage = 1;
      } else {
        _errorMessage = response.error ?? 'Error al cargar registros';
        _records = [];
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: $e';
      _records = [];
      debugPrint('Error loading records: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cargar más registros (paginación)
  Future<void> loadMoreRecords() async {
    if (_isLoadingMore || !_hasMoreRecords) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final response = await _apiService.getRecords(
        limit: _pageSize,
        skip: _currentPage * _pageSize,
        status: _statusFilter,
      );

      if (response.success && response.data != null) {
        _records.addAll(response.data!);
        _hasMoreRecords = response.data!.length >= _pageSize;
        _currentPage++;
      }
    } catch (e) {
      debugPrint('Error loading more records: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Refrescar registros
  Future<void> refresh() async {
    await loadRecords();
  }

  /// Aplicar filtro de estado
  void setStatusFilter(String? status) {
    if (_statusFilter != status) {
      _statusFilter = status;
      loadRecords();
    }
  }

  /// Aplicar búsqueda
  void setSearchQuery(String? query) {
    _searchQuery = query;
    _applyLocalFilters();
  }

  /// Aplicar filtro de fechas
  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    _applyLocalFilters();
  }

  /// Aplicar filtros locales (búsqueda y fechas)
  void _applyLocalFilters() {
    // TODO: Implementar filtros locales si la API no los soporta
    // Por ahora solo notificamos
    notifyListeners();
  }

  /// Limpiar filtros
  void clearFilters() {
    _statusFilter = null;
    _searchQuery = null;
    _startDate = null;
    _endDate = null;
    loadRecords();
  }

  /// Obtener registros filtrados (para búsqueda local)
  List<BiometricRecordModel> get filteredRecords {
    var filtered = List<BiometricRecordModel>.from(_records);

    // Filtrar por búsqueda
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final query = _searchQuery!.toLowerCase();
      filtered = filtered.where((record) {
        return record.fullName.toLowerCase().contains(query) ||
            record.documentNumber.toLowerCase().contains(query);
      }).toList();
    }

    // Filtrar por rango de fechas
    if (_startDate != null) {
      filtered = filtered.where((record) {
        return record.createdAt.isAfter(_startDate!) ||
            record.createdAt.isAtSameMomentAs(_startDate!);
      }).toList();
    }

    if (_endDate != null) {
      final endOfDay = DateTime(
        _endDate!.year,
        _endDate!.month,
        _endDate!.day,
        23,
        59,
        59,
      );
      filtered = filtered.where((record) {
        return record.createdAt.isBefore(endOfDay) ||
            record.createdAt.isAtSameMomentAs(endOfDay);
      }).toList();
    }

    return filtered;
  }

  /// Obtener estadísticas de los registros
  Map<String, int> get statistics {
    final stats = {
      'total': _records.length,
      'approved': 0,
      'pending': 0,
      'rejected': 0,
    };

    for (var record in _records) {
      if (record.status == 'approved' || record.status == 'success') {
        stats['approved'] = (stats['approved'] ?? 0) + 1;
      } else if (record.status == 'pending') {
        stats['pending'] = (stats['pending'] ?? 0) + 1;
      } else if (record.status == 'rejected' || record.status == 'failed') {
        stats['rejected'] = (stats['rejected'] ?? 0) + 1;
      }
    }

    return stats;
  }

  /// Limpiar mensaje de error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Resetear provider
  void reset() {
    _records = [];
    _currentPage = 0;
    _hasMoreRecords = true;
    _statusFilter = null;
    _searchQuery = null;
    _startDate = null;
    _endDate = null;
    _errorMessage = null;
    notifyListeners();
  }
}
