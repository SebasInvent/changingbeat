import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';
import '../services/tts_service.dart';
import '../services/logger_service.dart';
import 'document_scan_screen.dart';

/// Pantalla de registro rápido con Habeas Data + Datos obligatorios
class QuickRegistrationScreen extends StatefulWidget {
  const QuickRegistrationScreen({super.key});

  @override
  State<QuickRegistrationScreen> createState() => _QuickRegistrationScreenState();
}

class _QuickRegistrationScreenState extends State<QuickRegistrationScreen> {
  final TTSService _tts = TTSService();
  final _formKey = GlobalKey<FormState>();
  
  // Controladores
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _epsController = TextEditingController();
  final TextEditingController _arlController = TextEditingController();
  
  bool _habeasDataAccepted = false;
  bool _isProcessing = false;
  
  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }
  
  Future<void> _initializeScreen() async {
    await _tts.initialize();
    await Future.delayed(const Duration(milliseconds: 300));
    await _tts.speak('Por favor ingrese sus datos');
  }
  
  @override
  void dispose() {
    _phoneController.dispose();
    _epsController.dispose();
    _arlController.dispose();
    _tts.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro Rápido'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Título
                const Text(
                  'Datos Obligatorios',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                const Text(
                  'Complete la información para continuar',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Habeas Data
                _buildHabeasDataCard(),
                
                const SizedBox(height: 24),
                
                // Formulario
                _buildForm(),
                
                const SizedBox(height: 32),
                
                // Botón continuar
                ElevatedButton(
                  onPressed: _isProcessing ? null : _continue,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: AppTheme.accentColor,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Continuar con Captura Biométrica',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildHabeasDataCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Protección de Datos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              'Vedas Data tratará sus datos personales y biométricos de acuerdo con la Ley 1581 de 2012 (Habeas Data) únicamente para verificación de identidad.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 16),
            
            CheckboxListTile(
              value: _habeasDataAccepted,
              onChanged: (value) {
                setState(() {
                  _habeasDataAccepted = value ?? false;
                });
              },
              title: const Text(
                'Acepto el tratamiento de mis datos personales',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppTheme.accentColor,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildForm() {
    return Column(
      children: [
        // Celular
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Celular *',
            hintText: '3001234567',
            prefixIcon: Icon(Icons.phone_android),
          ),
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'El celular es obligatorio';
            }
            if (value.length != 10) {
              return 'Debe tener 10 dígitos';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 20),
        
        // EPS
        TextFormField(
          controller: _epsController,
          decoration: const InputDecoration(
            labelText: 'EPS *',
            hintText: 'Ej: Sanitas, Sura, Nueva EPS',
            prefixIcon: Icon(Icons.local_hospital),
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'La EPS es obligatoria';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 20),
        
        // ARL
        TextFormField(
          controller: _arlController,
          decoration: const InputDecoration(
            labelText: 'ARL *',
            hintText: 'Ej: Sura, Positiva, Colmena',
            prefixIcon: Icon(Icons.work),
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'La ARL es obligatoria';
            }
            return null;
          },
        ),
      ],
    );
  }
  
  Future<void> _continue() async {
    // Validar Habeas Data
    if (!_habeasDataAccepted) {
      _showError('Debe aceptar el tratamiento de datos para continuar');
      return;
    }
    
    // Validar formulario
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      // Guardar datos (se enviarán junto con el registro biométrico)
      final registrationData = {
        'phone': _phoneController.text,
        'eps': _epsController.text,
        'arl': _arlController.text,
        'habeasDataAccepted': true,
        'habeasDataTimestamp': DateTime.now().toIso8601String(),
      };
      
      LoggerService.info('📝 Datos capturados: $registrationData');
      
      await _tts.speak('Datos registrados. Continuamos con la captura biométrica');
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        // Navegar a captura de documento, pasando los datos
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => DocumentScanScreen(
              registrationData: registrationData,
            ),
          ),
        );
      }
    } catch (e) {
      LoggerService.error('❌ Error:', e);
      _showError('Error al procesar datos');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }
}
