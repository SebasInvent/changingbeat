import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/biometric_capture_provider.dart';

/// Pantalla de captura facial con cámara
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

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final provider = context.read<BiometricCaptureProvider>();
    await provider.initializeCamera(useFrontCamera: true);
  }

  Future<void> _capturePhoto() async {
    final provider = context.read<BiometricCaptureProvider>();

    setState(() => _isProcessing = true);

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
    setState(() => _capturedImage = null);
    await _initializeCamera();
  }

  Future<void> _continueWithCapture() async {
    if (_capturedImage == null) return;

    final provider = context.read<BiometricCaptureProvider>();
    provider.setFaceImage(_capturedImage!);

    if (widget.isValidationOnly) {
      // Validar biométrico
      await _validateBiometric();
    } else {
      // Continuar a confirmación para registro completo
      if (mounted) {
        Navigator.of(context).pushNamed(
          AppRoutes.result,
          arguments: {
            'success': true,
            'message': 'Captura facial completada',
            'details': 'Procesando registro biométrico...',
          },
        );

        // Registrar en background
        _registerBiometric();
      }
    }
  }

  Future<void> _validateBiometric() async {
    final provider = context.read<BiometricCaptureProvider>();
    final authProvider = context.read<AuthProvider>();

    setState(() => _isProcessing = true);

    final result = await provider.validateBiometric(
      tabletId: 'TAB-001', // TODO: Obtener de configuración
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
      tabletId: 'TAB-001', // TODO: Obtener de configuración
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
    context.read<BiometricCaptureProvider>().disposeCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.isValidationOnly ? 'Verificación Facial' : 'Captura Facial'),
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
                              ? 'Posicione su rostro en el centro del marco'
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
                    child: _capturedImage != null
                        ? Image.file(
                            _capturedImage!,
                            fit: BoxFit.contain,
                          )
                        : provider.isCameraInitialized &&
                                provider.cameraController != null
                            ? CameraPreview(provider.cameraController!)
                            : const Center(
                                child: CircularProgressIndicator(),
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
                            ElevatedButton.icon(
                              onPressed:
                                  _isProcessing || !provider.isCameraInitialized
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
