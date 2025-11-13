const { BiometricRegistration } = require('../models');
const apitudeService = require('../services/apitude.service');
const logger = require('../utils/logger');

/**
 * Controlador de Registros Biométricos
 */
class BiometricController {
  
  /**
   * Crear nuevo registro biométrico
   * POST /api/v1/biometric/register
   */
  async register(req, res) {
    try {
      const {
        documentNumber,
        documentType,
        expeditionDate,
        selfieBase64,
        frontDocumentBase64,
        backDocumentBase64,
        termsAccepted,
        phone,
        eps,
        arl,
        deviceInfo,
        tabletInfo,
        emotion
      } = req.body;

      logger.info(`📝 Iniciando registro biométrico para documento: ${documentNumber}`);

      // Validar que aceptó términos
      if (!termsAccepted) {
        return res.status(400).json({
          success: false,
          message: 'Debe aceptar los términos y condiciones'
        });
      }

      // Verificar si ya existe registro
      const existingRecord = await BiometricRegistration.findByDocument(documentNumber, documentType);
      if (existingRecord && existingRecord.status === 'VALIDATED') {
        return res.status(409).json({
          success: false,
          message: 'Ya existe un registro validado para este documento',
          data: { registrationId: existingRecord._id }
        });
      }

      // Verificar si se debe incluir validación de huella
      const includeFingerprintValidation = req.body.includeFingerprintValidation || false;

      // Realizar validación completa con Apitude (o MOCK)
      const validationResult = await apitudeService.validateComplete({
        documentNumber,
        expeditionDate,
        selfieBase64,
        frontDocumentBase64,
        backDocumentBase64,
        emotion: emotion || 'neutral',
        includeFingerprintValidation
      });

      // Extraer datos de las validaciones
      const docValidation = validationResult.documentValidation;
      const bioValidation = validationResult.biometricValidation;
      const fingerprintValidation = validationResult.fingerprintValidation;

      // Crear registro en BD
      const registration = new BiometricRegistration({
        documentNumber,
        documentType: documentType || 'CC',
        expeditionDate: new Date(expeditionDate),
        
        personalInfo: {
          fullName: docValidation.data?.name,
          phone: phone,
          eps: eps,
          arl: arl
        },
        
        registraduriaValidation: {
          isValid: docValidation.success,
          status: docValidation.data?.status || 'ERROR',
          validatedAt: new Date(),
          validationData: {
            area: docValidation.data?.area,
            city: docValidation.data?.city,
            resolution: docValidation.data?.resolution,
            dateResolution: docValidation.data?.date_resolution
          },
          requestId: docValidation.requestId,
          errorMessage: docValidation.error
        },
        
        facialVerification: {
          isValid: bioValidation.success,
          matchScore: bioValidation.data?.match_score,
          livenessDetected: bioValidation.data?.liveness_detected,
          emotionDetected: bioValidation.data?.emotion_detected,
          validatedAt: new Date(),
          requestId: bioValidation.requestId,
          errorMessage: bioValidation.error
        },
        
        images: {
          frontDocument: frontDocumentBase64,
          backDocument: backDocumentBase64,
          selfie: selfieBase64
        },
        
        termsAcceptance: {
          accepted: termsAccepted,
          acceptedAt: new Date(),
          ipAddress: req.ip,
          userAgent: req.get('user-agent'),
          version: '1.0'
        },
        
        status: validationResult.isFullyValidated ? 'VALIDATED' : 'REJECTED',
        deviceInfo,
        tabletInfo,
        
        securityFlags: {
          documentAltered: bioValidation.data?.document_altered,
          photoManipulated: bioValidation.data?.photo_manipulated,
          livenessCheckFailed: !bioValidation.data?.liveness_detected
        },
        
        // Expirar en 1 año
        expiresAt: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000)
      });

      await registration.save();

      logger.info(`✅ Registro biométrico ${registration.status}: ${registration._id}`);

      res.status(201).json({
        success: true,
        message: `Registro ${registration.status.toLowerCase()} exitosamente`,
        data: {
          registrationId: registration._id,
          status: registration.status,
          isValidated: registration.isFullyValidated,
          documentValidation: {
            isValid: docValidation.success,
            status: docValidation.data?.status
          },
          facialValidation: {
            isValid: bioValidation.success,
            matchScore: bioValidation.data?.match_score
          },
          fingerprintValidation: fingerprintValidation ? {
            isValid: fingerprintValidation.success,
            matchScore: fingerprintValidation.data?.matchScore
          } : null,
          mode: validationResult.mode || 'PRODUCTION'
        }
      });

    } catch (error) {
      logger.error('❌ Error en registro biométrico:', error);
      res.status(500).json({
        success: false,
        message: 'Error al procesar el registro biométrico',
        error: error.message
      });
    }
  }

  /**
   * Obtener registro por documento
   * GET /api/v1/biometric/document/:documentNumber
   */
  async getByDocument(req, res) {
    try {
      const { documentNumber } = req.params;
      const { documentType } = req.query;

      const registration = await BiometricRegistration.findByDocument(
        documentNumber,
        documentType || 'CC'
      );

      if (!registration) {
        return res.status(404).json({
          success: false,
          message: 'No se encontró registro para este documento'
        });
      }

      res.json({
        success: true,
        data: registration
      });

    } catch (error) {
      logger.error('❌ Error buscando registro:', error);
      res.status(500).json({
        success: false,
        message: 'Error al buscar registro',
        error: error.message
      });
    }
  }

  /**
   * Obtener registro por ID
   * GET /api/v1/biometric/:id
   */
  async getById(req, res) {
    try {
      const { id } = req.params;

      const registration = await BiometricRegistration.findById(id);

      if (!registration) {
        return res.status(404).json({
          success: false,
          message: 'Registro no encontrado'
        });
      }

      res.json({
        success: true,
        data: registration
      });

    } catch (error) {
      logger.error('❌ Error buscando registro:', error);
      res.status(500).json({
        success: false,
        message: 'Error al buscar registro',
        error: error.message
      });
    }
  }

  /**
   * Listar todos los registros (con paginación)
   * GET /api/v1/biometric
   */
  async list(req, res) {
    try {
      const {
        page = 1,
        limit = 20,
        status,
        startDate,
        endDate
      } = req.query;

      const query = {};
      
      if (status) query.status = status;
      if (startDate || endDate) {
        query.createdAt = {};
        if (startDate) query.createdAt.$gte = new Date(startDate);
        if (endDate) query.createdAt.$lte = new Date(endDate);
      }

      const skip = (page - 1) * limit;
      
      const [registrations, total] = await Promise.all([
        BiometricRegistration.find(query)
          .sort({ createdAt: -1 })
          .skip(skip)
          .limit(parseInt(limit)),
        BiometricRegistration.countDocuments(query)
      ]);

      res.json({
        success: true,
        data: {
          registrations,
          pagination: {
            page: parseInt(page),
            limit: parseInt(limit),
            total,
            pages: Math.ceil(total / limit)
          }
        }
      });

    } catch (error) {
      logger.error('❌ Error listando registros:', error);
      res.status(500).json({
        success: false,
        message: 'Error al listar registros',
        error: error.message
      });
    }
  }

  /**
   * Obtener estadísticas
   * GET /api/v1/biometric/stats
   */
  async getStats(req, res) {
    try {
      const { startDate, endDate } = req.query;
      
      const stats = await BiometricRegistration.getStats(startDate, endDate);

      res.json({
        success: true,
        data: stats[0] || {
          total: 0,
          validated: 0,
          rejected: 0,
          pending: 0,
          avgMatchScore: 0
        }
      });

    } catch (error) {
      logger.error('❌ Error obteniendo estadísticas:', error);
      res.status(500).json({
        success: false,
        message: 'Error al obtener estadísticas',
        error: error.message
      });
    }
  }

  /**
   * Validar existencia y estado de un documento
   * POST /api/v1/biometric/validate
   */
  async validate(req, res) {
    try {
      const { documentNumber, documentType } = req.body;

      const registration = await BiometricRegistration.findByDocument(
        documentNumber,
        documentType || 'CC'
      );

      if (!registration) {
        return res.json({
          success: false,
          exists: false,
          message: 'Documento no registrado'
        });
      }

      res.json({
        success: true,
        exists: true,
        data: {
          registrationId: registration._id,
          status: registration.status,
          isActive: registration.isActive(),
          isValidated: registration.isFullyValidated,
          registeredAt: registration.createdAt
        }
      });

    } catch (error) {
      logger.error('❌ Error validando documento:', error);
      res.status(500).json({
        success: false,
        message: 'Error al validar documento',
        error: error.message
      });
    }
  }
}

module.exports = new BiometricController();