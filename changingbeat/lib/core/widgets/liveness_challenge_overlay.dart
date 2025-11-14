import 'package:flutter/material.dart';
import '../services/liveness_detection_service.dart';
import '../theme/app_theme.dart';

/// Overlay para mostrar instrucciones de liveness challenge
class LivenessChallengeOverlay extends StatelessWidget {
  final LivenessChallenge? challenge;
  final LivenessChallengeStatus status;
  final double progress;

  const LivenessChallengeOverlay({
    super.key,
    required this.challenge,
    required this.status,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    if (challenge == null) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // Instrucción principal
        _buildInstructionCard(context),
        
        // Progreso de challenges
        _buildProgressIndicator(context),
        
        // Timer
        _buildTimer(context),
      ],
    );
  }

  Widget _buildInstructionCard(BuildContext context) {
    Color backgroundColor;
    IconData icon;
    String message;

    switch (status) {
      case LivenessChallengeStatus.waiting:
        backgroundColor = Colors.blue;
        icon = Icons.info;
        message = 'Preparándose...';
        break;
      case LivenessChallengeStatus.processing:
        backgroundColor = AppTheme.primaryColor;
        icon = _getChallengeIcon(challenge!.type);
        message = challenge!.instruction;
        break;
      case LivenessChallengeStatus.passed:
        backgroundColor = AppTheme.accentColor;
        icon = Icons.check_circle;
        message = '¡Excelente!';
        break;
      case LivenessChallengeStatus.failed:
        backgroundColor = AppTheme.errorColor;
        icon = Icons.error;
        message = 'Tiempo agotado. Intente nuevamente';
        break;
    }

    return Positioned(
      top: 80,
      left: 20,
      right: 20,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (status == LivenessChallengeStatus.processing) ...[
              const SizedBox(height: 8),
              Text(
                _getHelpText(challenge!.type),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    return Positioned(
      bottom: 120,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.verified_user,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Verificación: ${(progress * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 100,
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white30,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.accentColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimer(BuildContext context) {
    if (status != LivenessChallengeStatus.processing) {
      return const SizedBox.shrink();
    }

    final remainingSeconds = challenge!.remainingTime.inSeconds;
    final isLowTime = remainingSeconds <= 3;

    return Positioned(
      top: 20,
      right: 20,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isLowTime 
              ? AppTheme.errorColor 
              : Colors.black.withOpacity(0.6),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (isLowTime ? AppTheme.errorColor : Colors.black)
                  .withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          '$remainingSeconds',
          style: TextStyle(
            color: Colors.white,
            fontSize: isLowTime ? 24 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  IconData _getChallengeIcon(LivenessChallengeType type) {
    switch (type) {
      case LivenessChallengeType.blink:
        return Icons.remove_red_eye;
      case LivenessChallengeType.smile:
        return Icons.sentiment_satisfied_alt;
      case LivenessChallengeType.turnHead:
        return Icons.360;
    }
  }

  String _getHelpText(LivenessChallengeType type) {
    switch (type) {
      case LivenessChallengeType.blink:
        return 'Cierre y abra los ojos naturalmente';
      case LivenessChallengeType.smile:
        return 'Muestre una sonrisa natural';
      case LivenessChallengeType.turnHead:
        return 'Mueva su cabeza lentamente';
    }
  }
}

/// Widget para mostrar el resultado final de liveness
class LivenessResultOverlay extends StatelessWidget {
  final bool passed;
  final VoidCallback onContinue;
  final VoidCallback onRetry;

  const LivenessResultOverlay({
    super.key,
    required this.passed,
    required this.onContinue,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                passed ? Icons.check_circle : Icons.error,
                color: passed ? AppTheme.accentColor : AppTheme.errorColor,
                size: 80,
              ),
              const SizedBox(height: 24),
              Text(
                passed 
                    ? '¡Verificación Exitosa!' 
                    : 'Verificación Fallida',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: passed ? AppTheme.accentColor : AppTheme.errorColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                passed
                    ? 'Ha pasado todas las pruebas de vivacidad'
                    : 'No se pudo verificar que sea una persona real',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (passed)
                ElevatedButton.icon(
                  onPressed: onContinue,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Continuar'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      label: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
