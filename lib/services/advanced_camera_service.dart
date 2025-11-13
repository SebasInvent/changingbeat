import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'logger_service.dart';

/// Servicio avanzado de cámara con control de calidad
class AdvancedCameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  
  // Configuración de calidad
  static const int TARGET_WIDTH = 1920;
  static const int TARGET_HEIGHT = 1080;
  static const int JPEG_QUALITY = 90;
  static const int MIN_BRIGHTNESS = 50;
  static const int MAX_BRIGHTNESS = 200;
  
  /// Inicializar cámara
  Future<bool> initialize({bool useFrontCamera = false}) async {
    try {
      LoggerService.info('📸 Inicializando cámara avanzada...');
      
      _cameras = await availableCameras();
      
      if (_cameras == null || _cameras!.isEmpty) {
        LoggerService.error('❌ No hay cámaras disponibles');
        return false;
      }
      
      // Seleccionar cámara
      CameraDescription camera;
      if (useFrontCamera) {
        camera = _cameras!.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first,
        );
      } else {
        camera = _cameras!.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras!.first,
        );
      }
      
      // Crear controlador con máxima resolución
      _controller = CameraController(
        camera,
        ResolutionPreset.veryHigh,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      
      await _controller!.initialize();
      
      // Configurar modo de flash
      await _controller!.setFlashMode(FlashMode.off);
      
      // Configurar modo de enfoque
      await _controller!.setFocusMode(FocusMode.auto);
      
      // Configurar modo de exposición
      await _controller!.setExposureMode(ExposureMode.auto);
      
      _isInitialized = true;
      
      LoggerService.info('✅ Cámara inicializada correctamente');
      return true;
      
    } catch (e) {
      LoggerService.error('❌ Error inicializando cámara:', e);
      return false;
    }
  }
  
  /// Capturar imagen con validación de calidad
  Future<CaptureResult?> captureWithQualityCheck() async {
    if (!_isInitialized || _controller == null) {
      LoggerService.error('❌ Cámara no inicializada');
      return null;
    }
    
    try {
      LoggerService.info('📸 Capturando imagen...');
      
      // Capturar imagen
      final XFile imageFile = await _controller!.takePicture();
      
      // Leer bytes de la imagen
      final Uint8List imageBytes = await imageFile.readAsBytes();
      
      // Decodificar imagen
      img.Image? image = img.decodeImage(imageBytes);
      
      if (image == null) {
        LoggerService.error('❌ No se pudo decodificar la imagen');
        return null;
      }
      
      // Validar calidad de imagen
      final qualityCheck = await _validateImageQuality(image);
      
      if (!qualityCheck.isValid) {
        LoggerService.warning('⚠️ Imagen no cumple con calidad mínima: ${qualityCheck.reason}');
        return CaptureResult(
          success: false,
          reason: qualityCheck.reason,
        );
      }
      
      // Optimizar imagen
      final optimizedImage = await _optimizeImage(image);
      
      // Convertir a Base64
      final base64Image = base64Encode(img.encodeJpg(optimizedImage, quality: JPEG_QUALITY));
      
      LoggerService.info('✅ Imagen capturada y optimizada');
      
      return CaptureResult(
        success: true,
        imageBase64: base64Image,
        width: optimizedImage.width,
        height: optimizedImage.height,
        fileSize: base64Image.length,
        qualityScore: qualityCheck.score,
      );
      
    } catch (e) {
      LoggerService.error('❌ Error capturando imagen:', e);
      return CaptureResult(
        success: false,
        reason: 'Error al capturar: ${e.toString()}',
      );
    }
  }
  
  /// Validar calidad de imagen
  Future<QualityCheck> _validateImageQuality(img.Image image) async {
    try {
      // 1. Verificar resolución mínima
      if (image.width < 800 || image.height < 600) {
        return QualityCheck(
          isValid: false,
          reason: 'Resolución muy baja',
          score: 0,
        );
      }
      
      // 2. Calcular brillo promedio
      int totalBrightness = 0;
      int pixelCount = 0;
      
      for (int y = 0; y < image.height; y += 10) {
        for (int x = 0; x < image.width; x += 10) {
          final pixel = image.getPixel(x, y);
          final r = pixel.r.toInt();
          final g = pixel.g.toInt();
          final b = pixel.b.toInt();
          final brightness = (r + g + b) ~/ 3;
          totalBrightness += brightness;
          pixelCount++;
        }
      }
      
      final avgBrightness = totalBrightness ~/ pixelCount;
      
      // 3. Verificar brillo
      if (avgBrightness < MIN_BRIGHTNESS) {
        return QualityCheck(
          isValid: false,
          reason: 'Imagen muy oscura. Mejore la iluminación',
          score: 30,
        );
      }
      
      if (avgBrightness > MAX_BRIGHTNESS) {
        return QualityCheck(
          isValid: false,
          reason: 'Imagen muy brillante. Reduzca la luz',
          score: 30,
        );
      }
      
      // 4. Calcular nitidez (Laplacian variance)
      final sharpness = _calculateSharpness(image);
      
      if (sharpness < 100) {
        return QualityCheck(
          isValid: false,
          reason: 'Imagen borrosa. Mantenga el dispositivo firme',
          score: 40,
        );
      }
      
      // 5. Calcular score final
      int qualityScore = 100;
      
      // Penalizar por brillo no óptimo
      if (avgBrightness < 100 || avgBrightness > 180) {
        qualityScore -= 10;
      }
      
      // Penalizar por nitidez baja
      if (sharpness < 200) {
        qualityScore -= 15;
      }
      
      return QualityCheck(
        isValid: true,
        reason: 'Calidad aceptable',
        score: qualityScore,
      );
      
    } catch (e) {
      LoggerService.error('❌ Error validando calidad:', e);
      return QualityCheck(
        isValid: true, // Permitir continuar en caso de error
        reason: 'No se pudo validar calidad',
        score: 50,
      );
    }
  }
  
  /// Calcular nitidez de imagen (Laplacian variance)
  double _calculateSharpness(img.Image image) {
    try {
      // Convertir a escala de grises
      final gray = img.grayscale(image);
      
      // Aplicar operador Laplacian simplificado
      double variance = 0;
      int count = 0;
      
      for (int y = 1; y < gray.height - 1; y += 5) {
        for (int x = 1; x < gray.width - 1; x += 5) {
          final center = gray.getPixel(x, y).r.toInt();
          final top = gray.getPixel(x, y - 1).r.toInt();
          final bottom = gray.getPixel(x, y + 1).r.toInt();
          final left = gray.getPixel(x - 1, y).r.toInt();
          final right = gray.getPixel(x + 1, y).r.toInt();
          
          final laplacian = (4 * center - top - bottom - left - right).abs();
          variance += laplacian * laplacian;
          count++;
        }
      }
      
      return variance / count;
      
    } catch (e) {
      LoggerService.error('❌ Error calculando nitidez:', e);
      return 100; // Valor por defecto
    }
  }
  
  /// Optimizar imagen
  Future<img.Image> _optimizeImage(img.Image image) async {
    try {
      // 1. Redimensionar si es necesario
      img.Image optimized = image;
      
      if (image.width > TARGET_WIDTH || image.height > TARGET_HEIGHT) {
        optimized = img.copyResize(
          image,
          width: TARGET_WIDTH,
          height: TARGET_HEIGHT,
          interpolation: img.Interpolation.linear,
        );
      }
      
      // 2. Ajustar brillo si es necesario
      // (opcional, se puede implementar auto-ajuste)
      
      // 3. Aumentar nitidez ligeramente
      optimized = img.adjustColor(
        optimized,
        saturation: 1.1,
        contrast: 1.05,
      );
      
      return optimized;
      
    } catch (e) {
      LoggerService.error('❌ Error optimizando imagen:', e);
      return image; // Retornar original en caso de error
    }
  }
  
  /// Obtener controlador de cámara
  CameraController? get controller => _controller;
  
  /// Verificar si está inicializada
  bool get isInitialized => _isInitialized;
  
  /// Cambiar entre cámaras
  Future<bool> switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) {
      return false;
    }
    
    final currentLens = _controller?.description.lensDirection;
    final newLens = currentLens == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    
    await dispose();
    return await initialize(useFrontCamera: newLens == CameraLensDirection.front);
  }
  
  /// Activar/desactivar flash
  Future<void> toggleFlash() async {
    if (_controller == null) return;
    
    final currentMode = _controller!.value.flashMode;
    final newMode = currentMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    
    await _controller!.setFlashMode(newMode);
  }
  
  /// Enfocar en un punto específico
  Future<void> focusAt(Offset point) async {
    if (_controller == null) return;
    
    try {
      await _controller!.setFocusPoint(point);
      await _controller!.setExposurePoint(point);
    } catch (e) {
      LoggerService.error('❌ Error enfocando:', e);
    }
  }
  
  /// Liberar recursos
  Future<void> dispose() async {
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
      _isInitialized = false;
    }
  }
}

/// Resultado de captura
class CaptureResult {
  final bool success;
  final String? imageBase64;
  final int? width;
  final int? height;
  final int? fileSize;
  final int? qualityScore;
  final String? reason;
  
  CaptureResult({
    required this.success,
    this.imageBase64,
    this.width,
    this.height,
    this.fileSize,
    this.qualityScore,
    this.reason,
  });
}

/// Resultado de validación de calidad
class QualityCheck {
  final bool isValid;
  final String reason;
  final int score;
  
  QualityCheck({
    required this.isValid,
    required this.reason,
    required this.score,
  });
}
