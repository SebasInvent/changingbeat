import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/logger_service.dart';
import 'document_scan_screen.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _acceptedTerms = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Términos y Condiciones'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Contenido de términos
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ícono
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.description,
                          size: 40,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Título
                    const Text(
                      'Términos y Condiciones de Uso',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    const Text(
                      'Versión 1.0 - Última actualización: Noviembre 2024',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Contenido de términos
                    _buildSection(
                      '1. Aceptación de Términos',
                      'Al utilizar este sistema de verificación biométrica, usted acepta los presentes términos y condiciones. Si no está de acuerdo, no debe utilizar este servicio.',
                    ),
                    
                    _buildSection(
                      '2. Recopilación de Datos Biométricos',
                      'Este sistema capturará y procesará:\n'
                      '• Fotografía de su rostro\n'
                      '• Imágenes de su cédula de identidad (frente y reverso)\n'
                      '• Datos personales contenidos en su documento\n'
                      '• Ubicación geográfica del registro',
                    ),
                    
                    _buildSection(
                      '3. Uso de la Información',
                      'Los datos recopilados serán utilizados exclusivamente para:\n'
                      '• Validación de identidad con la Registraduría Nacional\n'
                      '• Control de acceso a las instalaciones\n'
                      '• Cumplimiento de normativas legales',
                    ),
                    
                    _buildSection(
                      '4. Almacenamiento y Seguridad',
                      'Sus datos biométricos serán:\n'
                      '• Almacenados de forma segura y encriptada\n'
                      '• Conservados durante el período legal requerido\n'
                      '• Protegidos contra acceso no autorizado',
                    ),
                    
                    _buildSection(
                      '5. Derechos del Usuario',
                      'Usted tiene derecho a:\n'
                      '• Acceder a sus datos almacenados\n'
                      '• Solicitar corrección de información incorrecta\n'
                      '• Solicitar eliminación de sus datos\n'
                      '• Revocar su consentimiento en cualquier momento',
                    ),
                    
                    _buildSection(
                      '6. Compartir Información',
                      'Sus datos podrán ser compartidos con:\n'
                      '• Registraduría Nacional del Estado Civil (para validación)\n'
                      '• Autoridades competentes (cuando sea legalmente requerido)\n'
                      '• NO serán vendidos ni compartidos con terceros comerciales',
                    ),
                    
                    _buildSection(
                      '7. Consentimiento',
                      'Al aceptar estos términos, usted consiente explícitamente el tratamiento de sus datos biométricos según lo descrito.',
                    ),
                    
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            
            // Footer con checkbox y botones
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Checkbox de aceptación
                  InkWell(
                    onTap: () {
                      setState(() {
                        _acceptedTerms = !_acceptedTerms;
                      });
                    },
                    child: Row(
                      children: [
                        Checkbox(
                          value: _acceptedTerms,
                          onChanged: (value) {
                            setState(() {
                              _acceptedTerms = value ?? false;
                            });
                          },
                          activeColor: AppTheme.primaryColor,
                        ),
                        const Expanded(
                          child: Text(
                            'He leído y acepto los términos y condiciones de uso y el tratamiento de mis datos biométricos',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Botones
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // Salir de la app
                            Navigator.of(context).pop();
                          },
                          child: const Text('Rechazar'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _acceptedTerms ? _continueToRegistration : null,
                          child: const Text('Aceptar y Continuar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
  
  void _continueToRegistration() {
    LoggerService.info('✅ Términos aceptados');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DocumentScanScreen()),
    );
  }
}