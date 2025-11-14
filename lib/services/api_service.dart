import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/biometric_registration.dart';
import 'logger_service.dart';

class ApiService {
  final String baseUrl = AppConfig.baseUrl;
  
  /// Registrar validación biométrica
  Future<Map<String, dynamic>> registerBiometric(BiometricRegistration registration) async {
    try {
      LoggerService.info('📤 Enviando registro biométrico al servidor...');
      
      final url = Uri.parse('$baseUrl${AppConfig.biometricRegisterEndpoint}');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(registration.toJson()),
      ).timeout(AppConfig.apiTimeout);
      
      LoggerService.info('📥 Respuesta recibida: ${response.statusCode}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        LoggerService.info('✅ Registro exitoso');
        return {
          'success': true,
          'data': data,
        };
      } else {
        final error = jsonDecode(response.body);
        LoggerService.error('❌ Error en registro: ${error['message']}');
        return {
          'success': false,
          'message': error['message'] ?? 'Error desconocido',
          'data': error,
        };
      }
    } catch (e, stackTrace) {
      LoggerService.error('❌ Error de conexión:', e, stackTrace);
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }
  
  /// Validar si un documento existe
  Future<Map<String, dynamic>> validateDocument(String documentNumber, {String documentType = 'CC'}) async {
    try {
      LoggerService.info('🔍 Validando documento: $documentNumber');
      
      final url = Uri.parse('$baseUrl${AppConfig.biometricValidateEndpoint}');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'documentNumber': documentNumber,
          'documentType': documentType,
        }),
      ).timeout(AppConfig.connectionTimeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {
          'success': false,
          'exists': false,
          'message': 'Error al validar documento',
        };
      }
    } catch (e) {
      LoggerService.error('❌ Error validando documento:', e);
      return {
        'success': false,
        'exists': false,
        'message': 'Error de conexión',
      };
    }
  }
  
  /// Health check del servidor
  Future<bool> checkServerHealth() async {
    try {
      final url = Uri.parse('$baseUrl/health');
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('❌ Servidor no disponible:', e);
      return false;
    }
  }
}