import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider para gestionar la configuración de la aplicación
class SettingsProvider with ChangeNotifier {
  // Keys para SharedPreferences
  static const String _keyTabletId = 'tablet_id';
  static const String _keyServerUrl = 'server_url';
  static const String _keyAutoCapture = 'auto_capture';
  static const String _keyFaceDetectionSensitivity =
      'face_detection_sensitivity';
  static const String _keyCameraResolution = 'camera_resolution';
  static const String _keyDebugMode = 'debug_mode';

  // Valores por defecto
  static const String _defaultTabletId = 'TAB-001';
  static const String _defaultServerUrl =
      'https://access-control.eukahack.com/api/v1';
  static const bool _defaultAutoCapture = true;
  static const double _defaultSensitivity = 80.0;
  static const String _defaultResolution = 'high';
  static const bool _defaultDebugMode = false;

  // Configuración actual
  String _tabletId = _defaultTabletId;
  String _serverUrl = _defaultServerUrl;
  bool _autoCapture = _defaultAutoCapture;
  double _faceDetectionSensitivity = _defaultSensitivity;
  String _cameraResolution = _defaultResolution;
  bool _debugMode = _defaultDebugMode;

  bool _isLoading = false;

  // Getters
  String get tabletId => _tabletId;
  String get serverUrl => _serverUrl;
  bool get autoCapture => _autoCapture;
  double get faceDetectionSensitivity => _faceDetectionSensitivity;
  String get cameraResolution => _cameraResolution;
  bool get debugMode => _debugMode;
  bool get isLoading => _isLoading;

  // Información de la app
  String get appName => 'Control de Acceso Biométrico';
  String get appVersion => '2.0.0';
  String get buildNumber => '1';

  /// Inicializar y cargar configuración guardada
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      _tabletId = prefs.getString(_keyTabletId) ?? _defaultTabletId;
      _serverUrl = prefs.getString(_keyServerUrl) ?? _defaultServerUrl;
      _autoCapture = prefs.getBool(_keyAutoCapture) ?? _defaultAutoCapture;
      _faceDetectionSensitivity =
          prefs.getDouble(_keyFaceDetectionSensitivity) ?? _defaultSensitivity;
      _cameraResolution =
          prefs.getString(_keyCameraResolution) ?? _defaultResolution;
      _debugMode = prefs.getBool(_keyDebugMode) ?? _defaultDebugMode;

      debugPrint('Settings loaded: TabletID=$_tabletId, ServerURL=$_serverUrl');
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Establecer Tablet ID
  Future<void> setTabletId(String id) async {
    if (id.isEmpty) return;

    _tabletId = id;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTabletId, id);
  }

  /// Establecer URL del servidor
  Future<void> setServerUrl(String url) async {
    if (url.isEmpty) return;

    // Validar formato de URL
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      debugPrint('Invalid URL format');
      return;
    }

    _serverUrl = url;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyServerUrl, url);
  }

  /// Establecer auto-captura
  Future<void> setAutoCapture(bool enabled) async {
    _autoCapture = enabled;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoCapture, enabled);
  }

  /// Establecer sensibilidad de detección facial (0-100)
  Future<void> setFaceDetectionSensitivity(double sensitivity) async {
    if (sensitivity < 0 || sensitivity > 100) return;

    _faceDetectionSensitivity = sensitivity;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyFaceDetectionSensitivity, sensitivity);
  }

  /// Establecer resolución de cámara
  Future<void> setCameraResolution(String resolution) async {
    if (!['low', 'medium', 'high', 'veryHigh'].contains(resolution)) return;

    _cameraResolution = resolution;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCameraResolution, resolution);
  }

  /// Establecer modo debug
  Future<void> setDebugMode(bool enabled) async {
    _debugMode = enabled;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDebugMode, enabled);
  }

  /// Restablecer a valores por defecto
  Future<void> resetToDefaults() async {
    _tabletId = _defaultTabletId;
    _serverUrl = _defaultServerUrl;
    _autoCapture = _defaultAutoCapture;
    _faceDetectionSensitivity = _defaultSensitivity;
    _cameraResolution = _defaultResolution;
    _debugMode = _defaultDebugMode;

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Limpiar caché de la aplicación
  Future<void> clearCache() async {
    // Aquí se implementaría la limpieza de caché de imágenes, etc.
    debugPrint('Cache cleared');
  }

  /// Exportar configuración como Map
  Map<String, dynamic> exportSettings() {
    return {
      'tabletId': _tabletId,
      'serverUrl': _serverUrl,
      'autoCapture': _autoCapture,
      'faceDetectionSensitivity': _faceDetectionSensitivity,
      'cameraResolution': _cameraResolution,
      'debugMode': _debugMode,
    };
  }

  /// Importar configuración desde Map
  Future<void> importSettings(Map<String, dynamic> settings) async {
    if (settings.containsKey('tabletId')) {
      await setTabletId(settings['tabletId']);
    }
    if (settings.containsKey('serverUrl')) {
      await setServerUrl(settings['serverUrl']);
    }
    if (settings.containsKey('autoCapture')) {
      await setAutoCapture(settings['autoCapture']);
    }
    if (settings.containsKey('faceDetectionSensitivity')) {
      await setFaceDetectionSensitivity(settings['faceDetectionSensitivity']);
    }
    if (settings.containsKey('cameraResolution')) {
      await setCameraResolution(settings['cameraResolution']);
    }
    if (settings.containsKey('debugMode')) {
      await setDebugMode(settings['debugMode']);
    }
  }
}
