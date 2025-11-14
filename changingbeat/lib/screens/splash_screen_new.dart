import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/theme.dart';
import '../services/logger_service.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    
    _animationController.forward();
    
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    try {
      LoggerService.info('🚀 Inicializando aplicación...');
      
      // Esperar animación
      await Future.delayed(const Duration(seconds: 2));
      
      // Solicitar permisos
      await _requestPermissions();
      
      // Navegar a pantalla de bienvenida
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );
      }
    } catch (e) {
      LoggerService.error('❌ Error inicializando app:', e);
    }
  }
  
  Future<void> _requestPermissions() async {
    LoggerService.info('🔐 Solicitando permisos...');
    
    final permissions = [
      Permission.camera,
      Permission.location,
      Permission.storage,
    ];
    
    for (var permission in permissions) {
      final status = await permission.request();
      if (status.isDenied) {
        LoggerService.warning('⚠️ Permiso denegado: $permission');
      }
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo o icono
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.fingerprint,
                  size: 80,
                  color: AppTheme.primaryColor,
                ),
              ),
              
              const SizedBox(height: 32),
              
              const Text(
                'Verificación Biométrica',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Sistema de Control de Acceso',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              
              const SizedBox(height: 48),
              
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
