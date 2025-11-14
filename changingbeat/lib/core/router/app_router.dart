import 'package:flutter/material.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/onboarding/presentation/screens/welcome_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/capture/presentation/screens/capture_screen.dart';
import '../../features/capture/presentation/screens/document_scan_screen.dart';
import '../../features/capture/presentation/screens/facial_capture_screen.dart';
import '../../features/capture/presentation/screens/result_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/records/presentation/screens/records_screen.dart';

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
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );

      case AppRoutes.welcome:
        return MaterialPageRoute(
          builder: (_) => const WelcomeScreen(),
          settings: settings,
        );

      case AppRoutes.login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );

      case AppRoutes.dashboard:
        return MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
          settings: settings,
        );

      case AppRoutes.capture:
        return MaterialPageRoute(
          builder: (_) => const CaptureScreen(),
          settings: settings,
        );

      case AppRoutes.documentScan:
        return MaterialPageRoute(
          builder: (_) => const DocumentScanScreen(),
          settings: settings,
        );

      case AppRoutes.facialCapture:
        return MaterialPageRoute(
          builder: (_) => const FacialCaptureScreen(),
          settings: settings,
        );

      case AppRoutes.confirmation:
        // TODO: Implementar ConfirmationScreen
        return MaterialPageRoute(
          builder: (_) => const ResultScreen(
            success: true,
            message: 'Registro completado',
          ),
          settings: settings,
        );

      case AppRoutes.result:
        return MaterialPageRoute(
          builder: (_) => const ResultScreen(
            success: true,
            message: 'Operación completada',
          ),
          settings: settings,
        );

      case AppRoutes.settings:
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
          settings: settings,
        );

      case AppRoutes.records:
        return MaterialPageRoute(
          builder: (_) => const RecordsScreen(),
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
