import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../providers/biometric_capture_provider.dart';

/// Pantalla de escaneo de documento con cámara
class DocumentScanScreen extends StatefulWidget {
  const DocumentScanScreen({super.key});

  @override
  State<DocumentScanScreen> createState() => _DocumentScanScreenState();
}

class _DocumentScanScreenState extends State<DocumentScanScreen> {
  bool _isProcessing = false;
  File? _capturedImage;

  // Formulario para datos del documento
  final _formKey = GlobalKey<FormState>();
  final _documentNumberController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  String _documentType = 'CC';
  String _gender = 'M';
  DateTime? _birthDate;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final provider = context.read<BiometricCaptureProvider>();
    await provider.initializeCamera(useFrontCamera: false); // Cámara trasera
  }

  Future<void> _captureDocument() async {
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
              content: Text('Error al capturar documento'),
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

  Future<void> _showDataEntryDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Datos del Documento'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tipo de documento
                DropdownButtonFormField<String>(
                  value: _documentType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Documento',
                    prefixIcon: Icon(Icons.badge),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'CC', child: Text('Cédula de Ciudadanía')),
                    DropdownMenuItem(
                        value: 'CE', child: Text('Cédula de Extranjería')),
                    DropdownMenuItem(value: 'PA', child: Text('Pasaporte')),
                    DropdownMenuItem(
                        value: 'TI', child: Text('Tarjeta de Identidad')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _documentType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Número de documento
                TextFormField(
                  controller: _documentNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Número de Documento',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese el número de documento';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Nombres
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombres',
                    prefixIcon: Icon(Icons.person),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese los nombres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Apellidos
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Apellidos',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese los apellidos';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Fecha de nacimiento
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime(2000),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _birthDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha de Nacimiento',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _birthDate != null
                          ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
                          : 'Seleccione la fecha',
                      style: TextStyle(
                        color: _birthDate != null ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Género
                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: const InputDecoration(
                    labelText: 'Género',
                    prefixIcon: Icon(Icons.wc),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'M', child: Text('Masculino')),
                    DropdownMenuItem(value: 'F', child: Text('Femenino')),
                    DropdownMenuItem(value: 'O', child: Text('Otro')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _gender = value);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                if (_birthDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Seleccione la fecha de nacimiento'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                  return;
                }
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      _continueToFacialCapture();
    }
  }

  Future<void> _continueToFacialCapture() async {
    if (_capturedImage == null) return;

    final provider = context.read<BiometricCaptureProvider>();

    // Guardar imagen del documento
    provider.setDocumentImage(_capturedImage!);

    // Guardar datos del documento
    provider.setDocumentData(
      documentNumber: _documentNumberController.text,
      documentType: _documentType,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      birthDate: _birthDate!,
      gender: _gender,
      nationality: 'CO',
    );

    // Navegar a captura facial
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.facialCapture);
    }
  }

  @override
  void dispose() {
    _documentNumberController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    context.read<BiometricCaptureProvider>().disposeCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escaneo de Documento'),
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
                              ? 'Coloque el documento dentro del marco y capture'
                              : 'Revise la imagen del documento',
                          style: const TextStyle(color: AppTheme.primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),

                // Vista previa de la cámara o imagen capturada
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _capturedImage != null
                            ? AppTheme.accentColor
                            : AppTheme.primaryColor,
                        width: 3,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: _capturedImage != null
                          ? Image.file(
                              _capturedImage!,
                              fit: BoxFit.contain,
                            )
                          : provider.isCameraInitialized &&
                                  provider.cameraController != null
                              ? Stack(
                                  children: [
                                    CameraPreview(provider.cameraController!),
                                    // Guía visual para el documento
                                    Center(
                                      child: Container(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.7,
                                        height:
                                            MediaQuery.of(context).size.width *
                                                0.45,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.credit_card,
                                              size: 48,
                                              color:
                                                  Colors.white.withOpacity(0.7),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Alinee el documento aquí',
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.7),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : const Center(
                                  child: CircularProgressIndicator(),
                                ),
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
                                      : _captureDocument,
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
                                  : 'Capturar Documento'),
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
                                  _isProcessing ? null : _showDataEntryDialog,
                              icon: const Icon(Icons.edit_document),
                              label: const Text('Ingresar Datos'),
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
