import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../router/app_router.dart';
import '../theme/app_theme.dart';

/// Widget que envuelve la app y maneja la navegación basada en el estado de autenticación
class AuthWrapper extends StatefulWidget {
  final Widget child;

  const AuthWrapper({
    super.key,
    required this.child,
  });

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _wasAuthenticated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final authProvider = Provider.of<AuthProvider>(context);

    // Detectar cuando el usuario pierde la autenticación (auto-logout)
    if (_wasAuthenticated && !authProvider.isAuthenticated) {
      _handleSessionExpired(authProvider.errorMessage);
    }

    _wasAuthenticated = authProvider.isAuthenticated;
  }

  void _handleSessionExpired(String? message) {
    // Mostrar mensaje de sesión expirada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Mostrar SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message ??
                'Su sesión ha expirado. Por favor, inicie sesión nuevamente.',
          ),
          backgroundColor: AppTheme.warningColor,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );

      // Navegar al login
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
