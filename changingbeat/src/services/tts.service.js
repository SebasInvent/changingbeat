const axios = require('axios');
const logger = require('../utils/logger');
const fs = require('fs');
const path = require('path');

/**
 * Servicio de Text-to-Speech
 * Soporta ElevenLabs API y Google Cloud TTS
 */
class TTSService {
  constructor() {
    this.elevenLabsApiKey = process.env.ELEVENLABS_API_KEY;
    this.elevenLabsVoiceId = process.env.ELEVENLABS_VOICE_ID || 'pNInz6obpgDQGcFmaJgB'; // Voz en español
    this.useElevenLabs = !!this.elevenLabsApiKey;
    
    if (this.useElevenLabs) {
      logger.info('🔊 TTS configurado con ElevenLabs');
    } else {
      logger.info('🔊 TTS no configurado (modo silencioso)');
    }
  }

  /**
   * Generar audio desde texto
   */
  async generateSpeech(text, options = {}) {
    try {
      if (!this.useElevenLabs) {
        logger.warn('⚠️ ElevenLabs no configurado');
        return null;
      }

      logger.info(`🔊 Generando audio: "${text}"`);

      const response = await axios.post(
        `https://api.elevenlabs.io/v1/text-to-speech/${this.elevenLabsVoiceId}`,
        {
          text: text,
          model_id: options.model || 'eleven_multilingual_v2',
          voice_settings: {
            stability: options.stability || 0.5,
            similarity_boost: options.similarityBoost || 0.75,
            style: options.style || 0,
            use_speaker_boost: options.useSpeakerBoost || true
          }
        },
        {
          headers: {
            'Accept': 'audio/mpeg',
            'Content-Type': 'application/json',
            'xi-api-key': this.elevenLabsApiKey
          },
          responseType: 'arraybuffer'
        }
      );

      logger.info('✅ Audio generado exitosamente');
      return response.data;

    } catch (error) {
      logger.error('❌ Error generando audio:', error.message);
      return null;
    }
  }

  /**
   * Generar y guardar audio
   */
  async generateAndSave(text, filename, options = {}) {
    try {
      const audioData = await this.generateSpeech(text, options);
      
      if (!audioData) {
        return null;
      }

      const audioDir = path.join(__dirname, '../../public/audio');
      
      // Crear directorio si no existe
      if (!fs.existsSync(audioDir)) {
        fs.mkdirSync(audioDir, { recursive: true });
      }

      const filepath = path.join(audioDir, filename);
      fs.writeFileSync(filepath, audioData);

      logger.info(`💾 Audio guardado: ${filename}`);
      
      return `/audio/${filename}`;

    } catch (error) {
      logger.error('❌ Error guardando audio:', error.message);
      return null;
    }
  }

  /**
   * Generar audios predefinidos del sistema
   */
  async generateSystemAudios() {
    try {
      logger.info('🎙️ Generando audios del sistema...');

      const messages = {
        'welcome.mp3': 'Bienvenido al sistema de verificación biométrica',
        'scan-front.mp3': 'Por favor, ubique el frente de su cédula dentro del marco',
        'scan-back.mp3': 'Ahora ubique el reverso de su cédula',
        'look-camera.mp3': 'Mire directamente a la cámara',
        'hold-still.mp3': 'Manténgase quieto',
        'countdown-3.mp3': 'Tres',
        'countdown-2.mp3': 'Dos',
        'countdown-1.mp3': 'Uno',
        'validating.mp3': 'Validando su información con la Registraduría Nacional',
        'success.mp3': 'Registro completado exitosamente',
        'error.mp3': 'Error en el proceso. Por favor intente nuevamente',
        'place-finger.mp3': 'Coloque su dedo en el lector de huellas',
        'fingerprint-captured.mp3': 'Huella capturada correctamente'
      };

      const results = [];

      for (const [filename, text] of Object.entries(messages)) {
        const result = await this.generateAndSave(text, filename);
        results.push({ filename, success: !!result });
        
        // Delay para no saturar la API
        await new Promise(resolve => setTimeout(resolve, 500));
      }

      const successCount = results.filter(r => r.success).length;
      logger.info(`✅ Generados ${successCount}/${results.length} audios`);

      return results;

    } catch (error) {
      logger.error('❌ Error generando audios del sistema:', error.message);
      return [];
    }
  }

  /**
   * Obtener voces disponibles
   */
  async getAvailableVoices() {
    try {
      if (!this.useElevenLabs) {
        return [];
      }

      const response = await axios.get(
        'https://api.elevenlabs.io/v1/voices',
        {
          headers: {
            'xi-api-key': this.elevenLabsApiKey
          }
        }
      );

      return response.data.voices;

    } catch (error) {
      logger.error('❌ Error obteniendo voces:', error.message);
      return [];
    }
  }

  /**
   * Health check
   */
  async healthCheck() {
    if (!this.useElevenLabs) {
      return { status: 'disabled', message: 'ElevenLabs no configurado' };
    }

    try {
      await this.getAvailableVoices();
      return { status: 'ok', message: 'ElevenLabs funcionando' };
    } catch (error) {
      return { status: 'error', message: error.message };
    }
  }
}

module.exports = new TTSService();
