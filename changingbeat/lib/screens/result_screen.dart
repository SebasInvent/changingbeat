import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'splash_screen.dart';

class ResultScreen extends StatelessWidget {
  final bool success;
  final dynamic data;
  final String? message;
  
  const ResultScreen({
    super.key,
    required this.success,
    this.data,
    this.message,
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
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: (success ? AppTheme.accentColor : AppTheme.errorColor)
                      .withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  success ? Icons.check_circle : Icons.error,
                  size: 80,
                  color: success ? AppTheme.accentColor : AppTheme.errorColor,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Título
              Text(
                success ? '¡Registro Exitoso!' : 'Error en Registro',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: success ? AppTheme.accentColor : AppTheme.errorColor,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Mensaje
              Text(
                message ?? (success
                    ? 'Su identidad ha sido verificada correctamente con la Registraduría Nacional'
                    : 'No se pudo completar la verificación'),
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              
              if (success && data != null) ...[
                const SizedBox(height: 32),
                _buildResultCard(),
              ],
              
              const Spacer(),
              
              // Botón
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const SplashScreen()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: success ? AppTheme.accentColor : AppTheme.primaryColor,
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: Text(success ? 'Registrar Nuevo Usuario' : 'Intentar Nuevamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildResultCard() {
    final registrationData = data['data'] ?? {};
    final status = registrationData['status'] ?? 'UNKNOWN';
    final isValidated = registrationData['isValidated'] ?? false;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInfoRow(
              Icons.verified_user,
              'Estado',
              status,
              isValidated ? AppTheme.accentColor : AppTheme.warningColor,
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.document_scanner,
              'Validación Registraduría',
              registrationData['documentValidation']?['isValid'] == true
                  ? 'Exitosa'
                  : 'Fallida',
              registrationData['documentValidation']?['isValid'] == true
                  ? AppTheme.accentColor
                  : AppTheme.errorColor,
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.face,
              'Validación Facial',
              registrationData['facialValidation']?['isValid'] == true
                  ? 'Exitosa'
                  : 'Fallida',
              registrationData['facialValidation']?['isValid'] == true
                  ? AppTheme.accentColor
                  : AppTheme.errorColor,
            ),
            if (registrationData['facialValidation']?['matchScore'] != null) ...[
              const Divider(height: 24),
              _buildInfoRow(
                Icons.percent,
                'Score de Coincidencia',
                '${registrationData['facialValidation']['matchScore']}%',
                AppTheme.primaryColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}