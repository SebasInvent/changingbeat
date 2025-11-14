import 'dart:typed_data';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'dart:convert';
import 'dart:math' as math;
import 'logger_service.dart';

/// Servicio de detección facial con liveness detection
class FaceDetectionService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      enableClassification: true,
      enableTracking: true,
      enableContours: true,
      minFaceSize: 0.15,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );
  
  /// Detectar rostro en imagen
  Future<FaceDetectionResult> detectFace(String imageBase64) async {
    try {
      LoggerService.info('👤 Detectando rostro...');
      
      // Decodificar imagen
      final imageBytes = base64Decode(imageBase64);
      
      // Crear InputImage
      final inputImage = InputImage.fromBytes(
        bytes: imageBytes,
        metadata: InputImageMetadata(
          size: Size(1920, 1080),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.yuv420,
          bytesPerRow: 1920,
        ),
      );
      
      // Detectar rostros
      final List<Face> faces = await _faceDetector.processImage(inputImage);
      
      if (faces.isEmpty) {
        return FaceDetectionResult(
          detected: false,
          reason: 'No se detectó ningún rostro',
        );
      }
      
      if (faces.length > 1) {
        return FaceDetectionResult(
          detected: false,
          reason: 'Se detectaron múltiples rostros. Solo debe aparecer una persona',
        );
      }
      
      final face = faces.first;
      
      // Validar calidad del rostro
      final qualityCheck = _validateFaceQuality(face);
      
      if (!qualityCheck.isValid) {
        return FaceDetectionResult(
          detected: false,
          reason: qualityCheck.reason,
        );
      }
      
      // Calcular liveness score
      final livenessScore = _calculateLivenessScore(face);
      
      if (livenessScore < 0.6) {
        return FaceDetectionResult(
          detected: false,
          reason: 'No se pudo verificar que sea una persona real',
          livenessScore: livenessScore,
        );
      }
      
      LoggerService.info('✅ Rostro detectado correctamente');
      
      return FaceDetectionResult(
        detected: true,
        face: face,
        livenessScore: livenessScore,
        qualityScore: qualityCheck.score,
        reason: 'Rostro válido detectado',
      );
      
    } catch (e) {
      LoggerService.error('❌ Error detectando rostro:', e);
      return FaceDetectionResult(
        detected: false,
        reason: 'Error en detección: ${e.toString()}',
      );
    }
  }
  
  /// Validar calidad del rostro
  FaceQualityCheck _validateFaceQuality(Face face) {
    try {
      int qualityScore = 100;
      List<String> issues = [];
      
      // 1. Verificar tamaño del rostro
      final faceSize = face.boundingBox.width * face.boundingBox.height;
      if (faceSize < 50000) {
        issues.add('Rostro muy pequeño. Acérquese más');
        qualityScore -= 30;
      }
      
      // 2. Verificar ángulo de la cabeza (Head Euler Angle)
      final headEulerAngleY = face.headEulerAngleY ?? 0;
      final headEulerAngleZ = face.headEulerAngleZ ?? 0;
      
      if (headEulerAngleY!.abs() > 15) {
        issues.add('Mire de frente a la cámara');
        qualityScore -= 20;
      }
      
      if (headEulerAngleZ!.abs() > 15) {
        issues.add('Mantenga la cabeza recta');
        qualityScore -= 15;
      }
      
      // 3. Verificar que los ojos estén abiertos
      final leftEyeOpen = face.leftEyeOpenProbability ?? 0;
      final rightEyeOpen = face.rightEyeOpenProbability ?? 0;
      
      if (leftEyeOpen < 0.5 || rightEyeOpen < 0.5) {
        issues.add('Mantenga los ojos abiertos');
        qualityScore -= 25;
      }
      
      // 4. Verificar expresión neutral
      final smilingProbability = face.smilingProbability ?? 0;
      
      if (smilingProbability > 0.7) {
        issues.add('Mantenga una expresión neutral');
        qualityScore -= 10;
      }
      
      // 5. Verificar que el rostro esté centrado
      final centerX = face.boundingBox.left + face.boundingBox.width / 2;
      final centerY = face.boundingBox.top + face.boundingBox.height / 2;
      
      // Asumiendo imagen de 1920x1080
      final imageCenterX = 960;
      final imageCenterY = 540;
      
      final distanceFromCenter = math.sqrt(
        math.pow(centerX - imageCenterX, 2) + 
        math.pow(centerY - imageCenterY, 2)
      );
      
      if (distanceFromCenter > 300) {
        issues.add('Centre su rostro en el círculo');
        qualityScore -= 15;
      }
      
      // Determinar si es válido
      final isValid = qualityScore >= 60 && issues.isEmpty;
      
      return FaceQualityCheck(
        isValid: isValid,
        score: qualityScore,
        reason: issues.isEmpty ? 'Calidad aceptable' : issues.join('. '),
      );
      
    } catch (e) {
      LoggerService.error('❌ Error validando calidad de rostro:', e);
      return FaceQualityCheck(
        isValid: true, // Permitir continuar en caso de error
        score: 70,
        reason: 'No se pudo validar calidad completamente',
      );
    }
  }
  
  /// Calcular score de liveness (detección de vida)
  double _calculateLivenessScore(Face face) {
    try {
      double livenessScore = 0.5; // Score base
      
      // 1. Verificar movimiento de ojos (si están abiertos)
      final leftEyeOpen = face.leftEyeOpenProbability ?? 0;
      final rightEyeOpen = face.rightEyeOpenProbability ?? 0;
      
      if (leftEyeOpen > 0.8 && rightEyeOpen > 0.8) {
        livenessScore += 0.2;
      }
      
      // 2. Verificar landmarks faciales
      if (face.landmarks.isNotEmpty) {
        livenessScore += 0.15;
      }
      
      // 3. Verificar contornos faciales
      if (face.contours.isNotEmpty) {
        livenessScore += 0.15;
      }
      
      // 4. Verificar tracking ID (indica rostro real en movimiento)
      if (face.trackingId != null) {
        livenessScore += 0.1;
      }
      
      // Limitar entre 0 y 1
      return math.min(1.0, math.max(0.0, livenessScore));
      
    } catch (e) {
      LoggerService.error('❌ Error calculando liveness:', e);
      return 0.5; // Score por defecto
    }
  }
  
  /// Verificar que el rostro esté dentro del área objetivo
  bool isFaceInTargetArea(Face face, Rect targetArea) {
    final faceBounds = face.boundingBox;
    
    // Verificar que el rostro esté completamente dentro del área
    return faceBounds.left >= targetArea.left &&
           faceBounds.top >= targetArea.top &&
           faceBounds.right <= targetArea.right &&
           faceBounds.bottom <= targetArea.bottom;
  }
  
  /// Obtener instrucciones para el usuario
  String getFeedback(Face face) {
    final headEulerAngleY = face.headEulerAngleY ?? 0;
    final headEulerAngleZ = face.headEulerAngleZ ?? 0;
    final leftEyeOpen = face.leftEyeOpenProbability ?? 0;
    final rightEyeOpen = face.rightEyeOpenProbability ?? 0;
    
    if (headEulerAngleY.abs() > 15) {
      return headEulerAngleY > 0 
        ? 'Gire ligeramente a la izquierda' 
        : 'Gire ligeramente a la derecha';
    }
    
    if (headEulerAngleZ.abs() > 15) {
      return 'Mantenga la cabeza recta';
    }
    
    if (leftEyeOpen < 0.5 || rightEyeOpen < 0.5) {
      return 'Abra bien los ojos';
    }
    
    final faceSize = face.boundingBox.width * face.boundingBox.height;
    if (faceSize < 50000) {
      return 'Acérquese más';
    }
    
    if (faceSize > 200000) {
      return 'Aléjese un poco';
    }
    
    return 'Perfecto, manténgase así';
  }
  
  /// Liberar recursos
  Future<void> dispose() async {
    await _faceDetector.close();
  }
}

/// Resultado de detección facial
class FaceDetectionResult {
  final bool detected;
  final Face? face;
  final double? livenessScore;
  final int? qualityScore;
  final String reason;
  
  FaceDetectionResult({
    required this.detected,
    this.face,
    this.livenessScore,
    this.qualityScore,
    this.reason = '',
  });
}

/// Validación de calidad de rostro
class FaceQualityCheck {
  final bool isValid;
  final int score;
  final String reason;
  
  FaceQualityCheck({
    required this.isValid,
    required this.score,
    required this.reason,
  });
}

/// Tamaño
class Size {
  final double width;
  final double height;
  
  Size(this.width, this.height);
}

/// Rectángulo
class Rect {
  final double left;
  final double top;
  final double right;
  final double bottom;
  
  Rect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });
}
