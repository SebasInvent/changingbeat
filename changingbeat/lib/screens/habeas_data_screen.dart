import 'package:flutter/material.dart';
import 'dart:async';
import '../config/theme.dart';
import '../services/tts_service.dart';
import '../services/logger_service.dart';
import '../services/tablet_service.dart';
import 'document_scan_screen.dart';

/// Pantalla de Habeas Data con asistencia de operador
class HabeasDataScreen extends StatefulWidget {
  const HabeasDataScreen({super.key});

  @override
  State<HabeasDataScreen> createState() => _HabeasDataScreenState();
}

class _HabeasDataScreenState extends State<HabeasDataScreen> with SingleTickerProviderStateMixin {
  final TTSService _tts = TTSService();
  final TabletService _tabletService = TabletService();
  
  bool _waitingForOperator = true;
  bool _operatorPresent = false;
  bool _habeasDataAccepted = false;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  Timer? _notificationTimer;
  
  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)
    );
    
    _initializeScreen();
  }
  
  Future<void> _initializeScreen() async {
    // Inicializar TTS
    await _tts.initialize();
    
    // Mensaje de bienvenida
    await Future.delayed(const Duration(milliseconds: 500));
    await _tts.speak(TTSMessages.waitForOperator);
    
    // Notificar al operador
    _notifyOperator();
    
    // Repetir notificación cada 30 segundos
    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_waitingForOperator) {
        _notifyOperator();
        _tts.speak(TTSMessages.operatorWillExplain);
      }
    });
  }
  
  void _notifyOperator() {
    // Enviar evento al backend para notificar al operador
    _tabletService.reportEvent(
      'INFO',
      'Usuario esperando explicación de Habeas Data',
      data: {'timestamp': DateTime.now().toIso8601String()}
    );
    
    LoggerService.info('📢 Notificación enviada al operador');
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _notificationTimer?.cancel();
    _tts.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habeas Data'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: _waitingForOperator
                    ? _buildWaitingView()
                    : _operatorPresent
                        ? _buildOperatorView()
                        : _buildAcceptedView(),
              ),
              
              // Botones de operador (solo visible para operador)
              if (_waitingForOperator || _operatorPresent)
                _buildOperatorControls(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildWaitingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icono pulsante
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                size: 80,
                color: AppTheme.accentColor,
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          const Text(
            'Por favor espere',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            'Un asesor le explicará sobre\nHabeas Data y el tratamiento\nde sus datos personales',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 48),
          
          const CircularProgressIndicator(),
        ],
      ),
    );
  }
  
  Widget _buildOperatorView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          const Text(
            'Ley de Habeas Data',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Información de Habeas Data
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoSection(
                    Icons.gavel,
                    'Ley 1581 de 2012',
                    'Protección de datos personales en Colombia',
                  ),
                  
                  const Divider(height: 32),
                  
                  _buildInfoSection(
                    Icons.fingerprint,
                    'Datos Biométricos',
                    'Capturaremos su fotografía, huella dactilar e imagen de su documento de identidad',
                  ),
                  
                  const Divider(height: 32),
                  
                  _buildInfoSection(
                    Icons.security,
                    'Uso de Datos',
                    'Sus datos serán usados únicamente para verificación de identidad y control de acceso',
                  ),
                  
                  const Divider(height: 32),
                  
                  _buildInfoSection(
                    Icons.verified_user,
                    'Validación',
                    'Validaremos su información con la Registraduría Nacional de Colombia',
                  ),
                  
                  const Divider(height: 32),
                  
                  _buildInfoSection(
                    Icons.account_balance,
                    'Sus Derechos',
                    'Puede conocer, actualizar, rectificar y suprimir sus datos en cualquier momento',
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Nota para el operador
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accentColor),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.accentColor),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Operador: Explique estos puntos al usuario y confirme su aceptación',
                    style: TextStyle(
                      color: AppTheme.accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAcceptedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 80,
              color: AppTheme.accentColor,
            ),
          ),
          
          const SizedBox(height: 32),
          
          const Text(
            '¡Gracias!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            'Ha aceptado el tratamiento\nde datos personales',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          const Text(
            'Continuando con el registro...',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoSection(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildOperatorControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.admin_panel_settings, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text(
                'Panel de Operador',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          if (_waitingForOperator)
            ElevatedButton.icon(
              onPressed: _operatorArrived,
              icon: const Icon(Icons.person_add),
              label: const Text('Operador Presente'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          
          if (_operatorPresent) ...[
            ElevatedButton.icon(
              onPressed: _acceptHabeasData,
              icon: const Icon(Icons.check_circle),
              label: const Text('Usuario Acepta Habeas Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            OutlinedButton.icon(
              onPressed: _rejectHabeasData,
              icon: const Icon(Icons.cancel),
              label: const Text('Usuario Rechaza'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  void _operatorArrived() {
    setState(() {
      _waitingForOperator = false;
      _operatorPresent = true;
    });
    
    _notificationTimer?.cancel();
    _pulseController.stop();
    
    _tabletService.reportEvent(
      'INFO',
      'Operador presente para explicar Habeas Data'
    );
    
    LoggerService.info('👤 Operador presente');
  }
  
  void _acceptHabeasData() async {
    setState(() {
      _operatorPresent = false;
      _habeasDataAccepted = true;
    });
    
    // Registrar aceptación
    _tabletService.reportEvent(
      'REGISTRATION',
      'Usuario acepta Habeas Data',
      data: {
        'accepted': true,
        'timestamp': DateTime.now().toIso8601String(),
        'operator': 'present'
      }
    );
    
    LoggerService.info('✅ Habeas Data aceptado');
    
    // Mensaje de confirmación
    await _tts.speak(TTSMessages.habeasDataAccepted);
    
    // Esperar 2 segundos y continuar
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DocumentScanScreen()),
      );
    }
  }
  
  void _rejectHabeasData() {
    // Registrar rechazo
    _tabletService.reportEvent(
      'WARNING',
      'Usuario rechaza Habeas Data',
      data: {
        'accepted': false,
        'timestamp': DateTime.now().toIso8601String()
      }
    );
    
    LoggerService.warning('❌ Habeas Data rechazado');
    
    // Mostrar diálogo
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registro Cancelado'),
        content: const Text(
          'Sin la aceptación del tratamiento de datos personales no es posible continuar con el registro.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Volver al inicio
            },
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}
