import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';

/// Pantalla de captura facial
class FacialCaptureScreen extends StatefulWidget {
  const FacialCaptureScreen({super.key});

  @override
  State<FacialCaptureScreen> createState() => _FacialCaptureScreenState();
}

class _FacialCaptureScreenState extends State<FacialCaptureScreen> {
  bool _isCapturing = false;
  bool _faceCaptured = false;
  int _captureCount = 0;
  final int _requiredCaptures = 3;

  Future<void> _captureFace() async {
    setState(() => _isCapturing = true);

    try {
      // TODO: Implementar captura facial con cámara y ML Kit
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isCapturing = false;
        _captureCount++;
        if (_captureCount >= _requiredCaptures) {
          _faceCaptured = true;
        }
      });
    } catch (e) {
      setState(() => _isCapturing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al capturar rostro: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _continueToConfirmation() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.confirmation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Captura Facial'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Instrucciones
              Card(
                color: AppTheme.primaryColor.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Mire directamente a la cámara',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      if (!_faceCaptured) ...[
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: _captureCount / _requiredCaptures,
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.accentColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Capturas: $_captureCount/$_requiredCaptures',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Área de captura
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _faceCaptured
                          ? AppTheme.accentColor
                          : AppTheme.primaryColor,
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: _buildCaptureContent(),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Botones de acción
              if (!_faceCaptured)
                ElevatedButton.icon(
                  onPressed: _isCapturing ? null : _captureFace,
                  icon: _isCapturing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.camera_alt),
                  label:
                      Text(_isCapturing ? 'Capturando...' : 'Capturar Rostro'),
                )
              else
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _continueToConfirmation,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Continuar a Confirmación'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _faceCaptured = false;
                          _captureCount = 0;
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Capturar Nuevamente'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureContent() {
    if (_isCapturing) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Analizando rostro...'),
        ],
      );
    }

    if (_faceCaptured) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            size: 80,
            color: AppTheme.accentColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Captura facial completada',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Todas las capturas realizadas correctamente',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.face,
          size: 80,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(height: 16),
        Text(
          _captureCount == 0
              ? 'Presione el botón para iniciar'
              : 'Captura $_captureCount de $_requiredCaptures completada',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
