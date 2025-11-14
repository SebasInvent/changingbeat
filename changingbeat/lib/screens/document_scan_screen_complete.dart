import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import '../config/theme.dart';
import '../services/advanced_camera_service.dart';
import '../services/document_detection_service.dart';
import '../services/tts_service.dart';
import '../services/logger_service.dart';
import 'facial_capture_screen_complete.dart';

/// Pantalla de escaneo de documento con detección en tiempo real
class DocumentScanScreenComplete extends StatefulWidget {
  final Map<String, dynamic>? registrationData;
  
  const DocumentScanScreenComplete({
    super.key,
    this.registrationData,
  });

  @override
  State<DocumentScanScreenComplete> createState() => _DocumentScanScreenCompleteState();
}

class _DocumentScanScreenCompleteState extends State<DocumentScanScreenComplete> {
  final AdvancedCameraService _cameraService = AdvancedCameraService();
  final DocumentDetectionService _documentService = DocumentDetectionService();
  final TTSService _tts = TTSService();
  
  bool _isInitialized = false;
  bool _isCapturing = false;
  bool _isFrontSide = true;
  
  String? _frontDocumentBase64;
  String? _backDocumentBase64;
  
  // Estado de detección
  bool _documentDetected = false;
  double _documentCoverage = 0.0;
  String _feedbackMessage = 'Posicione el documento dentro del marco';
  Color _feedbackColor = Colors.orange;
  
  Timer? _detectionTimer;
  
  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }
  
  Future<void> _initializeCamera() async {
    await _tts.initialize();
    
    final initialized = await _cameraService.initialize(useFrontCamera: false);
    
    if (initialized) {
      setState(() {
        _isInitialized = true;
      });
      
      // Iniciar detección en tiempo real
      _startRealtimeDetection();
      
      // Instrucción de voz
      await _tts.speak(_isFrontSide 
        ? TTSMessages.scanFront 
        : TTSMessages.scanBack
      );
    } else {
      _showError('No se pudo inicializar la cámara');
    }
  }
  
  void _startRealtimeDetection() {
    _detectionTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      if (!_isCapturing && _isInitialized) {
        await _detectDocument();
      }
    });
  }
  
  Future<void> _detectDocument() async {
    try {
      // Capturar frame actual (sin guardar)
      final result = await _cameraService.captureWithQualityCheck();
      
      if (result != null && result.success && result.imageBase64 != null) {
        // Detectar documento
        final detection = await _documentService.detectDocument(result.imageBase64!);
        
        setState(() {
          _documentDetected = detection.detected;
          _documentCoverage = detection.coverage ?? 0.0;
          
          if (detection.detected) {
            if (_documentCoverage < 0.3) {
              _feedbackMessage = 'Acérquese más';
              _feedbackColor = Colors.orange;
            } else if (_documentCoverage > 0.95) {
              _feedbackMessage = 'Aléjese un poco';
              _feedbackColor = Colors.orange;
            } else {
              _feedbackMessage = '¡Perfecto! Presione capturar';
              _feedbackColor = Colors.green;
            }
          } else {
            _feedbackMessage = detection.reason;
            _feedbackColor = Colors.red;
          }
        });
      }
    } catch (e) {
      LoggerService.error('Error en detección:', e);
    }
  }
  
  Future<void> _captureDocument() async {
    if (_isCapturing) return;
    
    setState(() {
      _isCapturing = true;
    });
    
    try {
      LoggerService.info('📸 Capturando ${_isFrontSide ? "frente" : "reverso"} del documento...');
      
      // Capturar imagen con validación de calidad
      final result = await _cameraService.captureWithQualityCheck();
      
      if (result == null || !result.success) {
        _showError(result?.reason ?? 'Error al capturar imagen');
        setState(() {
          _isCapturing = false;
        });
        return;
      }
      
      // Validar que hay un documento
      final detection = await _documentService.detectDocument(result.imageBase64!);
      
      if (!detection.detected) {
        _showError('No se detectó el documento. Intente nuevamente');
        setState(() {
          _isCapturing = false;
        });
        return;
      }
      
      // Extraer texto (OCR)
      final ocrResult = await _documentService.extractText(result.imageBase64!);
      
      if (_isFrontSide) {
        // Guardar frente
        _frontDocumentBase64 = result.imageBase64;
        
        await _tts.speak(TTSMessages.documentCaptured);
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Cambiar a reverso
        setState(() {
          _isFrontSide = false;
          _isCapturing = false;
          _feedbackMessage = 'Ahora capture el reverso';
        });
        
        await _tts.speak(TTSMessages.scanBack);
        
      } else {
        // Guardar reverso
        _backDocumentBase64 = result.imageBase64;
        
        await _tts.speak(TTSMessages.documentCaptured);
        
        // Continuar a captura facial
        _continueToFacialCapture();
      }
      
    } catch (e) {
      LoggerService.error('❌ Error capturando documento:', e);
      _showError('Error al procesar la imagen');
      setState(() {
        _isCapturing = false;
      });
    }
  }
  
  void _continueToFacialCapture() {
    _detectionTimer?.cancel();
    _cameraService.dispose();
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => FacialCaptureScreenComplete(
          registrationData: widget.registrationData,
          frontDocumentBase64: _frontDocumentBase64!,
          backDocumentBase64: _backDocumentBase64!,
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _detectionTimer?.cancel();
    _cameraService.dispose();
    _documentService.dispose();
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
        
        // Overlay oscuro con recorte
        Positioned.fill(
          child: CustomPaint(
            painter: DocumentOverlayPainter(
              detected: _documentDetected,
              coverage: _documentCoverage,
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
            child: Column(
              children: [
                Text(
                  _isFrontSide ? 'Frente de la Cédula' : 'Reverso de la Cédula',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isFrontSide ? '1 de 2' : '2 de 2',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
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
                    _documentDetected ? Icons.check_circle : Icons.info,
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
        if (_documentDetected)
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
                Text(
                  'Posicione el documento dentro del marco rectangular',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                // Botón de captura
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Botón de flash
                    IconButton(
                      onPressed: _cameraService.toggleFlash,
                      icon: const Icon(Icons.flash_on),
                      color: Colors.white,
                      iconSize: 32,
                    ),
                    
                    // Botón de captura principal
                    GestureDetector(
                      onTap: _isCapturing ? null : _captureDocument,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _documentDetected && !_isCapturing
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
                    
                    // Botón de ayuda
                    IconButton(
                      onPressed: _showHelp,
                      icon: const Icon(Icons.help_outline),
                      color: Colors.white,
                      iconSize: 32,
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
            Icons.check_circle,
            'Documento detectado',
            _documentDetected,
          ),
          const SizedBox(height: 8),
          _buildQualityItem(
            Icons.zoom_in,
            'Tamaño correcto',
            _documentCoverage >= 0.3 && _documentCoverage <= 0.95,
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
  
  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Consejos para Captura'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Coloque el documento sobre un fondo oscuro'),
            SizedBox(height: 8),
            Text('• Asegúrese de tener buena iluminación'),
            SizedBox(height: 8),
            Text('• Evite reflejos y sombras'),
            SizedBox(height: 8),
            Text('• Mantenga el dispositivo firme'),
            SizedBox(height: 8),
            Text('• El documento debe ocupar el 50-80% del marco'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
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

/// Painter para el overlay del documento
class DocumentOverlayPainter extends CustomPainter {
  final bool detected;
  final double coverage;
  
  DocumentOverlayPainter({
    required this.detected,
    required this.coverage,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Overlay oscuro
    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.5);
    
    // Rectángulo del documento (proporción de cédula colombiana: 85.6 x 53.98 mm ≈ 1.59:1)
    final double rectWidth = size.width * 0.85;
    final double rectHeight = rectWidth / 1.59;
    final double rectLeft = (size.width - rectWidth) / 2;
    final double rectTop = (size.height - rectHeight) / 2;
    
    final documentRect = Rect.fromLTWH(rectLeft, rectTop, rectWidth, rectHeight);
    
    // Dibujar overlay con recorte
    canvas.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addRRect(RRect.fromRectAndRadius(documentRect, const Radius.circular(12)))
        ..fillType = PathFillType.evenOdd,
      overlayPaint,
    );
    
    // Dibujar borde del rectángulo
    final borderPaint = Paint()
      ..color = detected ? Colors.green : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(documentRect, const Radius.circular(12)),
      borderPaint,
    );
    
    // Dibujar esquinas
    final cornerLength = 30.0;
    final cornerPaint = Paint()
      ..color = detected ? Colors.green : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    
    // Esquina superior izquierda
    canvas.drawLine(
      Offset(rectLeft, rectTop + cornerLength),
      Offset(rectLeft, rectTop),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rectLeft, rectTop),
      Offset(rectLeft + cornerLength, rectTop),
      cornerPaint,
    );
    
    // Esquina superior derecha
    canvas.drawLine(
      Offset(rectLeft + rectWidth - cornerLength, rectTop),
      Offset(rectLeft + rectWidth, rectTop),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rectLeft + rectWidth, rectTop),
      Offset(rectLeft + rectWidth, rectTop + cornerLength),
      cornerPaint,
    );
    
    // Esquina inferior izquierda
    canvas.drawLine(
      Offset(rectLeft, rectTop + rectHeight - cornerLength),
      Offset(rectLeft, rectTop + rectHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rectLeft, rectTop + rectHeight),
      Offset(rectLeft + cornerLength, rectTop + rectHeight),
      cornerPaint,
    );
    
    // Esquina inferior derecha
    canvas.drawLine(
      Offset(rectLeft + rectWidth, rectTop + rectHeight - cornerLength),
      Offset(rectLeft + rectWidth, rectTop + rectHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rectLeft + rectWidth - cornerLength, rectTop + rectHeight),
      Offset(rectLeft + rectWidth, rectTop + rectHeight),
      cornerPaint,
    );
  }
  
  @override
  bool shouldRepaint(DocumentOverlayPainter oldDelegate) {
    return detected != oldDelegate.detected || coverage != oldDelegate.coverage;
  }
}
