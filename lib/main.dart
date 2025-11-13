import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/app_config.dart';
import 'config/theme.dart';
import 'screens/splash_screen.dart';
import 'services/logger_service.dart';
import 'services/tablet_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurar orientación (solo portrait)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Inicializar logger
  LoggerService.init();
  
  // Inicializar y registrar tablet
  final tabletService = TabletService();
  await tabletService.initialize();
  
  runApp(const BiometricVerificationApp());
}

class BiometricVerificationApp extends StatelessWidget {
  const BiometricVerificationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Aquí puedes agregar providers si usas state management
      ],
      child: MaterialApp(
        title: 'Verificación Biométrica',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}