import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/widgets/auth_wrapper.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/dashboard/providers/dashboard_provider.dart';
import 'features/capture/providers/biometric_capture_provider.dart';
import 'features/records/providers/records_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar orientación (solo portrait)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const BiometricVerificationApp());
}

class BiometricVerificationApp extends StatelessWidget {
  const BiometricVerificationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => DashboardProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => BiometricCaptureProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => RecordsProvider(),
        ),
      ],
      child: AuthWrapper(
        child: MaterialApp(
          title: 'Verificación Biométrica',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          onGenerateRoute: AppRouter.generateRoute,
          initialRoute: AppRoutes.splash,
        ),
      ),
    );
  }
}
