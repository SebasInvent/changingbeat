import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';

/// Pantalla de resultado de la captura
class ResultScreen extends StatelessWidget {
  final bool success;
  final String message;
  final String? details;

  const ResultScreen({
    super.key,
    required this.success,
    required this.message,
    this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icono de resultado
              Icon(
                success ? Icons.check_circle : Icons.error,
                size: 120,
                color: success ? AppTheme.accentColor : AppTheme.errorColor,
              ),

              const SizedBox(height: 32),

              // Mensaje principal
              Text(
                success ? '¡Éxito!' : 'Error',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color:
                          success ? AppTheme.accentColor : AppTheme.errorColor,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Mensaje descriptivo
              Text(
                message,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),

              if (details != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      details!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 48),

              // Botones de acción
              if (success)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.dashboard,
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Volver al Inicio'),
                )
              else
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Intentar Nuevamente'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          AppRoutes.dashboard,
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.home),
                      label: const Text('Volver al Inicio'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
