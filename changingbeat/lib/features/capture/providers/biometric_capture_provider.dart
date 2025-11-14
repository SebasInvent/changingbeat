import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import '../../../data/services/api_service.dart';
import '../../../data/models/biometric_record_model.dart';

/// Provider para gestionar el proceso de captura biométrica
class BiometricCaptureProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Estado de la captura
  bool _isLoading = false;
  String? _errorMessage;

  // Datos capturados
  File? _documentImage;
  File? _faceImage;
  String? _documentNumber;
  String? _documentType;
  String? _firstName;
  String? _lastName;
  DateTime? _birthDate;
  String? _gender;
  String? _nationality;
  bool _livenessVerified = false;

  // Cámara
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  File? get documentImage => _documentImage;
  File? get faceImage => _faceImage;
  CameraController? get cameraController => _cameraController;
  bool get isCameraInitialized => _isCameraInitialized;
  bool get hasDocumentImage => _documentImage != null;
  bool get hasFaceImage => _faceImage != null;
  bool get livenessVerified => _livenessVerified;

  /// Inicializar cámara
  Future<void> initializeCamera({bool useFrontCamera = false}) async {
    try {
      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        _errorMessage = 'No se encontraron cámaras disponibles';
        notifyListeners();
        return;
      }

      // Seleccionar cámara (frontal para rostro, trasera para documentos)
      final camera = useFrontCamera
          ? _cameras!.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.front,
              orElse: () => _cameras!.first,
            )
          : _cameras!.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.back,
              orElse: () => _cameras!.first,
            );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      _isCameraInitialized = true;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al inicializar la cámara: $e';
      debugPrint('Camera initialization error: $e');
      notifyListeners();
    }
  }

  /// Capturar imagen
  Future<File?> captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _errorMessage = 'La cámara no está inicializada';
      notifyListeners();
      return null;
    }

    try {
      final image = await _cameraController!.takePicture();
      return File(image.path);
    } catch (e) {
      _errorMessage = 'Error al capturar imagen: $e';
      debugPrint('Image capture error: $e');
      notifyListeners();
      return null;
    }
  }

  /// Guardar imagen de documento
  void setDocumentImage(File image) {
    _documentImage = image;
    notifyListeners();
  }

  /// Guardar imagen facial
  void setFaceImage(File image) {
    _faceImage = image;
    notifyListeners();
  }

  /// Establecer si pasó liveness detection
  void setLivenessVerified(bool verified) {
    _livenessVerified = verified;
    notifyListeners();
  }

  /// Establecer datos del documento
  void setDocumentData({
    required String documentNumber,
    required String documentType,
    required String firstName,
    required String lastName,
    required DateTime birthDate,
    required String gender,
    String? nationality,
  }) {
    _documentNumber = documentNumber;
    _documentType = documentType;
    _firstName = firstName;
    _lastName = lastName;
    _birthDate = birthDate;
    _gender = gender;
    _nationality = nationality ?? 'CO';
    notifyListeners();
  }

  /// Registrar datos biométricos en la API
  Future<BiometricRecordModel?> registerBiometric({
    required String tabletId,
    required String operatorId,
  }) async {
    if (_documentImage == null || _faceImage == null) {
      _errorMessage = 'Faltan imágenes requeridas';
      notifyListeners();
      return null;
    }

    if (_documentNumber == null || _firstName == null || _lastName == null) {
      _errorMessage = 'Faltan datos del documento';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Convertir imágenes a Base64
      final documentBase64 = base64Encode(await _documentImage!.readAsBytes());
      final faceBase64 = base64Encode(await _faceImage!.readAsBytes());

      // Crear solicitud de registro
      final request = BiometricRegistrationRequest(
        documentNumber: _documentNumber!,
        documentType: _documentType ?? 'CC',
        firstName: _firstName!,
        lastName: _lastName!,
        birthDate: _birthDate ?? DateTime.now(),
        gender: _gender ?? 'M',
        nationality: _nationality ?? 'CO',
        photoBase64: faceBase64,
        faceEmbedding: faceBase64, // TODO: Implementar extracción de embeddings
        tabletId: tabletId,
        operatorId: operatorId,
        metadata: {
          'captureDate': DateTime.now().toIso8601String(),
          'documentImageSize': _documentImage!.lengthSync(),
          'faceImageSize': _faceImage!.lengthSync(),
          'livenessVerified': _livenessVerified,
        },
      );

      // Enviar a la API
      final response = await _apiService.registerBiometric(request);

      if (response.success && response.data != null) {
        _isLoading = false;
        notifyListeners();
        return response.data;
      } else {
        _errorMessage =
            response.error ?? 'Error al registrar datos biométricos';
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: $e';
      debugPrint('Biometric registration error: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Validar datos biométricos (solo facial)
  Future<BiometricValidationResponse?> validateBiometric({
    required String tabletId,
    String? documentNumber,
  }) async {
    if (_faceImage == null) {
      _errorMessage = 'Falta imagen facial';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Convertir imagen a Base64
      final faceBase64 = base64Encode(await _faceImage!.readAsBytes());

      // Crear solicitud de validación
      final request = BiometricValidationRequest(
        photoBase64: faceBase64,
        faceEmbedding: faceBase64, // TODO: Implementar extracción de embeddings
        documentNumber: documentNumber,
        tabletId: tabletId,
      );

      // Enviar a la API
      final response = await _apiService.validateBiometric(request);

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _errorMessage = 'Error inesperado: $e';
      debugPrint('Biometric validation error: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Limpiar datos de captura
  void reset() {
    _documentImage = null;
    _faceImage = null;
    _documentNumber = null;
    _documentType = null;
    _firstName = null;
    _lastName = null;
    _birthDate = null;
    _gender = null;
    _nationality = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Limpiar mensaje de error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Liberar recursos de la cámara
  Future<void> disposeCamera() async {
    await _cameraController?.dispose();
    _cameraController = null;
    _isCameraInitialized = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
}

/// Convertir bytes a Base64
String base64Encode(List<int> bytes) {
  return const Base64Encoder().convert(bytes);
}

/// Encoder Base64
class Base64Encoder {
  const Base64Encoder();

  String convert(List<int> input) {
    const String _base64Alphabet =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    final output = StringBuffer();
    int i = 0;

    while (i < input.length) {
      final int byte1 = input[i++];
      final int byte2 = i < input.length ? input[i++] : 0;
      final int byte3 = i < input.length ? input[i++] : 0;

      final int triple = (byte1 << 16) | (byte2 << 8) | byte3;

      output.write(_base64Alphabet[(triple >> 18) & 0x3F]);
      output.write(_base64Alphabet[(triple >> 12) & 0x3F]);
      output.write(
          i - 1 < input.length ? _base64Alphabet[(triple >> 6) & 0x3F] : '=');
      output.write(i < input.length ? _base64Alphabet[triple & 0x3F] : '=');
    }

    return output.toString();
  }
}
