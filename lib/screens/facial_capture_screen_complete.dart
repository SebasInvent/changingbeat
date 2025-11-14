import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'dart:math' as math;
import '../config/theme.dart';
import '../services/advanced_camera_service.dart';
import '../services/face_detection_service.dart';
import '../services/tts_service.dart';
import '../services/logger_service.dart';
import 'confirmation_screen.dart';

/// Pantalla de captura facial con detección en tiempo real
class FacialCaptureScreenComplete extends StatefulWidget {
  final Map<String, dynamic>? registrationData;
  final String frontDocumentBase64;
  final String backDocumentBase64;
  
  const FacialCaptureScreenComplete({
    super.key,
    this.registrationData,
    required this.frontDocumentBase64,
    required this.backDocumentBase64,
  });

  @override
  State<FacialCaptureScreenComplete> createState() => _FacialCaptureScreenCompleteState();
}

class _FacialCaptureScreenCompleteState extends State<FacialCaptureScreenComplete> with SingleTickerProviderStateMixin {
  final AdvancedCameraService _cameraService = AdvancedCameraService();
  final FaceDetectionService _faceService = FaceDetectionService();
  final TTSService _tts = TTSService();
  
  bool _isInitialized = false;
  bool _isCapturing = false;
  bool _isCountingDown = false;
  int _countdown = 3;
  
  String? _selfieBase64;
  
  // Estado de detección
  bool _faceDetected = false;
  bool _faceQualityOk = false;
  double _livenessScore = 0.0;
  String _feedbackMessage = 'Posicione su rostro dentro del círculo';
  Color _feedbackColor = Colors.orange;
  
  Timer? _detectionTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
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
    
    _initializeCamera();
  }
  
  Future<void> _initializeCamera() async {
    await _tts.initialize();
    
    final initialized = await _cameraService.initialize(useFrontCamera: true);
    
    if (initialized) {
      setState(() {
        _isInitialized = true;
      });
      
      // Iniciar detección en tiempo real
      _startRealtimeDetection();
      
      // Instrucción de voz
      await _tts.speak(TTSMessages.lookAtCamera);
    } else {
      _showError('No se pudo inicializar la cámara');
    }
  }
  
  void _startRealtimeDetection() {
    _detectionTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      if (!_isCapturing && !_isCountingDown && _isInitialized) {
        await _detectFace();
      }
    });
  }
  
  Future<void> _detectFace() async {
    try {
      // Capturar frame actual
      final result = await _cameraService.captureWithQualityCheck();
      
      if (result != null && result.success && result.imageBase64 != null) {
        // Detectar rostro
        final detection = await _faceService.detectFace(result.imageBase64!);
        
        setState(() {
          _faceDetected = detection.detected;
          _faceQualityOk = detection.detected && (detection.qualityScore ?? 0) >= 60;
          _livenessScore = detection.livenessScore ?? 0.0;
          
          if (detection.detected) {
            if (_faceQualityOk) {
              _feedbackMessage = '¡Perfecto! Manténgase así';
              _feedbackColor = Colors.green;
              
              // Auto-captura después de 2 segundos si todo está OK
              if (!_isCountingDown) {
                _startCountdown();
              }
            } else {
              _feedbackMessage = detection.reason;
              _feedbackColor = Colors.orange;
            }
          } else {
            _feedbackMessage = detection.reason;
            _feedbackColor = Colors.red;
          }
        });
      }
    } catch (e) {
      LoggerService.error('Error en detección facial:', e);
    }
  }
  
  Future<void> _startCountdown() async {
    if (_isCountingDown) return;
    
    setState(() {
      _isCountingDown = true;
      _countdown = 3;
    });
    
    await _tts.speak(TTSMessages.holdStill);
    
    for (int i = 3; i > 0; i--) {
      if (!mounted || !_faceQualityOk) {
        setState(() {
          _isCountingDown = false;
        });
        return;
      }
      
      setState(() {
        _countdown = i;
      });
      
      // Voz del countdown
      if (i == 3) await _tts.speak(TTSMessages.countdown3);
      if (i == 2) await _tts.speak(TTSMessages.countdown2);
      if (i == 1) await _tts.speak(TTSMessages.countdown1);
      
      await Future.delayed(const Duration(seconds: 1));
    }
    
    // Capturar
    await _captureFace();
  }
  
  Future<void> _captureFace() async {
    if (_isCapturing) return;
    
    setState(() {
      _isCapturing = true;
      _isCountingDown = false;
    });
    
    try {
      LoggerService.info('📸 Capturando selfie...');
      
      // Capturar imagen con validación de calidad
      final result = await _cameraService.captureWithQualityCheck();
      
      if (result == null || !result.success) {
        _showError(result?.reason ?? 'Error al capturar imagen');
        setState(() {
          _isCapturing = false;
        });
        return;
      }
      
      // Validar que hay un rostro
      final detection = await _faceService.detectFace(result.imageBase64!);
      
      if (!detection.detected) {
        _showError('No se detectó el rostro. Intente nuevamente');
        setState(() {
          _isCapturing = false;
        });
        return;
      }
      
      // Validar liveness
      if ((detection.livenessScore ?? 0) < 0.6) {
        _showError('No se pudo verificar que sea una persona real');
        setState(() {
          _isCapturing = false;
        });
        return;
      }
      
      // Guardar selfie
      _selfieBase64 = result.imageBase64;
      
      await _tts.speak(TTSMessages.faceCaptured);
      
      // Continuar a confirmación
      _continueToConfirmation();
      
    } catch (e) {
      LoggerService.error('❌ Error capturando selfie:', e);
      _showError('Error al procesar la imagen');
      setState(() {
        _isCapturing = false;
      });
    }
  }
  
  void _continueToConfirmation() {
    _detectionTimer?.cancel();
    _cameraService.dispose();
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ConfirmationScreen(
          frontDocumentBase64: widget.frontDocumentBase64,
          backDocumentBase64: widget.backDocumentBase64,
          selfieBase64: _selfieBase64!,
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _detectionTimer?.cancel();
    _pulseController.dispose();
    _cameraService.dispose();
    _faceService.dispose();
    _tts.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isInitialized
            ? _buildCameraView()
            : _buildLoadingView(),
      ),
    );
  }
  
  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Inicializando cámara...',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCameraView() {
    return Stack(
      children: [
        // Camera Preview
        Positioned.fill(
          child: CameraPreview(_cameraService.controller!),
        ),
        
        // Overlay oscuro con recorte circular
        Positioned.fill(
          child: CustomPaint(
            painter: FaceOverlayPainter(
              detected: _faceDetected,
              qualityOk: _faceQualityOk,
              livenessScore: _livenessScore,
            ),
          ),
        ),
        
        // Countdown overlay
        if (_isCountingDown)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.accentColor.withOpacity(0.9),
                    ),
                    child: Center(
                      child: Text(
                        '$_countdown',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 80,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        
        // Header
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
            ),
            child: const Column(
              children: [
                Text(
                  'Captura Facial',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Mire directamente a la cámara',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Feedback message
        Positioned(
          top: 120,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: _feedbackColor.withOpacity(0.9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _faceQualityOk ? Icons.check_circle : Icons.info,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _feedbackMessage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Indicadores de calidad
        if (_faceDetected)
          Positioned(
            top: 180,
            left: 20,
            child: _buildQualityIndicator(),
          ),
        
        // Botones inferiores
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              children: [
                // Instrucciones
                const Text(
                  'Centre su rostro en el círculo y mantenga una expresión neutral',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                // Botón de captura manual (opcional)
                if (!_isCountingDown)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _faceQualityOk && !_isCapturing ? _startCountdown : null,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _faceQualityOk && !_isCapturing
                                ? AppTheme.accentColor
                                : Colors.grey,
                            border: Border.all(
                              color: Colors.white,
                              width: 4,
                            ),
                          ),
                          child: _isCapturing
                              ? const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 40,
                                ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildQualityIndicator() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQualityItem(
            Icons.face,
            'Rostro detectado',
            _faceDetected,
          ),
          const SizedBox(height: 8),
          _buildQualityItem(
            Icons.verified_user,
            'Liveness OK',
            _livenessScore >= 0.6,
          ),
          const SizedBox(height: 8),
          _buildQualityItem(
            Icons.high_quality,
            'Calidad OK',
            _faceQualityOk,
          ),
        ],
      ),
    );
  }
  
  Widget _buildQualityItem(IconData icon, String label, bool isOk) {
    return Row(
      children: [
        Icon(
          icon,
          color: isOk ? Colors.green : Colors.grey,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: isOk ? Colors.white : Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

/// Painter para el overlay facial
class FaceOverlayPainter extends CustomPainter {
  final bool detected;
  final bool qualityOk;
  final double livenessScore;
  
  FaceOverlayPainter({
    required this.detected,
    required this.qualityOk,
    required this.livenessScore,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Overlay oscuro
    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.5);
    
    // Círculo para el rostro
    final double circleRadius = size.width * 0.35;
    final Offset circleCenter = Offset(size.width / 2, size.height / 2);
    
    // Dibujar overlay con recorte circular
    canvas.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addOval(Rect.fromCircle(center: circleCenter, radius: circleRadius))
        ..fillType = PathFillType.evenOdd,
      overlayPaint,
    );
    
    // Dibujar borde del círculo
    final borderPaint = Paint()
      ..color = qualityOk ? Colors.green : (detected ? Colors.orange : Colors.white)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    
    canvas.drawCircle(circleCenter, circleRadius, borderPaint);
    
    // Dibujar indicador de liveness (arco)
    if (detected) {
      final livenessPaint = Paint()
        ..color = livenessScore >= 0.6 ? Colors.green : Colors.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;
      
      final sweepAngle = 2 * math.pi * livenessScore;
      
      canvas.drawArc(
        Rect.fromCircle(center: circleCenter, radius: circleRadius + 10),
        -math.pi / 2,
        sweepAngle,
        false,
        livenessPaint,
      );
    }
  }
  
  @override
  bool shouldRepaint(FaceOverlayPainter oldDelegate) {
    return detected != oldDelegate.detected || 
           qualityOk != oldDelegate.qualityOk ||
           livenessScore != oldDelegate.livenessScore;
  }
}
