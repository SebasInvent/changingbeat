import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../config/theme.dart';
import '../services/camera_service.dart';
import '../services/logger_service.dart';
import 'confirmation_screen.dart';

class FacialCaptureScreen extends StatefulWidget {
  final String frontDocumentBase64;
  final String backDocumentBase64;
  
  const FacialCaptureScreen({
    super.key,
    required this.frontDocumentBase64,
    required this.backDocumentBase64,
  });

  @override
  State<FacialCaptureScreen> createState() => _FacialCaptureScreenState();
}

class _FacialCaptureScreenState extends State<FacialCaptureScreen> {
  final CameraService _cameraService = CameraService();
  bool _isInitialized = false;
  bool _isCapturing = false;
  int _countdown = 0;
  
  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }
  
  Future<void> _initializeCamera() async {
    final success = await _cameraService.initialize();
    if (success && mounted) {
      setState(() {
        _isInitialized = true;
      });
    } else {
      _showError('No se pudo inicializar la cámara');
    }
  }
  
  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Captura Facial'),
      ),
      body: SafeArea(
        child: _isInitialized ? _buildCameraView() : _buildLoading(),
      ),
    );
  }
  
  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Inicializando cámara frontal...'),
        ],
      ),
    );
  }
  
  Widget _buildCameraView() {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              // Preview de cámara
              if (_cameraService.controller != null)
                Center(
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CameraPreview(_cameraService.controller!),
                    ),
                  ),
                ),
              
              // Overlay facial
              _buildFaceOverlay(),
              
              // Instrucciones
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: _buildInstructions(),
              ),
              
              // Countdown
              if (_countdown > 0)
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$_countdown',
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // Botones de control
        _buildControls(),
      ],
    );
  }
  
  Widget _buildFaceOverlay() {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppTheme.accentColor,
            width: 4,
          ),
        ),
      ),
    );
  }
  
  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.face,
            color: Colors.white,
            size: 32,
          ),
          SizedBox(height: 8),
          Text(
            'Centre su rostro en el círculo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            'Mire directamente a la cámara con expresión neutral',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Consejos
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.warningColor),
            ),
            child: const Row(
              children: [
                Icon(Icons.lightbulb_outline, color: AppTheme.warningColor),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Asegúrese de tener buena iluminación y retire gafas/gorras',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Botón de captura
          Center(
            child: FloatingActionButton.large(
              onPressed: _isCapturing ? null : _startCountdownCapture,
              backgroundColor: AppTheme.accentColor,
              child: _isCapturing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Icon(Icons.camera_alt, size: 32),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _startCountdownCapture() async {
    // Countdown de 3 segundos
    for (int i = 3; i > 0; i--) {
      setState(() {
        _countdown = i;
      });
      await Future.delayed(const Duration(seconds: 1));
    }
    
    setState(() {
      _countdown = 0;
    });
    
    await _captureSelfie();
  }
  
  Future<void> _captureSelfie() async {
    if (_isCapturing) return;
    
    setState(() {
      _isCapturing = true;
    });
    
    try {
      final base64Image = await _cameraService.captureAndEncodeImage();
      
      if (base64Image == null) {
        _showError('Error al capturar selfie');
        return;
      }
      
      LoggerService.info('✅ Selfie capturado');
      
      // Navegar a confirmación
      _continueToConfirmation(base64Image);
      
    } catch (e) {
      _showError('Error al procesar imagen');
      LoggerService.error('Error capturando selfie:', e);
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }
  
  void _continueToConfirmation(String selfieBase64) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ConfirmationScreen(
          frontDocumentBase64: widget.frontDocumentBase64,
          backDocumentBase64: widget.backDocumentBase64,
          selfieBase64: selfieBase64,
        ),
      ),
    );
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