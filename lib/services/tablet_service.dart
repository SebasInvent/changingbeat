import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../config/app_config.dart';
import 'logger_service.dart';

/// Servicio para gestión de la tablet con el backend
class TabletService {
  final String baseUrl = AppConfig.baseUrl;
  String? _tabletId;
  
  /// Inicializar y registrar tablet
  Future<bool> initialize() async {
    try {
      LoggerService.info('📱 Inicializando tablet...');
      
      // Generar o recuperar ID de tablet
      _tabletId = await _getOrCreateTabletId();
      
      // Registrar tablet en el backend
      await registerTablet();
      
      // Iniciar heartbeat
      _startHeartbeat();
      
      return true;
    } catch (e) {
      LoggerService.error('❌ Error inicializando tablet:', e);
      return false;
    }
  }
  
  /// Obtener o crear ID único de tablet
  Future<String> _getOrCreateTabletId() async {
    // TODO: Guardar en SharedPreferences para persistencia
    // Por ahora, generar basado en device ID
    final deviceInfo = DeviceInfoPlugin();
    
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return 'TABLET_${androidInfo.id.substring(0, 8)}';
    }
    
    return 'TABLET_${DateTime.now().millisecondsSinceEpoch}';
  }
  
  /// Registrar tablet en el backend
  Future<void> registerTablet() async {
    try {
      final deviceInfo = await _getDeviceInfo();
      final appInfo = await _getAppInfo();
      
      final url = Uri.parse('$baseUrl/tablets/register');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tabletId': _tabletId,
          'name': deviceInfo['model'] ?? 'Tablet Android',
          'deviceInfo': deviceInfo,
          'appInfo': appInfo,
          'location': {
            'name': AppConfig.getTabletId(), // Usar config de ubicación
          }
        }),
      );
      
      if (response.statusCode == 200) {
        LoggerService.info('✅ Tablet registrada: $_tabletId');
      } else {
        LoggerService.error('❌ Error registrando tablet: ${response.body}');
      }
    } catch (e) {
      LoggerService.error('❌ Error en registro de tablet:', e);
    }
  }
  
  /// Enviar heartbeat al backend
  Future<Map<String, dynamic>?> sendHeartbeat() async {
    try {
      final url = Uri.parse('$baseUrl/tablets/$_tabletId/heartbeat');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'battery': await _getBatteryInfo(),
          'storage': await _getStorageInfo(),
          'signalStrength': 80, // TODO: Obtener señal WiFi real
        }),
      );
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        // Retornar configuración actualizada del servidor
        return result['configuration'];
      }
    } catch (e) {
      LoggerService.error('❌ Error en heartbeat:', e);
    }
    
    return null;
  }
  
  /// Reportar evento al backend
  Future<void> reportEvent(String type, String message, {dynamic data}) async {
    try {
      final url = Uri.parse('$baseUrl/tablets/$_tabletId/event');
      
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': type,
          'message': message,
          'data': data,
        }),
      );
    } catch (e) {
      LoggerService.error('❌ Error reportando evento:', e);
    }
  }
  
  /// Obtener información del dispositivo
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return {
        'manufacturer': androidInfo.manufacturer,
        'model': androidInfo.model,
        'osVersion': androidInfo.version.release,
        'androidVersion': 'Android ${androidInfo.version.release}',
        'serialNumber': androidInfo.id,
      };
    }
    
    return {};
  }
  
  /// Obtener información de la app
  Future<Map<String, dynamic>> _getAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    
    return {
      'version': packageInfo.version,
      'buildNumber': packageInfo.buildNumber,
      'installedAt': DateTime.now().toIso8601String(),
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }
  
  /// Obtener información de batería
  Future<Map<String, dynamic>> _getBatteryInfo() async {
    // TODO: Implementar con battery_plus package
    return {
      'level': 85,
      'isCharging': false,
    };
  }
  
  /// Obtener información de almacenamiento
  Future<Map<String, dynamic>> _getStorageInfo() async {
    // TODO: Implementar con disk_space package
    return {
      'total': 32000000000,
      'available': 15000000000,
      'used': 17000000000,
    };
  }
  
  /// Iniciar heartbeat periódico
  void _startHeartbeat() {
    // Enviar heartbeat cada 30 segundos
    Stream.periodic(const Duration(seconds: 30)).listen((_) {
      sendHeartbeat();
    });
  }
  
  /// Obtener ID de la tablet
  String? get tabletId => _tabletId;
}
