import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Servicio para detección facial en tiempo real con ML Kit
class FaceDetectionService {
  late FaceDetector _faceDetector;
  bool _isProcessing = false;

  FaceDetectionService() {
    _initializeDetector();
  }

  void _initializeDetector() {
    final options = FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      enableLandmarks: true,
      enableTracking: true,
      minFaceSize: 0.15,
      performanceMode: FaceDetectorMode.accurate,
    );
    _faceDetector = FaceDetector(options: options);
  }

  /// Detectar rostros en una imagen de cámara
  Future<FaceDetectionResult> detectFaces(CameraImage image) async {
    if (_isProcessing) {
      return FaceDetectionResult.processing();
    }

    _isProcessing = true;

    try {
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) {
        _isProcessing = false;
        return FaceDetectionResult.error('Error al procesar imagen');
      }

      final faces = await _faceDetector.processImage(inputImage);
      _isProcessing = false;

      return _analyzeFaces(faces);
    } catch (e) {
      _isProcessing = false;
      debugPrint('Error in face detection: $e');
      return FaceDetectionResult.error('Error: $e');
    }
  }

  /// Convertir CameraImage a InputImage para ML Kit
  InputImage? _convertCameraImage(CameraImage image) {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final imageSize = Size(
        image.width.toDouble(),
        image.height.toDouble(),
      );

      const imageRotation = InputImageRotation.rotation0deg;

      final inputImageFormat = InputImageFormat.nv21;

      final planeData = image.planes.map((Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      }).toList();

      final inputImageData = InputImageData(
        size: imageSize,
        imageRotation: imageRotation,
        inputImageFormat: inputImageFormat,
        planeData: planeData,
      );

      return InputImage.fromBytes(
        bytes: bytes,
        inputImageData: inputImageData,
      );
    } catch (e) {
      debugPrint('Error converting camera image: $e');
      return null;
    }
  }

  /// Analizar rostros detectados y generar feedback
  FaceDetectionResult _analyzeFaces(List<Face> faces) {
    if (faces.isEmpty) {
      return FaceDetectionResult.noFace();
    }

    if (faces.length > 1) {
      return FaceDetectionResult.multipleFaces();
    }

    final face = faces.first;
    final quality = _analyzeFaceQuality(face);

    return FaceDetectionResult.success(
      face: face,
      quality: quality,
    );
  }

  /// Analizar calidad del rostro detectado
  FaceQuality _analyzeFaceQuality(Face face) {
    final issues = <String>[];
    var score = 100.0;

    // Verificar tamaño del rostro
    final faceSize = face.boundingBox.width * face.boundingBox.height;
    if (faceSize < 10000) {
      issues.add('Acércate más a la cámara');
      score -= 30;
    } else if (faceSize > 100000) {
      issues.add('Aléjate un poco de la cámara');
      score -= 20;
    }

    // Verificar ángulo de cabeza (head pose)
    if (face.headEulerAngleY != null) {
      final yaw = face.headEulerAngleY!.abs();
      if (yaw > 15) {
        issues.add('Mira de frente a la cámara');
        score -= 25;
      }
    }

    if (face.headEulerAngleZ != null) {
      final roll = face.headEulerAngleZ!.abs();
      if (roll > 15) {
        issues.add('Mantén la cabeza recta');
        score -= 20;
      }
    }

    // Verificar ojos abiertos
    if (face.leftEyeOpenProbability != null &&
        face.rightEyeOpenProbability != null) {
      final leftEye = face.leftEyeOpenProbability!;
      final rightEye = face.rightEyeOpenProbability!;

      if (leftEye < 0.5 || rightEye < 0.5) {
        issues.add('Mantén los ojos abiertos');
        score -= 30;
      }
    }

    // Verificar sonrisa (opcional, para liveness)
    if (face.smilingProbability != null) {
      final smiling = face.smilingProbability!;
      // No penalizamos por sonreír, solo lo detectamos
    }

    // Determinar nivel de calidad
    FaceQualityLevel level;
    if (score >= 80) {
      level = FaceQualityLevel.excellent;
    } else if (score >= 60) {
      level = FaceQualityLevel.good;
    } else if (score >= 40) {
      level = FaceQualityLevel.fair;
    } else {
      level = FaceQualityLevel.poor;
    }

    return FaceQuality(
      score: score,
      level: level,
      issues: issues,
      faceSize: faceSize,
      headYaw: face.headEulerAngleY,
      headRoll: face.headEulerAngleZ,
      leftEyeOpen: face.leftEyeOpenProbability,
      rightEyeOpen: face.rightEyeOpenProbability,
      smiling: face.smilingProbability,
    );
  }

  /// Liberar recursos
  void dispose() {
    _faceDetector.close();
  }
}

/// Resultado de la detección facial
class FaceDetectionResult {
  final FaceDetectionStatus status;
  final Face? face;
  final FaceQuality? quality;
  final String? errorMessage;

  FaceDetectionResult._({
    required this.status,
    this.face,
    this.quality,
    this.errorMessage,
  });

  factory FaceDetectionResult.success({
    required Face face,
    required FaceQuality quality,
  }) {
    return FaceDetectionResult._(
      status: FaceDetectionStatus.faceDetected,
      face: face,
      quality: quality,
    );
  }

  factory FaceDetectionResult.noFace() {
    return FaceDetectionResult._(
      status: FaceDetectionStatus.noFaceDetected,
    );
  }

  factory FaceDetectionResult.multipleFaces() {
    return FaceDetectionResult._(
      status: FaceDetectionStatus.multipleFaces,
    );
  }

  factory FaceDetectionResult.processing() {
    return FaceDetectionResult._(
      status: FaceDetectionStatus.processing,
    );
  }

  factory FaceDetectionResult.error(String message) {
    return FaceDetectionResult._(
      status: FaceDetectionStatus.error,
      errorMessage: message,
    );
  }

  bool get isGoodQuality =>
      quality != null &&
      (quality!.level == FaceQualityLevel.excellent ||
          quality!.level == FaceQualityLevel.good);

  String get feedbackMessage {
    switch (status) {
      case FaceDetectionStatus.noFaceDetected:
        return 'No se detecta ningún rostro';
      case FaceDetectionStatus.multipleFaces:
        return 'Se detectan múltiples rostros';
      case FaceDetectionStatus.faceDetected:
        if (quality != null && quality!.issues.isNotEmpty) {
          return quality!.issues.first;
        }
        return 'Rostro detectado correctamente';
      case FaceDetectionStatus.processing:
        return 'Procesando...';
      case FaceDetectionStatus.error:
        return errorMessage ?? 'Error desconocido';
    }
  }
}

/// Estado de la detección
enum FaceDetectionStatus {
  noFaceDetected,
  faceDetected,
  multipleFaces,
  processing,
  error,
}

/// Calidad del rostro detectado
class FaceQuality {
  final double score; // 0-100
  final FaceQualityLevel level;
  final List<String> issues;
  final double faceSize;
  final double? headYaw;
  final double? headRoll;
  final double? leftEyeOpen;
  final double? rightEyeOpen;
  final double? smiling;

  FaceQuality({
    required this.score,
    required this.level,
    required this.issues,
    required this.faceSize,
    this.headYaw,
    this.headRoll,
    this.leftEyeOpen,
    this.rightEyeOpen,
    this.smiling,
  });

  bool get isAcceptable =>
      level == FaceQualityLevel.excellent ||
      level == FaceQualityLevel.good ||
      level == FaceQualityLevel.fair;
}

/// Nivel de calidad
enum FaceQualityLevel {
  excellent, // 80-100
  good, // 60-79
  fair, // 40-59
  poor, // 0-39
}
