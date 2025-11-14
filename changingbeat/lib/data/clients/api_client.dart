import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../../core/constants/app_constants.dart';
import '../models/api_response.dart';
import '../models/user_model.dart';
import '../models/biometric_record_model.dart';

/// Cliente HTTP para comunicación con la API del backend
class ApiClient {
  late final Dio _dio;
  final Logger _logger = Logger();
  String? _authToken;

  ApiClient({String? baseUrl}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? AppConstants.apiBaseUrl,
        connectTimeout: AppConstants.connectionTimeout,
        receiveTimeout: AppConstants.apiTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  /// Configurar interceptores de Dio
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Agregar token de autenticación si existe
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }

          _logger.d('REQUEST[${options.method}] => ${options.uri}');
          _logger.d('Headers: ${options.headers}');
          if (options.data != null) {
            _logger.d('Body: ${options.data}');
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.i(
            'RESPONSE[${response.statusCode}] => ${response.requestOptions.uri}',
          );
          return handler.next(response);
        },
        onError: (error, handler) {
          _logger.e(
            'ERROR[${error.response?.statusCode}] => ${error.requestOptions.uri}',
          );
          _logger.e('Error message: ${error.message}');
          if (error.response?.data != null) {
            _logger.e('Error data: ${error.response?.data}');
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Establecer token de autenticación
  void setAuthToken(String token) {
    _authToken = token;
    _logger.i('Auth token set');
  }

  /// Limpiar token de autenticación
  void clearAuthToken() {
    _authToken = null;
    _logger.i('Auth token cleared');
  }

  /// Método GET genérico
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
      );

      return ApiResponse<T>.fromJson(
        response.data as Map<String, dynamic>,
        fromJson,
      );
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      _logger.e('Unexpected error in GET request: $e');
      return ApiResponse<T>(
        success: false,
        error: 'Error inesperado: $e',
      );
    }
  }

  /// Método POST genérico
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );

      return ApiResponse<T>.fromJson(
        response.data as Map<String, dynamic>,
        fromJson,
      );
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      _logger.e('Unexpected error in POST request: $e');
      return ApiResponse<T>(
        success: false,
        error: 'Error inesperado: $e',
      );
    }
  }

  /// Método PUT genérico
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
      );

      return ApiResponse<T>.fromJson(
        response.data as Map<String, dynamic>,
        fromJson,
      );
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      _logger.e('Unexpected error in PUT request: $e');
      return ApiResponse<T>(
        success: false,
        error: 'Error inesperado: $e',
      );
    }
  }

  /// Método DELETE genérico
  Future<ApiResponse<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        queryParameters: queryParameters,
      );

      return ApiResponse<T>.fromJson(
        response.data as Map<String, dynamic>,
        fromJson,
      );
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      _logger.e('Unexpected error in DELETE request: $e');
      return ApiResponse<T>(
        success: false,
        error: 'Error inesperado: $e',
      );
    }
  }

  /// Manejar errores de Dio
  ApiResponse<T> _handleDioError<T>(DioException error) {
    String errorMessage;
    int? statusCode = error.response?.statusCode;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        errorMessage = 'Tiempo de conexión agotado';
        break;
      case DioExceptionType.sendTimeout:
        errorMessage = 'Tiempo de envío agotado';
        break;
      case DioExceptionType.receiveTimeout:
        errorMessage = 'Tiempo de respuesta agotado';
        break;
      case DioExceptionType.badResponse:
        errorMessage = _extractErrorMessage(error.response?.data) ??
            'Error del servidor (${statusCode})';
        break;
      case DioExceptionType.cancel:
        errorMessage = 'Solicitud cancelada';
        break;
      case DioExceptionType.connectionError:
        errorMessage = 'Error de conexión. Verifique su conexión a internet';
        break;
      default:
        errorMessage = 'Error de red: ${error.message}';
    }

    _logger.e('Dio error handled: $errorMessage');

    return ApiResponse<T>(
      success: false,
      error: errorMessage,
      statusCode: statusCode,
    );
  }

  /// Extraer mensaje de error de la respuesta
  String? _extractErrorMessage(dynamic data) {
    if (data == null) return null;

    if (data is Map<String, dynamic>) {
      return data['error'] as String? ??
          data['message'] as String? ??
          data['msg'] as String?;
    }

    if (data is String) {
      return data;
    }

    return null;
  }

  // ==================== MÉTODOS DE AUTENTICACIÓN ====================

  /// Login de usuario
  Future<AuthResponse> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.endpointLogin,
        data: {
          'username': username,
          'password': password,
        },
      );

      final authResponse = AuthResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      if (authResponse.success && authResponse.token != null) {
        setAuthToken(authResponse.token!);
      }

      return authResponse;
    } on DioException catch (e) {
      _logger.e('Login error: ${e.message}');
      return AuthResponse(
        success: false,
        message: _extractErrorMessage(e.response?.data) ?? 'Error de login',
      );
    } catch (e) {
      _logger.e('Unexpected login error: $e');
      return AuthResponse(
        success: false,
        message: 'Error inesperado durante el login',
      );
    }
  }

  /// Logout de usuario
  Future<void> logout() async {
    clearAuthToken();
    _logger.i('User logged out');
  }

  // ==================== MÉTODOS DE HEALTH CHECK ====================

  /// Verificar estado del servidor
  Future<ApiResponse<Map<String, dynamic>>> checkHealth() async {
    return get<Map<String, dynamic>>(
      AppConstants.endpointHealth,
      fromJson: (data) => data as Map<String, dynamic>,
    );
  }

  // ==================== MÉTODOS DE REGISTRO BIOMÉTRICO ====================

  /// Registrar datos biométricos
  Future<ApiResponse<BiometricRecordModel>> registerBiometric(
    BiometricRegistrationRequest request,
  ) async {
    return post<BiometricRecordModel>(
      AppConstants.endpointBiometricRegister,
      data: request.toJson(),
      fromJson: (data) => BiometricRecordModel.fromJson(
        data as Map<String, dynamic>,
      ),
    );
  }

  /// Validar datos biométricos
  Future<BiometricValidationResponse> validateBiometric(
    BiometricValidationRequest request,
  ) async {
    try {
      final response = await _dio.post(
        AppConstants.endpointBiometricValidate,
        data: request.toJson(),
      );

      return BiometricValidationResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      _logger.e('Validation error: ${e.message}');
      return BiometricValidationResponse(
        success: false,
        isMatch: false,
        message:
            _extractErrorMessage(e.response?.data) ?? 'Error de validación',
      );
    } catch (e) {
      _logger.e('Unexpected validation error: $e');
      return BiometricValidationResponse(
        success: false,
        isMatch: false,
        message: 'Error inesperado durante la validación',
      );
    }
  }

  /// Obtener lista de registros biométricos
  Future<ApiResponse<List<BiometricRecordModel>>> getRecords({
    int? limit,
    int? skip,
    String? status,
  }) async {
    return get<List<BiometricRecordModel>>(
      AppConstants.endpointRecords,
      queryParameters: {
        if (limit != null) 'limit': limit,
        if (skip != null) 'skip': skip,
        if (status != null) 'status': status,
      },
      fromJson: (data) {
        final list = data as List;
        return list
            .map((item) =>
                BiometricRecordModel.fromJson(item as Map<String, dynamic>))
            .toList();
      },
    );
  }

  /// Obtener un registro biométrico por ID
  Future<ApiResponse<BiometricRecordModel>> getRecordById(String id) async {
    return get<BiometricRecordModel>(
      '${AppConstants.endpointRecords}/$id',
      fromJson: (data) => BiometricRecordModel.fromJson(
        data as Map<String, dynamic>,
      ),
    );
  }
}
