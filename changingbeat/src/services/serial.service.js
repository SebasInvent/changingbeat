const { SerialPort } = require('serialport');
const config = require('../config/env');
const logger = require('../utils/logger');
const { MRZ_TYPES } = require('../config/constants');

/**
 * Servicio de Lectura de Cédulas por Puerto Serial
 */
class SerialService {
  constructor() {
    this.port = null;
    this.isConnected = false;
    this.callbacks = {
      onData: null,
      onError: null,
      onOpen: null,
      onClose: null
    };
  }

  /**
   * Inicializar puerto serial
   */
  async initialize() {
    try {
      if (this.isConnected) {
        logger.warn('Puerto serial ya está conectado');
        return;
      }

      this.port = new SerialPort({
        path: config.serialPort.path,
        baudRate: config.serialPort.baudRate,
        autoOpen: false
      });

      // Configurar event handlers
      this.setupEventHandlers();

      // Abrir puerto
      await this.open();

      logger.info('Puerto serial inicializado', {
        path: config.serialPort.path,
        baudRate: config.serialPort.baudRate
      });
    } catch (error) {
      logger.error('Error inicializando puerto serial:', error);
      throw error;
    }
  }

  /**
   * Configurar manejadores de eventos
   */
  setupEventHandlers() {
    // Datos recibidos
    this.port.on('data', (data) => {
      try {
        const mrzData = data.toString().trim();
        logger.debug('Datos MRZ recibidos', { length: mrzData.length });
        
        const parsedData = this.decodeMRZ(mrzData);
        
        if (this.callbacks.onData) {
          this.callbacks.onData(parsedData);
        }
      } catch (error) {
        logger.error('Error procesando datos del puerto:', error);
        if (this.callbacks.onError) {
          this.callbacks.onError(error);
        }
      }
    });

    // Error
    this.port.on('error', (err) => {
      logger.error('Error en puerto serial:', err);
      this.isConnected = false;
      
      if (this.callbacks.onError) {
        this.callbacks.onError(err);
      }
    });

    // Puerto abierto
    this.port.on('open', () => {
      this.isConnected = true;
      logger.info('Puerto serial abierto');
      
      if (this.callbacks.onOpen) {
        this.callbacks.onOpen();
      }
    });

    // Puerto cerrado
    this.port.on('close', () => {
      this.isConnected = false;
      logger.info('Puerto serial cerrado');
      
      if (this.callbacks.onClose) {
        this.callbacks.onClose();
      }
    });
  }

  /**
   * Abrir puerto serial
   */
  async open() {
    return new Promise((resolve, reject) => {
      if (!this.port) {
        return reject(new Error('Puerto no inicializado'));
      }

      this.port.open((err) => {
        if (err) {
          logger.error('Error abriendo puerto serial:', err);
          return reject(err);
        }
        resolve();
      });
    });
  }

  /**
   * Cerrar puerto serial
   */
  async close() {
    return new Promise((resolve, reject) => {
      if (!this.port || !this.isConnected) {
        return resolve();
      }

      this.port.close((err) => {
        if (err) {
          logger.error('Error cerrando puerto serial:', err);
          return reject(err);
        }
        this.isConnected = false;
        resolve();
      });
    });
  }

  /**
   * Detectar tipo de MRZ
   */
  detectMRZType(data) {
    const lines = data.split('\n').filter(line => line.length > 0);

    if (lines.length === 3 && lines.every(line => line.length === 30)) {
      return MRZ_TYPES.TD1;
    }

    if (lines.length === 2 && lines.every(line => line.length === 44)) {
      return MRZ_TYPES.TD3;
    }

    if (lines.length === 2 && lines.every(line => line.length === 36)) {
      return MRZ_TYPES.TD2;
    }

    return null;
  }

  /**
   * Decodificar datos MRZ
   */
  decodeMRZ(data) {
    const mrzType = this.detectMRZType(data);

    if (!mrzType) {
      logger.warn('Tipo de MRZ no reconocido');
      return {
        success: false,
        error: 'Formato MRZ no válido',
        rawData: data
      };
    }

    logger.info(`MRZ tipo ${mrzType} detectado`);

    switch (mrzType) {
      case MRZ_TYPES.TD1:
        return this.parseMRZ_TD1(data);
      case MRZ_TYPES.TD3:
        return this.parseMRZ_TD3(data);
      case MRZ_TYPES.TD2:
        return this.parseMRZ_TD2(data);
      default:
        return {
          success: false,
          error: 'Tipo MRZ no soportado',
          rawData: data
        };
    }
  }

  /**
   * Parsear MRZ TD1 (Cédulas - 3 líneas de 30 caracteres)
   */
  parseMRZ_TD1(data) {
    try {
      const lines = data.split('\n');
      
      // Línea 1: Tipo de documento, país emisor, número de documento
      const line1 = lines[0] || '';
      const documentNumber = this.extractField(line1, 5, 14).replace(/</g, '');
      
      // Línea 2: Fecha de nacimiento, sexo, fecha de expiración
      const line2 = lines[1] || '';
      const birthDate = this.extractField(line2, 0, 6);
      const sex = this.extractField(line2, 7, 8);
      const expiryDate = this.extractField(line2, 8, 14);
      
      // Línea 3: Apellidos << Nombres
      const line3 = lines[2] || '';
      const nameParts = this.parseName(line3);

      logger.info('MRZ TD1 parseado', { documentNumber });

      return {
        success: true,
        type: MRZ_TYPES.TD1,
        documentNumber,
        birthDate: this.formatDate(birthDate),
        sex,
        expiryDate: this.formatDate(expiryDate),
        lastName: nameParts.lastName,
        firstName: nameParts.firstName,
        rawData: data
      };
    } catch (error) {
      logger.error('Error parseando MRZ TD1:', error);
      return {
        success: false,
        error: error.message,
        rawData: data
      };
    }
  }

  /**
   * Parsear MRZ TD3 (Pasaportes - 2 líneas de 44 caracteres)
   */
  parseMRZ_TD3(data) {
    try {
      const lines = data.split('\n');
      
      // Línea 1: Tipo, país, apellidos << nombres
      const line1 = lines[0] || '';
      const nameParts = this.parseName(line1.substring(5));
      
      // Línea 2: Número de pasaporte, nacionalidad, fecha nacimiento, sexo, expiración
      const line2 = lines[1] || '';
      const documentNumber = this.extractField(line2, 0, 9).replace(/</g, '');
      const nationality = this.extractField(line2, 10, 13);
      const birthDate = this.extractField(line2, 13, 19);
      const sex = this.extractField(line2, 20, 21);
      const expiryDate = this.extractField(line2, 21, 27);

      logger.info('MRZ TD3 parseado', { documentNumber });

      return {
        success: true,
        type: MRZ_TYPES.TD3,
        documentNumber,
        nationality,
        birthDate: this.formatDate(birthDate),
        sex,
        expiryDate: this.formatDate(expiryDate),
        lastName: nameParts.lastName,
        firstName: nameParts.firstName,
        rawData: data
      };
    } catch (error) {
      logger.error('Error parseando MRZ TD3:', error);
      return {
        success: false,
        error: error.message,
        rawData: data
      };
    }
  }

  /**
   * Parsear MRZ TD2 (2 líneas de 36 caracteres)
   */
  parseMRZ_TD2(data) {
    try {
      const lines = data.split('\n');
      
      const line1 = lines[0] || '';
      const line2 = lines[1] || '';
      
      const documentNumber = this.extractField(line1, 5, 14).replace(/</g, '');
      const nameParts = this.parseName(line1.substring(14));
      const birthDate = this.extractField(line2, 0, 6);
      const sex = this.extractField(line2, 7, 8);
      const expiryDate = this.extractField(line2, 8, 14);

      logger.info('MRZ TD2 parseado', { documentNumber });

      return {
        success: true,
        type: MRZ_TYPES.TD2,
        documentNumber,
        birthDate: this.formatDate(birthDate),
        sex,
        expiryDate: this.formatDate(expiryDate),
        lastName: nameParts.lastName,
        firstName: nameParts.firstName,
        rawData: data
      };
    } catch (error) {
      logger.error('Error parseando MRZ TD2:', error);
      return {
        success: false,
        error: error.message,
        rawData: data
      };
    }
  }

  /**
   * Extraer campo de texto
   */
  extractField(line, start, end) {
    return (line.substring(start, end) || '').trim();
  }

  /**
   * Parsear nombres desde formato MRZ (APELLIDO<<NOMBRE)
   */
  parseName(nameField) {
    const parts = nameField.split('<<');
    const lastName = (parts[0] || '').replace(/</g, ' ').trim();
    const firstName = (parts[1] || '').replace(/</g, ' ').trim();

    return { lastName, firstName };
  }

  /**
   * Formatear fecha desde formato MRZ (YYMMDD) a ISO (YYYY-MM-DD)
   */
  formatDate(dateStr) {
    if (!dateStr || dateStr.length !== 6) {
      return null;
    }

    const year = parseInt(dateStr.substring(0, 2));
    const month = dateStr.substring(2, 4);
    const day = dateStr.substring(4, 6);

    // Asumir que años < 30 son 20XX, >= 30 son 19XX
    const fullYear = year < 30 ? `20${year}` : `19${year}`;

    return `${fullYear}-${month}-${day}`;
  }

  /**
   * Registrar callback para datos
   */
  onData(callback) {
    this.callbacks.onData = callback;
  }

  /**
   * Registrar callback para errores
   */
  onError(callback) {
    this.callbacks.onError = callback;
  }

  /**
   * Registrar callback para apertura
   */
  onOpen(callback) {
    this.callbacks.onOpen = callback;
  }

  /**
   * Registrar callback para cierre
   */
  onClose(callback) {
    this.callbacks.onClose = callback;
  }

  /**
   * Obtener estado de la conexión
   */
  getStatus() {
    return {
      connected: this.isConnected,
      port: config.serialPort.path,
      baudRate: config.serialPort.baudRate
    };
  }
}

module.exports = new SerialService();
