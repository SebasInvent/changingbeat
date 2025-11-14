const logger = require('../utils/logger');

/**
 * Servicio MOCK de validación biométrica
 * Simula las respuestas de Apitude para pruebas sin necesidad de API Key
 */
class MockBiometricService {
  constructor() {
    logger.info('🧪 Modo de Pruebas: Usando validación biométrica simulada');
  }

  /**
   * Simular validación de documento con Registraduría
   */
  async validateDocument(documentNumber, expeditionDate) {
    try {
      logger.info(`🧪 [MOCK] Validando documento ${documentNumber}...`);
      
      // Simular delay de API real
      await this._simulateDelay(2000);
      
      // Validación simple: números válidos
      const isValid = documentNumber.length >= 6 && !isNaN(documentNumber);
      
      const mockResponse = {
        success: isValid,
        requestId: this._generateMockId(),
        data: isValid ? {
          name: this._generateMockName(),
          status: 'VIGENTE',
          area: 'CUNDINAMARCA',
          city: 'BOGOTÁ D.C.',
          resolution: '12345',
          date_resolution: expeditionDate
        } : {},
        error: isValid ? null : 'Documento no válido en modo de pruebas',
        message: isValid ? 'Validación simulada exitosa' : 'Error en validación simulada'
      };
      
      logger.info(`✅ [MOCK] Documento validado: ${mockResponse.data.status}`);
      return mockResponse;
      
    } catch (error) {
      logger.error('❌ [MOCK] Error en validación simulada:', error.message);
      return {
        success: false,
        error: error.message,
        data: null
      };
    }
  }

  /**
   * Simular validación biométrica facial
   */
  async validateBiometric({ selfieBase64, frontDocumentBase64, backDocumentBase64, emotion = 'neutral' }) {
    try {
      logger.info('🧪 [MOCK] Iniciando validación biométrica facial simulada...');
      
      // Simular delay de procesamiento de IA
      await this._simulateDelay(3000);
      
      // Validación simple: que las imágenes no estén vacías
      const hasValidImages = selfieBase64 && frontDocumentBase64 && backDocumentBase64;
      const matchScore = hasValidImages ? this._generateMockScore() : 0;
      const isValid = matchScore >= 70; // Umbral de 70%
      
      const mockResponse = {
        success: isValid,
        requestId: this._generateMockId(),
        data: {
          is_same_person: isValid,
          match_score: matchScore,
          liveness_detected: hasValidImages,
          emotion_detected: emotion,
          selfie_valid: !!selfieBase64,
          document_altered: false,
          photo_manipulated: false,
          face_features: {
            age: Math.floor(Math.random() * 40) + 20,
            gender: Math.random() > 0.5 ? 'M' : 'F',
            race: 'latino'
          }
        },
        error: isValid ? null : 'Score de coincidencia muy bajo',
        message: isValid ? 'Validación biométrica simulada exitosa' : 'Validación biométrica simulada fallida'
      };
      
      logger.info(`✅ [MOCK] Validación facial: Score ${matchScore}%`);
      return mockResponse;
      
    } catch (error) {
      logger.error('❌ [MOCK] Error en validación biométrica simulada:', error.message);
      return {
        success: false,
        error: error.message,
        data: null
      };
    }
  }

  /**
   * Validación completa simulada
   */
  async validateComplete({ documentNumber, expeditionDate, selfieBase64, frontDocumentBase64, backDocumentBase64, emotion = 'neutral', includeFingerprintValidation = false }) {
    try {
      logger.info(`🧪 [MOCK] Validación completa simulada para documento ${documentNumber}...`);
      
      // Ejecutar validaciones en paralelo (simulado)
      const validations = [
        this.validateDocument(documentNumber, expeditionDate),
        this.validateBiometric({ selfieBase64, frontDocumentBase64, backDocumentBase64, emotion })
      ];

      // Si se solicita validación de huella, agregarla
      if (includeFingerprintValidation) {
        validations.push(this.validateFingerprint(frontDocumentBase64));
      }

      const results = await Promise.all(validations);
      const [documentResult, biometricResult, fingerprintResult] = results;
      
      const isValid = documentResult.success && biometricResult.success && 
                     (!includeFingerprintValidation || fingerprintResult?.success);
      
      return {
        success: isValid,
        documentValidation: documentResult,
        biometricValidation: biometricResult,
        fingerprintValidation: fingerprintResult || null,
        isFullyValidated: isValid && 
                         documentResult.data?.status === 'VIGENTE' &&
                         biometricResult.data?.is_same_person === true &&
                         (!includeFingerprintValidation || fingerprintResult?.data?.match === true),
        mode: 'MOCK' // Indicador de que es modo prueba
      };
      
    } catch (error) {
      logger.error('❌ [MOCK] Error en validación completa simulada:', error.message);
      return {
        success: false,
        error: error.message,
        mode: 'MOCK'
      };
    }
  }

  /**
   * Simular validación de huella dactilar
   */
  async validateFingerprint(documentImageBase64) {
    try {
      logger.info('🧪 [MOCK] Simulando validación de huella dactilar...');
      
      // Simular delay de captura de huella
      await this._simulateDelay(4000);
      
      const matchScore = this._generateMockScore();
      const isValid = matchScore >= 70;
      
      const mockResponse = {
        success: isValid,
        requestId: this._generateMockId(),
        data: {
          match: isValid,
          matchScore: matchScore,
          fingerprintQuality: Math.floor(Math.random() * 30) + 70, // 70-100
          livenessDetected: true
        },
        error: isValid ? null : 'Score de coincidencia de huella muy bajo',
        message: isValid ? 'Huella validada correctamente' : 'Huella no coincide'
      };
      
      logger.info(`${isValid ? '✅' : '❌'} [MOCK] Validación de huella: ${matchScore}%`);
      return mockResponse;
      
    } catch (error) {
      logger.error('❌ [MOCK] Error en validación de huella simulada:', error.message);
      return {
        success: false,
        error: error.message,
        data: null
      };
    }
  }

  /**
   * Health check simulado
   */
  async healthCheck() {
    return { 
      status: 'ok', 
      message: 'Servicio MOCK activo - Modo de Pruebas',
      mode: 'MOCK'
    };
  }

  /**
   * Simular delay de API
   * @private
   */
  _simulateDelay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  /**
   * Generar ID simulado
   * @private
   */
  _generateMockId() {
    return `MOCK-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }

  /**
   * Generar nombre simulado
   * @private
   */
  _generateMockName() {
    const nombres = [
      'JUAN CARLOS RODRIGUEZ MARTINEZ',
      'MARIA FERNANDA LOPEZ GARCIA',
      'CARLOS ALBERTO GOMEZ PEREZ',
      'ANA MARIA TORRES SANCHEZ',
      'LUIS FERNANDO RAMIREZ CRUZ',
      'PAULA ANDREA CASTRO DIAZ',
      'JORGE EDUARDO RUIZ MORENO',
      'SOFIA VALENTINA ORTIZ SILVA'
    ];
    return nombres[Math.floor(Math.random() * nombres.length)];
  }

  /**
   * Generar score de coincidencia simulado (70-99%)
   * @private
   */
  _generateMockScore() {
    return Math.floor(Math.random() * 30) + 70; // Entre 70 y 99
  }
}

module.exports = new MockBiometricService();
