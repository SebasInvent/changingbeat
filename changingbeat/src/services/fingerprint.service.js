const { SerialPort } = require('serialport');
const logger = require('../utils/logger');
const EventEmitter = require('events');

/**
 * Servicio de Lector de Huellas Dactilares USB
 * Maneja la captura y comparación de huellas dactilares
 */
class FingerprintService extends EventEmitter {
  constructor() {
    super();
    this.port = null;
    this.isConnected = false;
    this.currentFingerprint = null;
    this.fingerprintBuffer = [];
  }

  /**
   * Inicializar conexión con el lector de huellas
   */
  async initialize(portPath = 'COM3', baudRate = 9600) {
    try {
      logger.info(`🔌 Inicializando lector de huellas en ${portPath}...`);
      
      this.port = new SerialPort({
        path: portPath,
        baudRate: baudRate,
        dataBits: 8,
        parity: 'none',
        stopBits: 1,
        flowControl: false
      });

      this.port.on('open', () => {
        this.isConnected = true;
        logger.info('✅ Lector de huellas conectado');
        this.emit('connected');
      });

      this.port.on('data', (data) => {
        this.handleFingerprintData(data);
      });

      this.port.on('error', (err) => {
        logger.error('❌ Error en lector de huellas:', err.message);
        this.isConnected = false;
        this.emit('error', err);
      });

      this.port.on('close', () => {
        this.isConnected = false;
        logger.warn('⚠️  Lector de huellas desconectado');
        this.emit('disconnected');
      });

      return true;
    } catch (error) {
      logger.error('❌ Error inicializando lector de huellas:', error.message);
      return false;
    }
  }

  /**
   * Procesar datos del lector de huellas
   * @private
   */
  handleFingerprintData(data) {
    try {
      // Acumular datos en buffer
      this.fingerprintBuffer.push(...data);
      
      // Verificar si tenemos un paquete completo
      // (esto depende del protocolo de tu lector específico)
      if (this.fingerprintBuffer.length >= 512) { // Tamaño típico de template
        const fingerprintData = Buffer.from(this.fingerprintBuffer);
        this.fingerprintBuffer = [];
        
        logger.info('👆 Huella capturada del lector USB');
        this.currentFingerprint = fingerprintData;
        this.emit('fingerprint-captured', fingerprintData);
      }
    } catch (error) {
      logger.error('❌ Error procesando datos de huella:', error.message);
    }
  }

  /**
   * Capturar huella dactilar del lector USB
   * Espera a que el usuario coloque el dedo
   */
  async captureFingerprint(timeoutMs = 30000) {
    return new Promise((resolve, reject) => {
      if (!this.isConnected) {
        return reject(new Error('Lector de huellas no conectado'));
      }

      logger.info('👆 Esperando huella en el lector...');
      
      const timeout = setTimeout(() => {
        this.removeAllListeners('fingerprint-captured');
        reject(new Error('Timeout esperando huella'));
      }, timeoutMs);

      this.once('fingerprint-captured', (fingerprintData) => {
        clearTimeout(timeout);
        resolve(fingerprintData);
      });

      // Enviar comando al lector para iniciar captura
      this.sendCaptureCommand();
    });
  }

  /**
   * Enviar comando al lector para capturar huella
   * @private
   */
  sendCaptureCommand() {
    if (!this.port || !this.isConnected) return;
    
    // Comando genérico para iniciar captura
    // Esto varía según el modelo del lector
    const command = Buffer.from([0x01, 0x00, 0x00, 0x00]);
    
    this.port.write(command, (err) => {
      if (err) {
        logger.error('❌ Error enviando comando de captura:', err.message);
      }
    });
  }

  /**
   * Extraer huella de imagen de cédula (simulado)
   * En producción, usarías un servicio de OCR/procesamiento de imagen
   */
  async extractFingerprintFromDocument(documentImageBase64) {
    try {
      logger.info('🔍 Extrayendo huella de imagen de cédula...');
      
      // SIMULACIÓN: En la realidad necesitarías:
      // 1. Procesar la imagen con OpenCV o similar
      // 2. Detectar la zona de la huella en la cédula
      // 3. Extraer y convertir a template biométrico
      
      // Por ahora, generamos un template simulado basado en la imagen
      const mockTemplate = this.generateMockFingerprintTemplate(documentImageBase64);
      
      logger.info('✅ Huella extraída de cédula (simulado)');
      return mockTemplate;
      
    } catch (error) {
      logger.error('❌ Error extrayendo huella de documento:', error.message);
      throw error;
    }
  }

  /**
   * Comparar dos huellas dactilares
   * Retorna score de coincidencia (0-100)
   */
  async compareFingerprints(fingerprint1, fingerprint2) {
    try {
      logger.info('🔄 Comparando huellas dactilares...');
      
      // SIMULACIÓN: En producción usarías un algoritmo real como:
      // - NIST BOZORTH3
      // - SourceAFIS
      // - Neurotechnology MegaMatcher
      
      const score = this.calculateMatchScore(fingerprint1, fingerprint2);
      
      const isMatch = score >= 70; // Umbral de 70%
      
      logger.info(`${isMatch ? '✅' : '❌'} Comparación: ${score}% de coincidencia`);
      
      return {
        match: isMatch,
        score: score,
        threshold: 70
      };
      
    } catch (error) {
      logger.error('❌ Error comparando huellas:', error.message);
      throw error;
    }
  }

  /**
   * Calcular score de coincidencia (simulado)
   * @private
   */
  calculateMatchScore(fp1, fp2) {
    // SIMULACIÓN: Genera un score aleatorio entre 60-95%
    // En producción, esto sería un algoritmo de matching real
    
    if (!fp1 || !fp2) return 0;
    
    // Simular que huellas similares tienen score alto
    const baseScore = 75;
    const variation = Math.random() * 20 - 10; // ±10%
    
    return Math.min(100, Math.max(0, Math.floor(baseScore + variation)));
  }

  /**
   * Generar template de huella simulado
   * @private
   */
  generateMockFingerprintTemplate(imageBase64) {
    // Generar un buffer basado en hash de la imagen
    const hash = require('crypto')
      .createHash('sha256')
      .update(imageBase64.substring(0, 1000)) // Usar parte de la imagen
      .digest();
    
    return hash;
  }

  /**
   * Validación completa: Capturar huella USB y comparar con cédula
   */
  async validateFingerprintWithDocument(documentImageBase64) {
    try {
      logger.info('🔐 Iniciando validación de huella con documento...');
      
      // 1. Extraer huella de la imagen de la cédula
      const documentFingerprint = await this.extractFingerprintFromDocument(documentImageBase64);
      
      // 2. Capturar huella del lector USB
      logger.info('👆 Por favor, coloque su dedo en el lector...');
      const liveFingerprint = await this.captureFingerprint();
      
      // 3. Comparar ambas huellas
      const comparison = await this.compareFingerprints(documentFingerprint, liveFingerprint);
      
      return {
        success: comparison.match,
        matchScore: comparison.score,
        threshold: comparison.threshold,
        message: comparison.match 
          ? 'Huella verificada correctamente' 
          : 'Las huellas no coinciden'
      };
      
    } catch (error) {
      logger.error('❌ Error en validación de huella:', error.message);
      return {
        success: false,
        matchScore: 0,
        error: error.message
      };
    }
  }

  /**
   * Listar puertos seriales disponibles
   */
  static async listAvailablePorts() {
    try {
      const ports = await SerialPort.list();
      logger.info('📋 Puertos disponibles:');
      ports.forEach(port => {
        logger.info(`  - ${port.path}: ${port.manufacturer || 'Unknown'}`);
      });
      return ports;
    } catch (error) {
      logger.error('❌ Error listando puertos:', error.message);
      return [];
    }
  }

  /**
   * Cerrar conexión con el lector
   */
  async disconnect() {
    if (this.port && this.isConnected) {
      return new Promise((resolve) => {
        this.port.close(() => {
          this.isConnected = false;
          logger.info('🔌 Lector de huellas desconectado');
          resolve();
        });
      });
    }
  }

  /**
   * Verificar si el lector está conectado
   */
  isReady() {
    return this.isConnected;
  }
}

module.exports = new FingerprintService();
