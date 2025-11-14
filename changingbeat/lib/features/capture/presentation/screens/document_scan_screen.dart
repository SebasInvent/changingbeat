import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';

/// Pantalla de escaneo de documento
class DocumentScanScreen extends StatefulWidget {
  const DocumentScanScreen({super.key});

  @override
  State<DocumentScanScreen> createState() => _DocumentScanScreenState();
}

class _DocumentScanScreenState extends State<DocumentScanScreen> {
  bool _isScanning = false;
  bool _documentCaptured = false;

  Future<void> _startScan() async {
    setState(() => _isScanning = true);

    try {
      // TODO: Implementar captura de documento con cámara
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isScanning = false;
        _documentCaptured = true;
      });
    } catch (e) {
      setState(() => _isScanning = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al capturar documento: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _continueToFacialCapture() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.facialCapture);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escaneo de Documento'),
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
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Coloque el documento de identidad dentro del marco',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
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
                      color: _documentCaptured
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
              if (!_documentCaptured)
                ElevatedButton.icon(
                  onPressed: _isScanning ? null : _startScan,
                  icon: _isScanning
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
                  label: Text(
                      _isScanning ? 'Escaneando...' : 'Capturar Documento'),
                )
              else
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _continueToFacialCapture,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Continuar a Captura Facial'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() => _documentCaptured = false);
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
    if (_isScanning) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Procesando documento...'),
        ],
      );
    }

    if (_documentCaptured) {
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
            'Documento capturado correctamente',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.document_scanner,
          size: 80,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(height: 16),
        Text(
          'Presione el botón para capturar',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
