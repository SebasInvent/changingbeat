import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../data/services/api_service.dart';

/// Pantalla de splash con verificación de sesión y permisos
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  String _statusMessage = 'Iniciando...';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      // Paso 1: Verificar permisos de cámara
      await _checkPermissions();

      // Paso 2: Verificar conectividad con API
      await _checkApiConnection();

      // Paso 3: Verificar sesión guardada
      await _checkSession();

      // Paso 4: Navegar a la pantalla correspondiente
      await _navigateToNextScreen();
    } catch (e) {
      setState(() {
        _hasError = true;
        _statusMessage = 'Error al inicializar: $e';
      });

      // Esperar un momento y navegar al login
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    }
  }

  Future<void> _checkPermissions() async {
    setState(() => _statusMessage = 'Verificando permisos...');

    // Verificar permiso de cámara
    final cameraStatus = await Permission.camera.status;

    if (cameraStatus.isDenied) {
      // Solicitar permiso
      final result = await Permission.camera.request();
      if (result.isDenied || result.isPermanentlyDenied) {
        setState(() {
          _statusMessage = 'Permiso de cámara requerido';
          _hasError = true;
        });
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _checkApiConnection() async {
    setState(() => _statusMessage = 'Conectando con el servidor...');

    try {
      final apiService = ApiService();
      final response = await apiService.checkHealth();

      if (!response.success) {
        setState(() {
          _statusMessage = 'Servidor no disponible';
          _hasError = true;
        });
        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Sin conexión al servidor';
        _hasError = true;
      });
      await Future.delayed(const Duration(seconds: 1));
    }

    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _checkSession() async {
    setState(() => _statusMessage = 'Verificando sesión...');

    final authProvider = context.read<AuthProvider>();

    // El AuthProvider ya se inicializó en main.dart
    // Solo esperamos un momento para que complete
    await Future.delayed(const Duration(milliseconds: 800));
  }

  Future<void> _navigateToNextScreen() async {
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();

    // Esperar animación mínima
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      // Usuario tiene sesión válida, ir al dashboard
      setState(() => _statusMessage = 'Bienvenido de nuevo!');
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
      }
    } else {
      // No hay sesión, ir al login
      setState(() => _statusMessage = 'Iniciando sesión...');
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
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
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo animado
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
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
                      size: 100,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Título
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  'Control de Acceso',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  'Biométrico',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),

              const SizedBox(height: 60),

              // Indicador de carga
              if (!_hasError)
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                )
              else
                const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 40,
                ),

              const SizedBox(height: 20),

              // Mensaje de estado
              Text(
                _statusMessage,
                style: TextStyle(
                  color: _hasError ? Colors.white : Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 60),

              // Versión
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  'v2.0.0',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
