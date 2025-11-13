import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'logger_service.dart';

/// Servicio de Text-to-Speech
/// Soporta TTS nativo de Android y ElevenLabs API
class TTSService {
  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Configuración de ElevenLabs (opcional)
  final String? _elevenLabsApiKey = null; // Agregar tu API key aquí
  final String _elevenLabsVoiceId = 'pNInz6obpgDQGcFmaJgB'; // Voz en español (Adam)
  
  bool _isInitialized = false;
  bool _useElevenLabs = false;

  /// Inicializar TTS
  Future<void> initialize() async {
    try {
      LoggerService.info('🔊 Inicializando TTS...');
      
      // Configurar TTS nativo
      await _flutterTts.setLanguage('es-ES');
      await _flutterTts.setSpeechRate(0.5); // Velocidad normal
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      
      // Verificar si usar ElevenLabs
      _useElevenLabs = _elevenLabsApiKey != null && _elevenLabsApiKey!.isNotEmpty;
      
      _isInitialized = true;
      
      LoggerService.info(_useElevenLabs 
        ? '✅ TTS inicializado con ElevenLabs'
        : '✅ TTS inicializado (nativo Android)');
        
    } catch (e) {
      LoggerService.error('❌ Error inicializando TTS:', e);
    }
  }

  /// Hablar texto
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      LoggerService.info('🔊 Hablando: "$text"');
      
      if (_useElevenLabs) {
        await _speakWithElevenLabs(text);
      } else {
        await _speakNative(text);
      }
    } catch (e) {
      LoggerService.error('❌ Error al hablar:', e);
      // Fallback a TTS nativo si ElevenLabs falla
      if (_useElevenLabs) {
        await _speakNative(text);
      }
    }
  }

  /// TTS nativo de Android
  Future<void> _speakNative(String text) async {
    await _flutterTts.speak(text);
  }

  /// TTS con ElevenLabs API
  Future<void> _speakWithElevenLabs(String text) async {
    try {
      final url = Uri.parse(
        'https://api.elevenlabs.io/v1/text-to-speech/$_elevenLabsVoiceId'
      );
      
      final response = await http.post(
        url,
        headers: {
          'Accept': 'audio/mpeg',
          'Content-Type': 'application/json',
          'xi-api-key': _elevenLabsApiKey!,
        },
        body: jsonEncode({
          'text': text,
          'model_id': 'eleven_multilingual_v2',
          'voice_settings': {
            'stability': 0.5,
            'similarity_boost': 0.75,
          }
        }),
      );

      if (response.statusCode == 200) {
        // Guardar audio temporalmente
        final tempDir = await getTemporaryDirectory();
        final audioFile = File('${tempDir.path}/tts_${DateTime.now().millisecondsSinceEpoch}.mp3');
        await audioFile.writeAsBytes(response.bodyBytes);
        
        // Reproducir audio
        await _audioPlayer.play(DeviceFileSource(audioFile.path));
        
        // Esperar a que termine
        await _audioPlayer.onPlayerComplete.first;
        
        // Limpiar archivo temporal
        await audioFile.delete();
      } else {
        throw Exception('Error en ElevenLabs: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('❌ Error con ElevenLabs:', e);
      rethrow;
    }
  }

  /// Detener TTS
  Future<void> stop() async {
    await _flutterTts.stop();
    await _audioPlayer.stop();
  }

  /// Pausar TTS
  Future<void> pause() async {
    await _flutterTts.pause();
    await _audioPlayer.pause();
  }

  /// Configurar velocidad (0.0 - 1.0)
  Future<void> setSpeechRate(double rate) async {
    await _flutterTts.setSpeechRate(rate);
  }

  /// Configurar volumen (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    await _flutterTts.setVolume(volume);
  }

  /// Configurar tono (0.5 - 2.0)
  Future<void> setPitch(double pitch) async {
    await _flutterTts.setPitch(pitch);
  }

  /// Obtener voces disponibles
  Future<List<dynamic>> getVoices() async {
    return await _flutterTts.getVoices;
  }

  /// Verificar si está hablando
  Future<bool> get isSpeaking async {
    return await _flutterTts.awaitSpeakCompletion(true);
  }

  /// Liberar recursos
  Future<void> dispose() async {
    await _flutterTts.stop();
    await _audioPlayer.dispose();
  }
}

/// Mensajes predefinidos del sistema
class TTSMessages {
  // Bienvenida
  static const String welcome = 'Bienvenido al sistema de verificación biométrica de Vedas Data';
  
  // Habeas Data
  static const String waitForOperator = 'Por favor espere, un asesor le explicará sobre Habeas Data y el tratamiento de sus datos personales';
  static const String operatorWillExplain = 'Un momento por favor, nuestro asesor le atenderá';
  static const String habeasDataAccepted = 'Gracias por aceptar el tratamiento de datos. Continuamos con el registro';
  
  // Términos
  static const String readTerms = 'Por favor, lea los términos y condiciones antes de continuar';
  static const String acceptTerms = 'Acepte los términos para continuar con el registro';
  
  // Escaneo de documento
  static const String scanFront = 'Por favor, ubique el frente de su cédula dentro del marco';
  static const String scanBack = 'Ahora ubique el reverso de su cédula';
  static const String documentCaptured = 'Documento capturado correctamente';
  static const String documentError = 'Error al capturar documento. Intente nuevamente';
  
  // Captura facial
  static const String lookAtCamera = 'Mire directamente a la cámara';
  static const String centerFace = 'Centre su rostro en el círculo';
  static const String holdStill = 'Manténgase quieto';
  static const String countdown3 = 'Tres';
  static const String countdown2 = 'Dos';
  static const String countdown1 = 'Uno';
  static const String faceCaptured = 'Fotografía capturada correctamente';
  static const String faceError = 'Error al capturar rostro. Intente nuevamente';
  
  // Huella dactilar
  static const String placeFinger = 'Coloque su dedo en el lector de huellas';
  static const String holdFinger = 'Mantenga el dedo presionado';
  static const String fingerprintCaptured = 'Huella capturada correctamente';
  static const String fingerprintError = 'Error al capturar huella. Intente nuevamente';
  
  // Validación
  static const String validating = 'Validando su información con la Registraduría Nacional';
  static const String pleaseWait = 'Por favor espere';
  static const String validationSuccess = 'Validación exitosa. Bienvenido';
  static const String validationError = 'No se pudo validar su información. Por favor intente nuevamente';
  
  // Confirmación
  static const String confirmData = 'Por favor confirme sus datos';
  static const String fillFields = 'Complete todos los campos requeridos';
  
  // Resultado
  static const String registrationSuccess = 'Registro completado exitosamente';
  static const String registrationError = 'Error en el registro. Por favor contacte al administrador';
  
  // Errores generales
  static const String cameraError = 'Error al acceder a la cámara';
  static const String connectionError = 'Error de conexión. Verifique su red';
  static const String tryAgain = 'Por favor intente nuevamente';
  
  // Instrucciones
  static const String removeGlasses = 'Por favor retire sus gafas';
  static const String removeHat = 'Por favor retire su gorra o sombrero';
  static const String goodLighting = 'Asegúrese de tener buena iluminación';
  static const String neutralExpression = 'Mantenga una expresión neutral';
}
