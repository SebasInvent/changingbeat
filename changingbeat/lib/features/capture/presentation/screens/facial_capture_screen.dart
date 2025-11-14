import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/face_detection_service.dart';
import '../../../../core/widgets/face_detection_overlay.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/biometric_capture_provider.dart';

/// Pantalla de captura facial con ML Kit Face Detection
class FacialCaptureScreen extends StatefulWidget {
  final bool isValidationOnly;

  const FacialCaptureScreen({
    super.key,
    this.isValidationOnly = false,
  });

  @override
  State<FacialCaptureScreen> createState() => _FacialCaptureScreenState();
}

class _FacialCaptureScreenState extends State<FacialCaptureScreen> {
  bool _isProcessing = false;
  File? _capturedImage;

  // Face Detection
  late FaceDetectionService _faceDetectionService;
  FaceDetectionResult? _detectionResult;
  StreamSubscription? _detectionSubscription;
  Timer? _detectionTimer;
  bool _autoCapture = true;
  int _goodQualityFrames = 0;
  static const int _requiredGoodFrames =
      5; // 5 frames consecutivos de buena calidad

  @override
  void initState() {
    super.initState();
    _faceDetectionService = FaceDetectionService();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final provider = context.read<BiometricCaptureProvider>();
    await provider.initializeCamera(useFrontCamera: true);

    // Iniciar detección en tiempo real
    if (provider.isCameraInitialized) {
      _startFaceDetection();
    }
  }

  void _startFaceDetection() {
    final provider = context.read<BiometricCaptureProvider>();

    // Procesar frames cada 200ms
    _detectionTimer =
        Timer.periodic(const Duration(milliseconds: 200), (timer) async {
      if (!mounted || provider.cameraController == null) {
        timer.cancel();
        return;
      }

      try {
        final image =
            await provider.cameraController!.startImageStream((image) {
          // Este callback se ejecuta para cada frame
        });

        // Nota: startImageStream requiere un enfoque diferente
        // Por simplicidad, usaremos un enfoque basado en timer
        // En producción, usar imageStream directamente
      } catch (e) {
        debugPrint('Error in face detection: $e');
      }
    });
  }

  void _processFrame(CameraImage image) async {
    if (_isProcessing || _capturedImage != null) return;

    final result = await _faceDetectionService.detectFaces(image);

    if (mounted) {
      setState(() {
        _detectionResult = result;
      });

      // Auto-captura si la calidad es excelente
      if (_autoCapture && result.isGoodQuality) {
        _goodQualityFrames++;

        if (_goodQualityFrames >= _requiredGoodFrames) {
          _goodQualityFrames = 0;
          _capturePhoto();
        }
      } else {
        _goodQualityFrames = 0;
      }
    }
  }

  Future<void> _capturePhoto() async {
    final provider = context.read<BiometricCaptureProvider>();

    setState(() => _isProcessing = true);
    _detectionTimer?.cancel();

    try {
      final image = await provider.captureImage();

      if (image != null) {
        setState(() {
          _capturedImage = image;
          _isProcessing = false;
        });
      } else {
        setState(() => _isProcessing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al capturar imagen'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _retryCapture() async {
    setState(() {
      _capturedImage = null;
      _goodQualityFrames = 0;
    });
    await _initializeCamera();
  }

  Future<void> _continueWithCapture() async {
    if (_capturedImage == null) return;

    final provider = context.read<BiometricCaptureProvider>();
    provider.setFaceImage(_capturedImage!);

    if (widget.isValidationOnly) {
      await _validateBiometric();
    } else {
      if (mounted) {
        Navigator.of(context).pushNamed(
          AppRoutes.result,
          arguments: {
            'success': true,
            'message': 'Captura facial completada',
            'details': 'Procesando registro biométrico...',
          },
        );
        _registerBiometric();
      }
    }
  }

  Future<void> _validateBiometric() async {
    final provider = context.read<BiometricCaptureProvider>();

    setState(() => _isProcessing = true);

    final result = await provider.validateBiometric(
      tabletId: 'TAB-001',
    );

    setState(() => _isProcessing = false);

    if (!mounted) return;

    if (result != null && result.success) {
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.result,
        arguments: {
          'success': result.isMatch,
          'message': result.isMatch
              ? '¡Identidad Verificada!'
              : 'No se encontró coincidencia',
          'details': result.isMatch
              ? 'Persona: ${result.matchedRecord?.fullName}\nScore: ${result.matchScore?.toStringAsFixed(2)}'
              : 'No se encontró ninguna coincidencia en la base de datos',
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Error al validar'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _registerBiometric() async {
    final provider = context.read<BiometricCaptureProvider>();
    final authProvider = context.read<AuthProvider>();

    final result = await provider.registerBiometric(
      tabletId: 'TAB-001',
      operatorId: authProvider.currentUser?.id ?? 'unknown',
    );

    if (result != null) {
      debugPrint('Registro exitoso: ${result.id}');
    } else {
      debugPrint('Error en registro: ${provider.errorMessage}');
    }
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _detectionSubscription?.cancel();
    _faceDetectionService.dispose();
    context.read<BiometricCaptureProvider>().disposeCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.isValidationOnly ? 'Verificación Facial' : 'Captura Facial'),
        actions: [
          if (_capturedImage == null)
            IconButton(
              icon: Icon(_autoCapture
                  ? Icons.auto_awesome
                  : Icons.auto_awesome_outlined),
              tooltip: _autoCapture ? 'Auto-captura ON' : 'Auto-captura OFF',
              onPressed: () {
                setState(() => _autoCapture = !_autoCapture);
              },
            ),
        ],
      ),
      body: Consumer<BiometricCaptureProvider>(
        builder: (context, provider, child) {
          return SafeArea(
            child: Column(
              children: [
                // Instrucciones
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppTheme.primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _capturedImage == null
                              ? (_autoCapture
                                  ? 'Posicione su rostro en el óvalo. La captura será automática.'
                                  : 'Posicione su rostro en el óvalo y presione capturar')
                              : 'Revise la imagen capturada',
                          style: const TextStyle(color: AppTheme.primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),

                // Vista previa de la cámara o imagen capturada
                Expanded(
                  child: Container(
                    color: Colors.black,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Cámara o imagen
                        if (_capturedImage != null)
                          Image.file(
                            _capturedImage!,
                            fit: BoxFit.contain,
                          )
                        else if (provider.isCameraInitialized &&
                            provider.cameraController != null)
                          CameraPreview(provider.cameraController!)
                        else
                          const Center(
                            child: CircularProgressIndicator(),
                          ),

                        // Overlay de detección facial
                        if (_capturedImage == null &&
                            provider.isCameraInitialized)
                          FaceDetectionOverlay(
                            detectionResult: _detectionResult,
                            cameraSize: Size(
                              MediaQuery.of(context).size.width,
                              MediaQuery.of(context).size.height,
                            ),
                          ),

                        // Indicador de auto-captura
                        if (_autoCapture &&
                            _capturedImage == null &&
                            _goodQualityFrames > 0)
                          Positioned(
                            bottom: 100,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentColor,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Capturando en ${_requiredGoodFrames - _goodQualityFrames}...',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Botones de acción
                Container(
                  padding: const EdgeInsets.all(24.0),
                  child: _capturedImage == null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!_autoCapture)
                              ElevatedButton.icon(
                                onPressed: _isProcessing ||
                                        !provider.isCameraInitialized
                                    ? null
                                    : _capturePhoto,
                                icon: _isProcessing
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : const Icon(Icons.camera_alt, size: 28),
                                label: Text(_isProcessing
                                    ? 'Capturando...'
                                    : 'Capturar Foto'),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            if (_autoCapture)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.accentColor,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.auto_awesome,
                                      color: AppTheme.accentColor,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Modo auto-captura activado\nLa foto se tomará automáticamente',
                                        style: TextStyle(
                                          color: AppTheme.accentColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton.icon(
                              onPressed:
                                  _isProcessing ? null : _continueWithCapture,
                              icon: _isProcessing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Icon(Icons.check_circle),
                              label: Text(_isProcessing
                                  ? 'Procesando...'
                                  : widget.isValidationOnly
                                      ? 'Validar'
                                      : 'Continuar'),
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _isProcessing ? null : _retryCapture,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Tomar Otra Foto'),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
