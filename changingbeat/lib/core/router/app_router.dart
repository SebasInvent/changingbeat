import 'package:flutter/material.dart';

/// Rutas de la aplicación
class AppRoutes {
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String capture = '/capture';
  static const String documentScan = '/document-scan';
  static const String facialCapture = '/facial-capture';
  static const String confirmation = '/confirmation';
  static const String result = '/result';
  static const String settings = '/settings';
  static const String records = '/records';
}

/// Router centralizado de la aplicación
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        // TODO: Importar desde features/onboarding
        return MaterialPageRoute(
          builder: (_) => const Placeholder(), // SplashScreen
          settings: settings,
        );

      case AppRoutes.welcome:
        // TODO: Importar desde features/onboarding
        return MaterialPageRoute(
          builder: (_) => const Placeholder(), // WelcomeScreen
          settings: settings,
        );

      case AppRoutes.login:
        // TODO: Importar desde features/auth
        return MaterialPageRoute(
          builder: (_) => const Placeholder(), // LoginScreen
          settings: settings,
        );

      case AppRoutes.dashboard:
        // TODO: Importar desde features/dashboard
        return MaterialPageRoute(
          builder: (_) => const Placeholder(), // DashboardScreen
          settings: settings,
        );

      case AppRoutes.capture:
        // TODO: Importar desde features/capture
        return MaterialPageRoute(
          builder: (_) => const Placeholder(), // CaptureScreen
          settings: settings,
        );

      case AppRoutes.documentScan:
        // TODO: Importar desde features/capture
        return MaterialPageRoute(
          builder: (_) => const Placeholder(), // DocumentScanScreen
          settings: settings,
        );

      case AppRoutes.facialCapture:
        // TODO: Importar desde features/capture
        return MaterialPageRoute(
          builder: (_) => const Placeholder(), // FacialCaptureScreen
          settings: settings,
        );

      case AppRoutes.confirmation:
        // TODO: Importar desde features/capture
        return MaterialPageRoute(
          builder: (_) => const Placeholder(), // ConfirmationScreen
          settings: settings,
        );

      case AppRoutes.result:
        // TODO: Importar desde features/capture
        return MaterialPageRoute(
          builder: (_) => const Placeholder(), // ResultScreen
          settings: settings,
        );

      case AppRoutes.settings:
        // TODO: Importar desde features/settings
        return MaterialPageRoute(
          builder: (_) => const Placeholder(), // SettingsScreen
          settings: settings,
        );

      case AppRoutes.records:
        // TODO: Importar desde features/records
        return MaterialPageRoute(
          builder: (_) => const Placeholder(), // RecordsScreen
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Ruta no encontrada: ${settings.name}')),
          ),
        );
    }
  }
}
