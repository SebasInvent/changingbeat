import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../services/face_detection_service.dart';
import '../theme/app_theme.dart';

/// Overlay para mostrar guías visuales de detección facial
class FaceDetectionOverlay extends StatelessWidget {
  final FaceDetectionResult? detectionResult;
  final Size cameraSize;

  const FaceDetectionOverlay({
    super.key,
    required this.detectionResult,
    required this.cameraSize,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Óvalo guía
        _buildFaceGuide(context),

        // Bounding box del rostro detectado (opcional, para debug)
        if (detectionResult?.face != null)
          _buildFaceBoundingBox(detectionResult!.face!),

        // Feedback de calidad
        _buildQualityFeedback(context),
      ],
    );
  }

  /// Óvalo guía para posicionar el rostro
  Widget _buildFaceGuide(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final ovalWidth = screenSize.width * 0.7;
    final ovalHeight = screenSize.height * 0.5;

    Color guideColor;
    double strokeWidth;

    if (detectionResult == null) {
      guideColor = Colors.white.withOpacity(0.5);
      strokeWidth = 2;
    } else {
      switch (detectionResult!.status) {
        case FaceDetectionStatus.faceDetected:
          if (detectionResult!.isGoodQuality) {
            guideColor = AppTheme.accentColor;
            strokeWidth = 4;
          } else {
            guideColor = AppTheme.warningColor;
            strokeWidth = 3;
          }
          break;
        case FaceDetectionStatus.noFaceDetected:
          guideColor = Colors.white.withOpacity(0.5);
          strokeWidth = 2;
          break;
        case FaceDetectionStatus.multipleFaces:
          guideColor = AppTheme.errorColor;
          strokeWidth = 3;
          break;
        default:
          guideColor = Colors.white.withOpacity(0.5);
          strokeWidth = 2;
      }
    }

    return Center(
      child: CustomPaint(
        size: Size(ovalWidth, ovalHeight),
        painter: FaceOvalPainter(
          color: guideColor,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }

  /// Bounding box del rostro detectado
  Widget _buildFaceBoundingBox(Face face) {
    return Positioned(
      left: face.boundingBox.left,
      top: face.boundingBox.top,
      child: Container(
        width: face.boundingBox.width,
        height: face.boundingBox.height,
        decoration: BoxDecoration(
          border: Border.all(
            color: AppTheme.accentColor.withOpacity(0.5),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Feedback de calidad en la parte superior
  Widget _buildQualityFeedback(BuildContext context) {
    if (detectionResult == null) {
      return const SizedBox.shrink();
    }

    Color backgroundColor;
    IconData icon;
    String message = detectionResult!.feedbackMessage;

    switch (detectionResult!.status) {
      case FaceDetectionStatus.faceDetected:
        if (detectionResult!.isGoodQuality) {
          backgroundColor = AppTheme.accentColor;
          icon = Icons.check_circle;
        } else {
          backgroundColor = AppTheme.warningColor;
          icon = Icons.warning;
        }
        break;
      case FaceDetectionStatus.noFaceDetected:
        backgroundColor = AppTheme.errorColor;
        icon = Icons.face_retouching_off;
        break;
      case FaceDetectionStatus.multipleFaces:
        backgroundColor = AppTheme.errorColor;
        icon = Icons.groups;
        break;
      case FaceDetectionStatus.processing:
        backgroundColor = Colors.blue;
        icon = Icons.hourglass_empty;
        break;
      case FaceDetectionStatus.error:
        backgroundColor = AppTheme.errorColor;
        icon = Icons.error;
        break;
    }

    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (detectionResult!.quality != null)
              _buildQualityIndicator(detectionResult!.quality!),
          ],
        ),
      ),
    );
  }

  /// Indicador visual de calidad (score)
  Widget _buildQualityIndicator(FaceQuality quality) {
    Color color;
    switch (quality.level) {
      case FaceQualityLevel.excellent:
        color = Colors.white;
        break;
      case FaceQualityLevel.good:
        color = Colors.white.withOpacity(0.9);
        break;
      case FaceQualityLevel.fair:
        color = Colors.white.withOpacity(0.7);
        break;
      case FaceQualityLevel.poor:
        color = Colors.white.withOpacity(0.5);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${quality.score.toInt()}%',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Painter para dibujar el óvalo guía
class FaceOvalPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  FaceOvalPainter({
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Dibujar óvalo
    canvas.drawOval(rect, paint);

    // Dibujar líneas guía (opcional)
    final dashedPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Línea vertical central
    _drawDashedLine(
      canvas,
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      dashedPaint,
    );

    // Línea horizontal central
    _drawDashedLine(
      canvas,
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      dashedPaint,
    );
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 5.0;

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = (dx * dx + dy * dy);
    final normalizedDx = dx / distance;
    final normalizedDy = dy / distance;

    var currentX = start.dx;
    var currentY = start.dy;

    while ((currentX - end.dx).abs() > dashWidth ||
        (currentY - end.dy).abs() > dashWidth) {
      canvas.drawLine(
        Offset(currentX, currentY),
        Offset(
          currentX + normalizedDx * dashWidth,
          currentY + normalizedDy * dashWidth,
        ),
        paint,
      );

      currentX += normalizedDx * (dashWidth + dashSpace);
      currentY += normalizedDy * (dashWidth + dashSpace);
    }
  }

  @override
  bool shouldRepaint(FaceOvalPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}
