import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import '../config/app_config.dart';
import '../config/theme.dart';
import '../models/biometric_registration.dart';
import '../services/api_service.dart';
import '../services/logger_service.dart';
import 'result_screen.dart';

class ConfirmationScreen extends StatefulWidget {
  final String frontDocumentBase64;
  final String backDocumentBase64;
  final String selfieBase64;
  
  const ConfirmationScreen({
    super.key,
    required this.frontDocumentBase64,
    required this.backDocumentBase64,
    required this.selfieBase64,
  });

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  final TextEditingController _documentNumberController = TextEditingController();
  final TextEditingController _expeditionDateController = TextEditingController();
  
  String _selectedDocumentType = 'CC';
  bool _isProcessing = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar Datos'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Resumen
              _buildSummaryCard(),
              
              const SizedBox(height: 24),
              
              // Formulario
              _buildForm(),
              
              const SizedBox(height: 24),
              
              // Botones
              _buildButtons(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppTheme.accentColor,
            ),
            const SizedBox(height: 16),
            const Text(
              '¡Imágenes Capturadas!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Por favor confirme los datos de su documento',
              style: TextStyle(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageIndicator(Icons.credit_card, 'Frente'),
                _buildImageIndicator(Icons.credit_card_off, 'Reverso'),
                _buildImageIndicator(Icons.face, 'Selfie'),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildImageIndicator(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.accentColor),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
  
  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Datos del Documento',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Tipo de documento
        DropdownButtonFormField<String>(
          value: _selectedDocumentType,
          decoration: const InputDecoration(
            labelText: 'Tipo de Documento',
            prefixIcon: Icon(Icons.assignment),
          ),
          items: const [
            DropdownMenuItem(value: 'CC', child: Text('Cédula de Ciudadanía')),
            DropdownMenuItem(value: 'TI', child: Text('Tarjeta de Identidad')),
            DropdownMenuItem(value: 'CE', child: Text('Cédula de Extranjería')),
            DropdownMenuItem(value: 'PEP', child: Text('PEP')),
            DropdownMenuItem(value: 'PPT', child: Text('PPT')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedDocumentType = value!;
            });
          },
        ),
        
        const SizedBox(height: 16),
        
        // Número de documento
        TextField(
          controller: _documentNumberController,
          decoration: const InputDecoration(
            labelText: 'Número de Documento',
            prefixIcon: Icon(Icons.badge),
            hintText: 'Ej: 1234567890',
          ),
          keyboardType: TextInputType.number,
        ),
        
        const SizedBox(height: 16),
        
        // Fecha de expedición
        TextField(
          controller: _expeditionDateController,
          decoration: const InputDecoration(
            labelText: 'Fecha de Expedición',
            prefixIcon: Icon(Icons.calendar_today),
            hintText: 'AAAA-MM-DD',
          ),
          keyboardType: TextInputType.datetime,
          onTap: () => _selectDate(),
        ),
      ],
    );
  }
  
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      _expeditionDateController.text = picked.toString().split(' ')[0];
    }
  }
  
  Widget _buildButtons() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _isProcessing ? null : _submitRegistration,
          child: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Confirmar y Enviar'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          child: const Text('Volver a Capturar'),
        ),
      ],
    );
  }
  
  Future<void> _submitRegistration() async {
    // Validar campos
    if (_documentNumberController.text.isEmpty ||
        _expeditionDateController.text.isEmpty) {
      _showError('Por favor complete todos los campos');
      return;
    }
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      // Obtener información del dispositivo
      final deviceInfo = await _getDeviceInfo();
      final location = await _getLocation();
      
      // Crear objeto de registro
      final registration = BiometricRegistration(
        documentNumber: _documentNumberController.text,
        documentType: _selectedDocumentType,
        expeditionDate: DateTime.parse(_expeditionDateController.text),
        selfieBase64: widget.selfieBase64,
        frontDocumentBase64: widget.frontDocumentBase64,
        backDocumentBase64: widget.backDocumentBase64,
        termsAccepted: true,
        emotion: 'neutral',
        deviceInfo: deviceInfo,
        tabletInfo: TabletInfoModel(
          tabletId: AppConfig.getTabletId(),
          location: location,
        ),
      );
      
      // Enviar al servidor
      final apiService = ApiService();
      final result = await apiService.registerBiometric(registration);
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              success: result['success'],
              data: result['data'],
              message: result['message'],
            ),
          ),
        );
      }
      
    } catch (e) {
      LoggerService.error('Error en registro:', e);
      _showError('Error al procesar el registro: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
  
  Future<DeviceInfoModel> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();
      
      if (Theme.of(context).platform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        return DeviceInfoModel(
          deviceId: androidInfo.id,
          deviceModel: '${androidInfo.manufacturer} ${androidInfo.model}',
          osVersion: 'Android ${androidInfo.version.release}',
          appVersion: packageInfo.version,
        );
      } else {
        return DeviceInfoModel(
          deviceId: 'unknown',
          deviceModel: 'Unknown Device',
          osVersion: 'Unknown OS',
          appVersion: packageInfo.version,
        );
      }
    } catch (e) {
      LoggerService.error('Error obteniendo device info:', e);
      return DeviceInfoModel(
        deviceId: 'error',
        deviceModel: 'error',
        osVersion: 'error',
        appVersion: '1.0.0',
      );
    }
  }
  
  Future<LocationModel?> _getLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      return LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      LoggerService.warning('No se pudo obtener ubicación:', e);
      return null;
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