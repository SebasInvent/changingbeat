import '../clients/api_client.dart';
import '../models/api_response.dart';
import '../models/user_model.dart';
import '../models/biometric_record_model.dart';

/// Servicio singleton para acceso global al API Client
class ApiService {
  static final ApiService _instance = ApiService._internal();
  late final ApiClient _client;

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    _client = ApiClient();
  }

  /// Obtener instancia del API Client
  ApiClient get client => _client;

  // ==================== MÉTODOS DE AUTENTICACIÓN ====================

  /// Login de usuario
  Future<AuthResponse> login({
    required String username,
    required String password,
  }) async {
    return _client.login(username: username, password: password);
  }

  /// Logout de usuario
  Future<void> logout() async {
    return _client.logout();
  }

  /// Establecer token de autenticación
  void setAuthToken(String token) {
    _client.setAuthToken(token);
  }

  /// Limpiar token de autenticación
  void clearAuthToken() {
    _client.clearAuthToken();
  }

  // ==================== MÉTODOS DE HEALTH CHECK ====================

  /// Verificar estado del servidor
  Future<ApiResponse<Map<String, dynamic>>> checkHealth() async {
    return _client.checkHealth();
  }

  // ==================== MÉTODOS DE REGISTRO BIOMÉTRICO ====================

  /// Registrar datos biométricos
  Future<ApiResponse<BiometricRecordModel>> registerBiometric(
    BiometricRegistrationRequest request,
  ) async {
    return _client.registerBiometric(request);
  }

  /// Validar datos biométricos
  Future<BiometricValidationResponse> validateBiometric(
    BiometricValidationRequest request,
  ) async {
    return _client.validateBiometric(request);
  }

  /// Obtener lista de registros biométricos
  Future<ApiResponse<List<BiometricRecordModel>>> getRecords({
    int? limit,
    int? skip,
    String? status,
  }) async {
    return _client.getRecords(limit: limit, skip: skip, status: status);
  }

  /// Obtener un registro biométrico por ID
  Future<ApiResponse<BiometricRecordModel>> getRecordById(String id) async {
    return _client.getRecordById(id);
  }
}
