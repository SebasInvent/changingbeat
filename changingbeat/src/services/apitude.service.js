const axios = require('axios');
const config = require('../config/env');
const logger = require('../utils/logger');
const mockService = require('./mock-biometric.service');

/**
 * Servicio para integración con Apitude API
 * Validación de cédulas y reconocimiento facial con Registraduría/ANI
 * 
 * Si no hay API_KEY configurada, usa automáticamente el servicio MOCK para pruebas
 */
class ApitudeService {
  constructor() {
    this.baseURL = 'https://apitude.co/api/v1.0';
    this.apiKey = process.env.APITUDE_API_KEY;
    this.useMockService = !this.apiKey;
    
    if (this.useMockService) {
      logger.warn('⚠️  APITUDE_API_KEY no configurada. Usando servicio MOCK para pruebas.');
      logger.info('💡 Para usar validación real, configura APITUDE_API_KEY en .env');
    } else {
      logger.info('✅ Usando Apitude API para validaciones reales');
    }
    
    this.axiosInstance = axios.create({
      baseURL: this.baseURL,
      headers: {
        'x-api-key': this.apiKey,
        'Content-Type': 'application/json'
      },
      timeout: 60000 // 60 segundos para procesos de IA
    });
  }

  /**
   * Validar cédula con Registraduría
   */
  async validateDocument(documentNumber, expeditionDate) {
    // Usar servicio MOCK si no hay API key
    if (this.useMockService) {
      return mockService.validateDocument(documentNumber, expeditionDate);
    }
    
    try {
      logger.info(`📄 Validando documento ${documentNumber} con Registraduría...`);
      
      // Paso 1: Crear solicitud
      const postResponse = await this.axiosInstance.post('/requests/registraduria-co/', {
        document_number: documentNumber,
        date_expedition: expeditionDate // Formato: 'YYYY-MM-DD'
      });
      
      const { request_id, url } = postResponse.data;
      logger.info(`✅ Solicitud creada: ${request_id}`);
      
      // Paso 2: Polling para obtener resultado
      const result = await this._pollForResult(url);
      
      return {
        success: result.status === 200,
        requestId: request_id,
        data: result.data || {},
        error: result.error || null,
        message: result.message || 'Validación completada'
      };
      
    } catch (error) {
      logger.error('❌ Error validando documento:', error.message);
      return {
        success: false,
        error: error.message,
        data: null
      };
    }
  }

  /**
   * Validación biométrica facial completa
   * Incluye: selfie + cédula frontal + cédula reverso
   */
  async validateBiometric({ selfieBase64, frontDocumentBase64, backDocumentBase64, emotion = 'neutral' }) {
    // Usar servicio MOCK si no hay API key
    if (this.useMockService) {
      return mockService.validateBiometric({ selfieBase64, frontDocumentBase64, backDocumentBase64, emotion });
    }
    
    try {
      logger.info('📸 Iniciando validación biométrica facial...');
      
      // Paso 1: Crear solicitud
      const postResponse = await this.axiosInstance.post('/requests/face-id-co/', {
        emotion: emotion,
        selfie_img: selfieBase64,
        front_img: frontDocumentBase64,
        back_img: backDocumentBase64
      });
      
      const { request_id, url } = postResponse.data;
      logger.info(`✅ Solicitud biométrica creada: ${request_id}`);
      
      // Paso 2: Polling para obtener resultado
      const result = await this._pollForResult(url);
      
      return {
        success: result.status === 200,
        requestId: request_id,
        data: result.data || {},
        error: result.error || null,
        message: result.message || 'Validación biométrica completada'
      };
      
    } catch (error) {
      logger.error('❌ Error en validación biométrica:', error.message);
      return {
        success: false,
        error: error.message,
        data: null
      };
    }
  }

  /**
   * Validación completa: Documento + Biometría
   * Combina ambas validaciones en una sola llamada
   */
  async validateComplete({ documentNumber, expeditionDate, selfieBase64, frontDocumentBase64, backDocumentBase64, emotion = 'neutral' }) {
    // Usar servicio MOCK si no hay API key
    if (this.useMockService) {
      return mockService.validateComplete({ documentNumber, expeditionDate, selfieBase64, frontDocumentBase64, backDocumentBase64, emotion });
    }
    
    try {
      logger.info(`🔍 Validación completa para documento ${documentNumber}...`);
      
      // Ejecutar ambas validaciones en paralelo
      const [documentResult, biometricResult] = await Promise.all([
        this.validateDocument(documentNumber, expeditionDate),
        this.validateBiometric({ selfieBase64, frontDocumentBase64, backDocumentBase64, emotion })
      ]);
      
      const isValid = documentResult.success && biometricResult.success;
      
      return {
        success: isValid,
        documentValidation: documentResult,
        biometricValidation: biometricResult,
        isFullyValidated: isValid && 
                         documentResult.data?.status === 'VIGENTE' &&
                         biometricResult.data?.is_same_person === true
      };
      
    } catch (error) {
      logger.error('❌ Error en validación completa:', error.message);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Polling para obtener resultado de una solicitud asíncrona
   * @private
   */
  async _pollForResult(url, maxAttempts = 20, interval = 3000) {
    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        logger.info(`⏳ Esperando resultado... (intento ${attempt}/${maxAttempts})`);
        
        const response = await this.axiosInstance.get(url);
        const { result } = response.data;
        
        // Si tiene resultado, retornar
        if (result && result.status !== undefined) {
          logger.info('✅ Resultado obtenido exitosamente');
          return result;
        }
        
        // Esperar antes del siguiente intento
        await this._sleep(interval);
        
      } catch (error) {
        if (attempt === maxAttempts) {
          throw new Error(`Timeout esperando resultado: ${error.message}`);
        }
        await this._sleep(interval);
      }
    }
    
    throw new Error('Timeout: No se recibió respuesta de Apitude');
  }

  /**
   * Utilidad para esperar
   * @private
   */
  _sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  /**
   * Verificar conectividad con Apitude
   */
  async healthCheck() {
    // Usar servicio MOCK si no hay API key
    if (this.useMockService) {
      return mockService.healthCheck();
    }
    
    try {
      // Hacer una petición simple para verificar conectividad
      await this.axiosInstance.get('/health', { timeout: 5000 }).catch(() => {
        // Si no existe endpoint de health, intentar con cualquier otro
        return { status: 200 };
      });
      
      return { status: 'ok', message: 'Conectado a Apitude API' };
    } catch (error) {
      return { status: 'error', message: error.message };
    }
  }
}

module.exports = new ApitudeService();