# 🔊 Guía de Integración - Text-to-Speech (TTS)

## 🎯 Descripción General

Sistema de voz integrado que guía a los usuarios durante todo el proceso de registro biométrico, mejorando la experiencia de usuario y accesibilidad.

---

## 🌟 Características

### Voces Disponibles

#### 1. **TTS Nativo Android** (Gratis)
- ✅ Incluido en Android
- ✅ No requiere internet
- ✅ Totalmente gratuito
- ✅ Múltiples idiomas
- ⚠️ Calidad variable según dispositivo

#### 2. **ElevenLabs API** (Premium - Opcional)
- ✅ Voces ultra-realistas
- ✅ Soporte español nativo
- ✅ Calidad profesional
- ✅ Emociones y tonos
- ⚠️ Requiere API key
- ⚠️ Plan gratuito: 10,000 caracteres/mes

---

## 🚀 Configuración

### Opción 1: Solo TTS Nativo (Recomendado para Empezar)

**No requiere configuración adicional**. La app usará el TTS del sistema Android automáticamente.

### Opción 2: Con ElevenLabs (Calidad Premium)

#### Paso 1: Obtener API Key

1. Visita: https://elevenlabs.io/
2. Crea una cuenta (plan gratuito disponible)
3. Ve a Settings → API Keys
4. Copia tu API key

#### Paso 2: Configurar Backend

Agrega al archivo `.env`:

```bash
ELEVENLABS_API_KEY=tu_api_key_aqui
ELEVENLABS_VOICE_ID=pNInz6obpgDQGcFmaJgB  # Voz en español
```

#### Paso 3: Configurar Flutter

En `lib/services/tts_service.dart`:

```dart
final String? _elevenLabsApiKey = 'tu_api_key_aqui';
```

---

## 📱 Uso en la App Flutter

### Inicialización

```dart
final TTSService tts = TTSService();
await tts.initialize();
```

### Hablar Texto

```dart
await tts.speak('Bienvenido al sistema');
```

### Usar Mensajes Predefinidos

```dart
await tts.speak(TTSMessages.welcome);
await tts.speak(TTSMessages.scanFront);
await tts.speak(TTSMessages.lookAtCamera);
```

### Control de Reproducción

```dart
// Detener
await tts.stop();

// Pausar
await tts.pause();

// Configurar velocidad (0.0 - 1.0)
await tts.setSpeechRate(0.5);

// Configurar volumen (0.0 - 1.0)
await tts.setVolume(1.0);

// Configurar tono (0.5 - 2.0)
await tts.setPitch(1.0);
```

---

## 🎙️ Mensajes del Sistema

### Bienvenida
- `TTSMessages.welcome` - "Bienvenido al sistema de verificación biométrica"

### Términos
- `TTSMessages.readTerms` - "Por favor, lea los términos y condiciones"
- `TTSMessages.acceptTerms` - "Acepte los términos para continuar"

### Escaneo de Documento
- `TTSMessages.scanFront` - "Ubique el frente de su cédula dentro del marco"
- `TTSMessages.scanBack` - "Ahora ubique el reverso de su cédula"
- `TTSMessages.documentCaptured` - "Documento capturado correctamente"

### Captura Facial
- `TTSMessages.lookAtCamera` - "Mire directamente a la cámara"
- `TTSMessages.centerFace` - "Centre su rostro en el círculo"
- `TTSMessages.holdStill` - "Manténgase quieto"
- `TTSMessages.countdown3` - "Tres"
- `TTSMessages.countdown2` - "Dos"
- `TTSMessages.countdown1` - "Uno"
- `TTSMessages.faceCaptured` - "Fotografía capturada correctamente"

### Huella Dactilar
- `TTSMessages.placeFinger` - "Coloque su dedo en el lector"
- `TTSMessages.holdFinger` - "Mantenga el dedo presionado"
- `TTSMessages.fingerprintCaptured` - "Huella capturada correctamente"

### Validación
- `TTSMessages.validating` - "Validando con la Registraduría Nacional"
- `TTSMessages.pleaseWait` - "Por favor espere"
- `TTSMessages.validationSuccess` - "Validación exitosa. Bienvenido"

### Resultados
- `TTSMessages.registrationSuccess` - "Registro completado exitosamente"
- `TTSMessages.registrationError` - "Error en el registro"

### Errores
- `TTSMessages.cameraError` - "Error al acceder a la cámara"
- `TTSMessages.connectionError` - "Error de conexión"
- `TTSMessages.tryAgain` - "Por favor intente nuevamente"

---

## 🎨 Integración en Pantallas

### WelcomeScreen

```dart
class _WelcomeScreenState extends State<WelcomeScreen> {
  final TTSService _tts = TTSService();
  
  @override
  void initState() {
    super.initState();
    _initializeTTS();
  }
  
  Future<void> _initializeTTS() async {
    await _tts.initialize();
    await _tts.speak(TTSMessages.welcome);
  }
  
  @override
  void dispose() {
    _tts.dispose();
    super.dispose();
  }
}
```

### DocumentScanScreen

```dart
Future<void> _captureDocument(bool isFront) async {
  // Instrucción de voz
  await _tts.speak(
    isFront ? TTSMessages.scanFront : TTSMessages.scanBack
  );
  
  // Capturar imagen
  final image = await _cameraService.captureImage();
  
  if (image != null) {
    await _tts.speak(TTSMessages.documentCaptured);
  } else {
    await _tts.speak(TTSMessages.documentError);
  }
}
```

### FacialCaptureScreen

```dart
Future<void> _startCountdown() async {
  await _tts.speak(TTSMessages.lookAtCamera);
  await Future.delayed(Duration(seconds: 1));
  
  await _tts.speak(TTSMessages.countdown3);
  await Future.delayed(Duration(seconds: 1));
  
  await _tts.speak(TTSMessages.countdown2);
  await Future.delayed(Duration(seconds: 1));
  
  await _tts.speak(TTSMessages.countdown1);
  await Future.delayed(Duration(seconds: 1));
  
  // Capturar
  await _capturePhoto();
}
```

---

## 🔧 Backend - Generación de Audios

### Generar Audio desde Texto

```javascript
const ttsService = require('./src/services/tts.service');

// Generar audio
const audioData = await ttsService.generateSpeech('Hola mundo');

// Generar y guardar
const audioUrl = await ttsService.generateAndSave(
  'Bienvenido',
  'welcome.mp3'
);
```

### Generar Audios del Sistema

```javascript
// Genera todos los audios predefinidos
await ttsService.generateSystemAudios();
```

Esto crea archivos MP3 en `public/audio/`:
- `welcome.mp3`
- `scan-front.mp3`
- `scan-back.mp3`
- `look-camera.mp3`
- etc.

### Servir Audios Pre-generados

```javascript
// En la app Flutter, descargar y reproducir
final url = '$baseUrl/audio/welcome.mp3';
await _audioPlayer.play(UrlSource(url));
```

---

## 🎛️ Configuración Avanzada

### Personalizar Voz de ElevenLabs

```dart
// En tts_service.dart
final String _elevenLabsVoiceId = 'voice_id_aqui';
```

**Voces en Español Disponibles:**
- `pNInz6obpgDQGcFmaJgB` - Adam (Masculina)
- `EXAVITQu4vr4xnSDxMaL` - Bella (Femenina)
- `ErXwobaYiN019PkySvjV` - Antoni (Masculina)

### Ajustar Parámetros de Voz

```javascript
// Backend
await ttsService.generateSpeech('Texto', {
  stability: 0.5,        // 0-1 (más estable = menos variación)
  similarityBoost: 0.75, // 0-1 (más alto = más similar a la voz original)
  style: 0,              // 0-1 (intensidad del estilo)
  useSpeakerBoost: true  // Mejorar claridad
});
```

---

## 📊 Flujo Completo con Voz

```
Usuario llega a la tablet
    ↓
🔊 "Bienvenido al sistema de verificación biométrica"
    ↓
Pantalla de Términos
    ↓
🔊 "Por favor, lea los términos y condiciones"
    ↓
Usuario acepta
    ↓
Escaneo de Documento
    ↓
🔊 "Ubique el frente de su cédula dentro del marco"
    ↓
Captura frente
    ↓
🔊 "Documento capturado correctamente"
    ↓
🔊 "Ahora ubique el reverso"
    ↓
Captura reverso
    ↓
Captura Facial
    ↓
🔊 "Mire directamente a la cámara"
    ↓
🔊 "Tres, Dos, Uno"
    ↓
Captura selfie
    ↓
🔊 "Fotografía capturada correctamente"
    ↓
[OPCIONAL] Huella Dactilar
    ↓
🔊 "Coloque su dedo en el lector"
    ↓
Captura huella
    ↓
🔊 "Huella capturada correctamente"
    ↓
Validación
    ↓
🔊 "Validando su información con la Registraduría Nacional"
    ↓
Resultado
    ↓
🔊 "Registro completado exitosamente"
```

---

## 💰 Costos

### TTS Nativo Android
- **Costo**: $0 (Gratis)
- **Límite**: Ilimitado
- **Calidad**: Media

### ElevenLabs

**Plan Gratuito:**
- 10,000 caracteres/mes
- ~200 mensajes del sistema
- Perfecto para pruebas

**Plan Starter ($5/mes):**
- 30,000 caracteres/mes
- ~600 mensajes

**Plan Creator ($22/mes):**
- 100,000 caracteres/mes
- ~2,000 mensajes

**Estimación:**
- Promedio por registro: ~50 caracteres
- 10,000 caracteres = ~200 registros/mes (plan gratuito)

---

## 🔒 Privacidad y Seguridad

### Datos Enviados a ElevenLabs
- Solo el texto a convertir
- NO se envían datos personales
- NO se envían imágenes
- NO se almacena información del usuario

### Recomendaciones
- Usar mensajes genéricos
- No incluir números de documento en TTS
- No incluir nombres en mensajes de voz
- Mantener API key segura

---

## 🐛 Troubleshooting

### TTS No Funciona en Android

**Problema**: No se escucha voz

**Soluciones**:
1. Verificar volumen del dispositivo
2. Verificar que TTS esté instalado en Android
3. Ir a Configuración → Idioma → Text-to-Speech
4. Instalar voces en español si es necesario

### ElevenLabs Retorna Error

**Problema**: Error 401 Unauthorized

**Solución**: Verificar API key en `.env`

**Problema**: Error 429 Too Many Requests

**Solución**: Límite de caracteres alcanzado, esperar o actualizar plan

### Audio Se Corta

**Problema**: TTS se detiene antes de terminar

**Solución**:
```dart
// Esperar a que termine de hablar
await _tts.speak(text);
await Future.delayed(Duration(seconds: 2));
```

---

## 🚀 Mejoras Futuras

### Corto Plazo
- [ ] Selección de idioma (español/inglés)
- [ ] Velocidad de voz ajustable por usuario
- [ ] Modo silencioso opcional

### Mediano Plazo
- [ ] Voces personalizadas por ubicación
- [ ] Detección de idioma automática
- [ ] Subtítulos sincronizados con voz

### Largo Plazo
- [ ] Conversación bidireccional (Speech-to-Text)
- [ ] Comandos de voz
- [ ] Asistente virtual completo

---

## 📞 Recursos

### Documentación
- **Flutter TTS**: https://pub.dev/packages/flutter_tts
- **ElevenLabs**: https://docs.elevenlabs.io/
- **Audioplayers**: https://pub.dev/packages/audioplayers

### Voces de Prueba
- **ElevenLabs Voice Lab**: https://elevenlabs.io/voice-lab
- **Probar voces**: https://elevenlabs.io/text-to-speech

### Alternativas Open Source
- **Piper TTS**: https://github.com/rhasspy/piper
- **Coqui TTS**: https://github.com/coqui-ai/TTS
- **Mozilla TTS**: https://github.com/mozilla/TTS

---

**Versión**: 1.0.0  
**Fecha**: Noviembre 2024  
**Estado**: Listo para Producción ✅
