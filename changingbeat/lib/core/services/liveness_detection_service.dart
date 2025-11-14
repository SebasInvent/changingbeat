import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Servicio para detección de vivacidad (anti-spoofing)
class LivenessDetectionService {
  // Estado de detección
  LivenessChallenge? _currentChallenge;
  final List<LivenessChallengeResult> _challengeResults = [];

  // Configuración
  static const int _requiredChallenges = 2; // Número de challenges requeridos
  static const Duration _challengeTimeout = Duration(seconds: 10);

  // Detección de parpadeo
  int _consecutiveEyesOpen = 0;
  int _consecutiveEyesClosed = 0;
  int _blinkCount = 0;
  static const int _framesForEyeState =
      2; // Frames consecutivos para confirmar estado

  // Detección de sonrisa
  int _consecutiveSmiling = 0;
  int _consecutiveNotSmiling = 0;
  bool _hasSmiled = false;

  // Detección de movimiento de cabeza
  double? _initialHeadYaw;
  bool _hasMovedLeft = false;
  bool _hasMovedRight = false;
  static const double _headMovementThreshold = 15.0; // Grados

  /// Obtener el challenge actual
  LivenessChallenge? get currentChallenge => _currentChallenge;

  /// Verificar si pasó todos los challenges
  bool get hasPassedAllChallenges =>
      _challengeResults.length >= _requiredChallenges &&
      _challengeResults.every((r) => r.passed);

  /// Progreso de challenges (0.0 - 1.0)
  double get challengeProgress =>
      _challengeResults.length / _requiredChallenges;

  /// Iniciar nuevo challenge
  LivenessChallenge startNewChallenge() {
    // Seleccionar challenge aleatorio que no se haya completado
    final availableChallenges = LivenessChallengeType.values.where((type) {
      return !_challengeResults.any((r) => r.challengeType == type && r.passed);
    }).toList();

    if (availableChallenges.isEmpty) {
      // Si ya completó todos, seleccionar uno aleatorio
      final randomType = LivenessChallengeType
          .values[Random().nextInt(LivenessChallengeType.values.length)];
      _currentChallenge = LivenessChallenge(type: randomType);
    } else {
      final randomType =
          availableChallenges[Random().nextInt(availableChallenges.length)];
      _currentChallenge = LivenessChallenge(type: randomType);
    }

    _resetChallengeState();
    return _currentChallenge!;
  }

  /// Procesar frame para el challenge actual
  LivenessChallengeStatus processFrame(Face face) {
    if (_currentChallenge == null) {
      return LivenessChallengeStatus.waiting;
    }

    // Verificar timeout
    if (_currentChallenge!.hasTimedOut) {
      return LivenessChallengeStatus.failed;
    }

    switch (_currentChallenge!.type) {
      case LivenessChallengeType.blink:
        return _processBlink(face);

      case LivenessChallengeType.smile:
        return _processSmile(face);

      case LivenessChallengeType.turnHead:
        return _processTurnHead(face);
    }
  }

  /// Procesar detección de parpadeo
  LivenessChallengeStatus _processBlink(Face face) {
    if (face.leftEyeOpenProbability == null ||
        face.rightEyeOpenProbability == null) {
      return LivenessChallengeStatus.processing;
    }

    final leftEye = face.leftEyeOpenProbability!;
    final rightEye = face.rightEyeOpenProbability!;
    final bothEyesOpen = leftEye > 0.5 && rightEye > 0.5;
    final bothEyesClosed = leftEye < 0.3 && rightEye < 0.3;

    if (bothEyesOpen) {
      _consecutiveEyesOpen++;
      _consecutiveEyesClosed = 0;
    } else if (bothEyesClosed) {
      _consecutiveEyesClosed++;

      // Si estaban abiertos y ahora cerrados, contar parpadeo
      if (_consecutiveEyesOpen >= _framesForEyeState &&
          _consecutiveEyesClosed >= _framesForEyeState) {
        _blinkCount++;
        debugPrint('Blink detected! Count: $_blinkCount');
        _consecutiveEyesOpen = 0;
      }
    }

    // Requiere 2 parpadeos para pasar
    if (_blinkCount >= 2) {
      _completeChallenge(true);
      return LivenessChallengeStatus.passed;
    }

    return LivenessChallengeStatus.processing;
  }

  /// Procesar detección de sonrisa
  LivenessChallengeStatus _processSmile(Face face) {
    if (face.smilingProbability == null) {
      return LivenessChallengeStatus.processing;
    }

    final smiling = face.smilingProbability! > 0.7;

    if (smiling) {
      _consecutiveSmiling++;
      _consecutiveNotSmiling = 0;

      if (_consecutiveSmiling >= 3) {
        _hasSmiled = true;
      }
    } else {
      _consecutiveNotSmiling++;
      _consecutiveSmiling = 0;
    }

    // Debe sonreír y luego dejar de sonreír
    if (_hasSmiled && _consecutiveNotSmiling >= 3) {
      _completeChallenge(true);
      return LivenessChallengeStatus.passed;
    }

    return LivenessChallengeStatus.processing;
  }

  /// Procesar detección de movimiento de cabeza
  LivenessChallengeStatus _processTurnHead(Face face) {
    if (face.headEulerAngleY == null) {
      return LivenessChallengeStatus.processing;
    }

    final currentYaw = face.headEulerAngleY!;

    // Establecer posición inicial
    if (_initialHeadYaw == null) {
      _initialHeadYaw = currentYaw;
      return LivenessChallengeStatus.processing;
    }

    final yawDifference = currentYaw - _initialHeadYaw!;

    // Detectar movimiento a la izquierda
    if (yawDifference < -_headMovementThreshold) {
      _hasMovedLeft = true;
      debugPrint('Head moved left');
    }

    // Detectar movimiento a la derecha
    if (yawDifference > _headMovementThreshold) {
      _hasMovedRight = true;
      debugPrint('Head moved right');
    }

    // Debe mover la cabeza a ambos lados
    if (_hasMovedLeft && _hasMovedRight) {
      _completeChallenge(true);
      return LivenessChallengeStatus.passed;
    }

    return LivenessChallengeStatus.processing;
  }

  /// Completar challenge actual
  void _completeChallenge(bool passed) {
    if (_currentChallenge != null) {
      _challengeResults.add(LivenessChallengeResult(
        challengeType: _currentChallenge!.type,
        passed: passed,
        completedAt: DateTime.now(),
      ));

      debugPrint(
          'Challenge ${_currentChallenge!.type} ${passed ? "PASSED" : "FAILED"}');
      _currentChallenge = null;
    }
  }

  /// Resetear estado del challenge
  void _resetChallengeState() {
    _consecutiveEyesOpen = 0;
    _consecutiveEyesClosed = 0;
    _blinkCount = 0;
    _consecutiveSmiling = 0;
    _consecutiveNotSmiling = 0;
    _hasSmiled = false;
    _initialHeadYaw = null;
    _hasMovedLeft = false;
    _hasMovedRight = false;
  }

  /// Resetear todo el servicio
  void reset() {
    _currentChallenge = null;
    _challengeResults.clear();
    _resetChallengeState();
  }

  /// Obtener resultados de challenges
  List<LivenessChallengeResult> get challengeResults =>
      List.unmodifiable(_challengeResults);
}

/// Tipo de challenge de liveness
enum LivenessChallengeType {
  blink, // Parpadear
  smile, // Sonreír
  turnHead, // Girar cabeza
}

/// Challenge de liveness
class LivenessChallenge {
  final LivenessChallengeType type;
  final DateTime startTime;
  final Duration timeout;

  LivenessChallenge({
    required this.type,
    this.timeout = const Duration(seconds: 10),
  }) : startTime = DateTime.now();

  bool get hasTimedOut => DateTime.now().difference(startTime) > timeout;

  Duration get remainingTime {
    final elapsed = DateTime.now().difference(startTime);
    final remaining = timeout - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  String get instruction {
    switch (type) {
      case LivenessChallengeType.blink:
        return 'Parpadee 2 veces';
      case LivenessChallengeType.smile:
        return 'Sonría y luego deje de sonreír';
      case LivenessChallengeType.turnHead:
        return 'Gire su cabeza a la izquierda y derecha';
    }
  }

  String get shortInstruction {
    switch (type) {
      case LivenessChallengeType.blink:
        return 'Parpadee';
      case LivenessChallengeType.smile:
        return 'Sonría';
      case LivenessChallengeType.turnHead:
        return 'Gire la cabeza';
    }
  }
}

/// Estado del challenge
enum LivenessChallengeStatus {
  waiting, // Esperando inicio
  processing, // En proceso
  passed, // Pasado
  failed, // Fallado
}

/// Resultado de un challenge
class LivenessChallengeResult {
  final LivenessChallengeType challengeType;
  final bool passed;
  final DateTime completedAt;

  LivenessChallengeResult({
    required this.challengeType,
    required this.passed,
    required this.completedAt,
  });
}
