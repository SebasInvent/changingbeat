import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/face_detection_service.dart';
import '../../../../core/services/liveness_detection_service.dart';
import '../../../../core/widgets/face_detection_overlay.dart';
import '../../../../core/widgets/liveness_challenge_overlay.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../settings/providers/settings_provider.dart';
import '../../providers/biometric_capture_provider.dart';

/// Pantalla de captura facial con ML Kit Face Detection y Liveness
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
  Timer? _detectionTimer;
  bool _autoCapture = true;
  int _goodQualityFrames = 0;
  static const int _requiredGoodFrames = 5;

  // Liveness Detection
  LivenessDetectionService? _livenessService;
  LivenessChallenge? _currentChallenge;
  LivenessChallengeStatus _challengeStatus = LivenessChallengeStatus.waiting;
  bool _livenessCompleted = false;
  bool _showLivenessResult = false;
  bool _livenessEnabled = false;

  @override
  void initState() {
    super.initState();
    _faceDetectionService = FaceDetectionService();

    // Verificar si liveness está habilitado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsProvider>();
      _livenessEnabled = settings.livenessDetection;

      if (_livenessEnabled) {
        _livenessService = LivenessDetectionService();
        _currentChallenge = _livenessService!.startNewChallenge();
        setState(() {});
      }
    });

    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final provider = context.read<BiometricCaptureProvider>();
    await provider.initializeCamera(useFrontCamera: true);

    if (provider.isCameraInitialized) {
      _startFaceDetection();
    }
  }

  void _startFaceDetection() {
    _detectionTimer =
        Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      // El procesamiento real se haría con camera image stream
      // Por ahora, el timer está listo para cuando se implemente
    });
  }

  void _processFrame(dynamic face) {
    if (_isProcessing || _capturedImage != null) return;

    // Procesar detección facial
    // final result = await _faceDetectionService.detectFaces(image);
    // setState(() => _detectionResult = result);

    // Si liveness está habilitado y no completado
    if (_livenessEnabled &&
        !_livenessCompleted &&
        _currentChallenge != null &&
        face != null) {
      final status = _livenessService!.processFrame(face);
      setState(() => _challengeStatus = status);

      if (status == LivenessChallengeStatus.passed) {
        if (_livenessService!.hasPassedAllChallenges) {
          // Completó todos los challenges
          setState(() {
            _livenessCompleted = true;
            _showLivenessResult = true;
          });

          // Guardar que pasó liveness
          final provider = context.read<BiometricCaptureProvider>();
          provider.setLivenessVerified(true);
        } else {
          // Siguiente challenge
          setState(() {
            _currentChallenge = _livenessService!.startNewChallenge();
            _challengeStatus = LivenessChallengeStatus.processing;
          });
        }
      } else if (status == LivenessChallengeStatus.failed) {
        // Challenge fallido
        setState(() {
          _showLivenessResult = true;
        });
      }
    }

    // Auto-captura (solo si liveness completado o deshabilitado)
    if (_autoCapture && (!_livenessEnabled || _livenessCompleted)) {
      // Lógica de auto-captura basada en calidad
      if (_detectionResult?.isGoodQuality ?? false) {
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

  void _retryLiveness() {
    _livenessService?.reset();
    setState(() {
      _currentChallenge = _livenessService?.startNewChallenge();
      _livenessCompleted = false;
      _showLivenessResult = false;
      _challengeStatus = LivenessChallengeStatus.waiting;
    });
  }

  void _continueLiveness() {
    setState(() {
      _showLivenessResult = false;
    });
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
      tabletId: context.read<SettingsProvider>().tabletId,
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
    final settings = context.read<SettingsProvider>();

    final result = await provider.registerBiometric(
      tabletId: settings.tabletId,
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
          if (_capturedImage == null &&
              (!_livenessEnabled || _livenessCompleted))
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
            child: Stack(
              children: [
                Column(
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
                              _getInstructionText(),
                              style:
                                  const TextStyle(color: AppTheme.primaryColor),
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

                            // Overlay de detección facial (solo si no hay liveness o ya completó)
                            if (_capturedImage == null &&
                                provider.isCameraInitialized &&
                                (!_livenessEnabled || _livenessCompleted))
                              FaceDetectionOverlay(
                                detectionResult: _detectionResult,
                                cameraSize: Size(
                                  MediaQuery.of(context).size.width,
                                  MediaQuery.of(context).size.height,
                                ),
                              ),

                            // Overlay de liveness challenge
                            if (_livenessEnabled &&
                                !_livenessCompleted &&
                                _currentChallenge != null &&
                                _capturedImage == null)
                              LivenessChallengeOverlay(
                                challenge: _currentChallenge,
                                status: _challengeStatus,
                                progress:
                                    _livenessService?.challengeProgress ?? 0.0,
                              ),

                            // Indicador de auto-captura
                            if (_autoCapture &&
                                _capturedImage == null &&
                                _goodQualityFrames > 0 &&
                                (!_livenessEnabled || _livenessCompleted))
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
                      child: _buildActionButtons(provider),
                    ),
                  ],
                ),

                // Resultado de liveness
                if (_showLivenessResult)
                  LivenessResultOverlay(
                    passed: _livenessService?.hasPassedAllChallenges ?? false,
                    onContinue: _continueLiveness,
                    onRetry: _retryLiveness,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getInstructionText() {
    if (_capturedImage != null) {
      return 'Revise la imagen capturada';
    }

    if (_livenessEnabled && !_livenessCompleted) {
      return 'Complete las pruebas de vivacidad';
    }

    if (_autoCapture) {
      return 'Posicione su rostro en el óvalo. La captura será automática.';
    }

    return 'Posicione su rostro en el óvalo y presione capturar';
  }

  Widget _buildActionButtons(BiometricCaptureProvider provider) {
    if (_capturedImage == null) {
      // Botones durante captura
      if (_livenessEnabled && !_livenessCompleted) {
        // Durante liveness, no mostrar botones
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_autoCapture)
            ElevatedButton.icon(
              onPressed: _isProcessing || !provider.isCameraInitialized
                  ? null
                  : _capturePhoto,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    )
                  : const Icon(Icons.camera_alt, size: 28),
              label: Text(_isProcessing ? 'Capturando...' : 'Capturar Foto'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
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
                      _livenessCompleted
                          ? 'Liveness completado. Auto-captura activada'
                          : 'Modo auto-captura activado\nLa foto se tomará automáticamente',
                      style: const TextStyle(
                        color: AppTheme.accentColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    } else {
      // Botones después de captura
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _continueWithCapture,
            icon: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
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
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _isProcessing ? null : _retryCapture,
            icon: const Icon(Icons.refresh),
            label: const Text('Tomar Otra Foto'),
          ),
        ],
      );
    }
  }
}
