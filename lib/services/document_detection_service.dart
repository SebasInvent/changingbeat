import 'dart:typed_data';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'dart:convert';
import 'logger_service.dart';

/// Servicio de detección y procesamiento de documentos
class DocumentDetectionService {
  final TextRecognizer _textRecognizer = TextRecognizer();
  
  /// Detectar si hay un documento en la imagen
  Future<DocumentDetectionResult> detectDocument(String imageBase64) async {
    try {
      LoggerService.info('🔍 Detectando documento...');
      
      // Decodificar imagen
      final imageBytes = base64Decode(imageBase64);
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        return DocumentDetectionResult(
          detected: false,
          reason: 'No se pudo decodificar la imagen',
        );
      }
      
      // Detectar bordes del documento
      final edges = await _detectEdges(image);
      
      if (!edges.detected) {
        return DocumentDetectionResult(
          detected: false,
          reason: 'No se detectaron bordes del documento',
        );
      }
      
      // Verificar que el documento ocupe suficiente espacio
      final coverage = _calculateCoverage(edges.corners!, image.width, image.height);
      
      if (coverage < 0.3) {
        return DocumentDetectionResult(
          detected: false,
          reason: 'Documento muy pequeño. Acérquese más',
        );
      }
      
      if (coverage > 0.95) {
        return DocumentDetectionResult(
          detected: false,
          reason: 'Documento muy cerca. Aléjese un poco',
        );
      }
      
      LoggerService.info('✅ Documento detectado correctamente');
      
      return DocumentDetectionResult(
        detected: true,
        corners: edges.corners,
        coverage: coverage,
        reason: 'Documento detectado',
      );
      
    } catch (e) {
      LoggerService.error('❌ Error detectando documento:', e);
      return DocumentDetectionResult(
        detected: false,
        reason: 'Error en detección: ${e.toString()}',
      );
    }
  }
  
  /// Extraer texto del documento (OCR)
  Future<OCRResult> extractText(String imageBase64) async {
    try {
      LoggerService.info('📝 Extrayendo texto del documento...');
      
      // Decodificar imagen
      final imageBytes = base64Decode(imageBase64);
      
      // Crear InputImage para ML Kit
      final inputImage = InputImage.fromBytes(
        bytes: imageBytes,
        metadata: InputImageMetadata(
          size: Size(1920, 1080),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.yuv420,
          bytesPerRow: 1920,
        ),
      );
      
      // Reconocer texto
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      // Extraer información específica de la cédula
      final extractedData = _extractCedulaData(recognizedText);
      
      LoggerService.info('✅ Texto extraído: ${extractedData.documentNumber ?? "No detectado"}');
      
      return extractedData;
      
    } catch (e) {
      LoggerService.error('❌ Error extrayendo texto:', e);
      return OCRResult(
        success: false,
        error: e.toString(),
      );
    }
  }
  
  /// Detectar bordes del documento
  Future<EdgeDetectionResult> _detectEdges(img.Image image) async {
    try {
      // Convertir a escala de grises
      final gray = img.grayscale(image);
      
      // Aplicar filtro Gaussian blur para reducir ruido
      final blurred = img.gaussianBlur(gray, radius: 2);
      
      // Detectar bordes con Sobel
      final edges = img.sobel(blurred);
      
      // Encontrar contornos (simplificado)
      final corners = _findDocumentCorners(edges);
      
      if (corners != null && corners.length == 4) {
        return EdgeDetectionResult(
          detected: true,
          corners: corners,
        );
      }
      
      return EdgeDetectionResult(detected: false);
      
    } catch (e) {
      LoggerService.error('❌ Error detectando bordes:', e);
      return EdgeDetectionResult(detected: false);
    }
  }
  
  /// Encontrar esquinas del documento
  List<Point>? _findDocumentCorners(img.Image edges) {
    try {
      // Algoritmo simplificado de detección de esquinas
      // En producción, usar algoritmos más robustos como Hough Transform
      
      final width = edges.width;
      final height = edges.height;
      
      // Buscar puntos con alta intensidad (bordes)
      List<Point> edgePoints = [];
      
      for (int y = 0; y < height; y += 5) {
        for (int x = 0; x < width; x += 5) {
          final pixel = edges.getPixel(x, y);
          final intensity = pixel.r.toInt();
          
          if (intensity > 128) {
            edgePoints.add(Point(x.toDouble(), y.toDouble()));
          }
        }
      }
      
      if (edgePoints.length < 100) {
        return null;
      }
      
      // Encontrar las 4 esquinas (simplificado)
      // Esquina superior izquierda
      final topLeft = edgePoints.reduce((a, b) => 
        (a.x + a.y) < (b.x + b.y) ? a : b
      );
      
      // Esquina superior derecha
      final topRight = edgePoints.reduce((a, b) => 
        (width - a.x + a.y) < (width - b.x + b.y) ? a : b
      );
      
      // Esquina inferior izquierda
      final bottomLeft = edgePoints.reduce((a, b) => 
        (a.x + height - a.y) < (b.x + height - b.y) ? a : b
      );
      
      // Esquina inferior derecha
      final bottomRight = edgePoints.reduce((a, b) => 
        (width - a.x + height - a.y) < (width - b.x + height - b.y) ? a : b
      );
      
      return [topLeft, topRight, bottomRight, bottomLeft];
      
    } catch (e) {
      LoggerService.error('❌ Error encontrando esquinas:', e);
      return null;
    }
  }
  
  /// Calcular cobertura del documento en la imagen
  double _calculateCoverage(List<Point> corners, int imageWidth, int imageHeight) {
    try {
      // Calcular área del polígono usando fórmula del área de Shoelace
      double area = 0;
      
      for (int i = 0; i < corners.length; i++) {
        final j = (i + 1) % corners.length;
        area += corners[i].x * corners[j].y;
        area -= corners[j].x * corners[i].y;
      }
      
      area = area.abs() / 2;
      
      final imageArea = imageWidth * imageHeight;
      final coverage = area / imageArea;
      
      return coverage;
      
    } catch (e) {
      LoggerService.error('❌ Error calculando cobertura:', e);
      return 0.5; // Valor por defecto
    }
  }
  
  /// Extraer datos específicos de cédula colombiana
  OCRResult _extractCedulaData(RecognizedText recognizedText) {
    try {
      String fullText = recognizedText.text;
      
      // Patrones para cédula colombiana
      final documentNumberPattern = RegExp(r'\b\d{6,10}\b');
      final datePattern = RegExp(r'\b\d{2}[/-]\d{2}[/-]\d{4}\b');
      final namePattern = RegExp(r'[A-ZÁÉÍÓÚÑ]{2,}\s+[A-ZÁÉÍÓÚÑ]{2,}');
      
      // Extraer número de documento
      final documentMatch = documentNumberPattern.firstMatch(fullText);
      final documentNumber = documentMatch?.group(0);
      
      // Extraer fecha de expedición
      final dateMatch = datePattern.firstMatch(fullText);
      final expeditionDate = dateMatch?.group(0);
      
      // Extraer nombre (simplificado)
      final nameMatches = namePattern.allMatches(fullText);
      String? fullName;
      if (nameMatches.isNotEmpty) {
        fullName = nameMatches.first.group(0);
      }
      
      return OCRResult(
        success: true,
        documentNumber: documentNumber,
        expeditionDate: expeditionDate,
        fullName: fullName,
        rawText: fullText,
      );
      
    } catch (e) {
      LoggerService.error('❌ Error extrayendo datos:', e);
      return OCRResult(
        success: false,
        error: e.toString(),
      );
    }
  }
  
  /// Liberar recursos
  Future<void> dispose() async {
    await _textRecognizer.close();
  }
}

/// Resultado de detección de documento
class DocumentDetectionResult {
  final bool detected;
  final List<Point>? corners;
  final double? coverage;
  final String reason;
  
  DocumentDetectionResult({
    required this.detected,
    this.corners,
    this.coverage,
    this.reason = '',
  });
}

/// Resultado de detección de bordes
class EdgeDetectionResult {
  final bool detected;
  final List<Point>? corners;
  
  EdgeDetectionResult({
    required this.detected,
    this.corners,
  });
}

/// Resultado de OCR
class OCRResult {
  final bool success;
  final String? documentNumber;
  final String? expeditionDate;
  final String? fullName;
  final String? rawText;
  final String? error;
  
  OCRResult({
    required this.success,
    this.documentNumber,
    this.expeditionDate,
    this.fullName,
    this.rawText,
    this.error,
  });
}

/// Punto en 2D
class Point {
  final double x;
  final double y;
  
  Point(this.x, this.y);
}

/// Tamaño
class Size {
  final double width;
  final double height;
  
  Size(this.width, this.height);
}
