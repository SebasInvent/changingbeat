class AppConfig {
  // URL del backend
  static const String baseUrl = 'http://192.168.1.2:3000/api/v1';

  // Endpoints
  static const String biometricRegisterEndpoint = '/biometric/register';
  static const String biometricValidateEndpoint = '/biometric/validate';

  // Configuración de la app
  static const String appName = 'Verificación Biométrica';
  static const String appVersion = '1.0.0';

  // Términos y condiciones version
  static const String termsVersion = '1.0';

  // Configuración de cámara
  static const double imageQuality = 0.9;
  static const int maxImageSize = 1920; // pixels

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 60);
  static const Duration connectionTimeout = Duration(seconds: 30);

  // IDs de tablet (configurar por dispositivo)
  static String getTabletId() {
    // TODO: Implementar lógica para obtener ID único del dispositivo
    return 'TABLET_001';
  }
}
