/// Constantes globales de la aplicación
class AppConstants {
  // Información de la app
  static const String appName = 'Verificación Biométrica';
  static const String appVersion = '1.0.0';

  // API
  static const String apiBaseUrl = 'https://access-control.eukahack.com/api/v1';
  static const String apiBaseUrlLocal = 'http://192.168.1.2:3000/api/v1';

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 60);
  static const Duration connectionTimeout = Duration(seconds: 30);

  // Configuración de cámara
  static const double imageQuality = 0.9;
  static const int maxImageSize = 1920;

  // Términos y condiciones
  static const String termsVersion = '1.0';

  // Storage keys
  static const String keyTabletId = 'tablet_id';
  static const String keyUserToken = 'user_token';
  static const String keyTermsAccepted = 'terms_accepted';
  static const String keyLastSync = 'last_sync';

  // Endpoints
  static const String endpointHealth = '/health';
  static const String endpointLogin = '/auth/login';
  static const String endpointRegister = '/auth/register';
  static const String endpointBiometricRegister = '/biometric/register';
  static const String endpointBiometricValidate = '/biometric/validate';
  static const String endpointTablets = '/tablets';
  static const String endpointRecords = '/records';
}
