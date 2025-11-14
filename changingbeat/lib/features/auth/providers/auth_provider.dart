import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/services/api_service.dart';
import '../../../data/models/user_model.dart';

/// Provider para gestionar el estado de autenticación
class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  UserModel? _currentUser;
  String? _authToken;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  UserModel? get currentUser => _currentUser;
  String? get authToken => _authToken;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Keys para SharedPreferences
  static const String _keyAuthToken = 'auth_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUsername = 'username';
  static const String _keyUserRole = 'user_role';

  /// Inicializar y verificar si hay sesión guardada
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_keyAuthToken);

      if (token != null && token.isNotEmpty) {
        // Restaurar sesión
        _authToken = token;
        _apiService.setAuthToken(token);

        // Restaurar datos del usuario
        _currentUser = UserModel(
          id: prefs.getString(_keyUserId) ?? '',
          username: prefs.getString(_keyUsername) ?? '',
          role: prefs.getString(_keyUserRole) ?? 'operator',
        );

        _isAuthenticated = true;

        // Verificar que el token siga siendo válido
        final healthCheck = await _apiService.checkHealth();
        if (!healthCheck.success) {
          // Token inválido, limpiar sesión
          await logout();
        }
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
      await logout();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Login de usuario
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.login(
        username: username,
        password: password,
      );

      if (response.success && response.token != null && response.user != null) {
        _authToken = response.token;
        _currentUser = response.user;
        _isAuthenticated = true;

        // Guardar en SharedPreferences
        await _saveAuthData(response.token!, response.user!);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message ?? 'Error de autenticación';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout de usuario
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.logout();
      await _clearAuthData();

      _authToken = null;
      _currentUser = null;
      _isAuthenticated = false;
      _errorMessage = null;
    } catch (e) {
      debugPrint('Error during logout: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Guardar datos de autenticación
  Future<void> _saveAuthData(String token, UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAuthToken, token);
      await prefs.setString(_keyUserId, user.id);
      await prefs.setString(_keyUsername, user.username);
      await prefs.setString(_keyUserRole, user.role);
    } catch (e) {
      debugPrint('Error saving auth data: $e');
    }
  }

  /// Limpiar datos de autenticación
  Future<void> _clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyAuthToken);
      await prefs.remove(_keyUserId);
      await prefs.remove(_keyUsername);
      await prefs.remove(_keyUserRole);
    } catch (e) {
      debugPrint('Error clearing auth data: $e');
    }
  }

  /// Limpiar mensaje de error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
