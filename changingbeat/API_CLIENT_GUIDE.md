# Guía de Uso del API Client

Esta guía explica cómo usar el API Client para comunicarse con el backend del sistema de verificación biométrica.

## Arquitectura

```
lib/data/
├── clients/
│   └── api_client.dart          # Cliente HTTP base con Dio
├── models/
│   ├── api_response.dart        # Modelo genérico de respuesta
│   ├── user_model.dart          # Modelos de usuario y autenticación
│   └── biometric_record_model.dart  # Modelos de registros biométricos
└── services/
    └── api_service.dart         # Servicio singleton para acceso global
```

## Configuración

El API Client está configurado para conectarse a:
- **URL Base**: `https://access-control.eukahack.com/api/v1`
- **Timeout de Conexión**: 30 segundos
- **Timeout de API**: 60 segundos

Estos valores están definidos en `lib/core/constants/app_constants.dart`.

## Uso Básico

### 1. Obtener Instancia del Servicio

```dart
import 'package:biometric_verification/data/services/api_service.dart';

final apiService = ApiService();
```

### 2. Verificar Estado del Servidor

```dart
Future<void> checkServerHealth() async {
  final response = await apiService.checkHealth();
  
  if (response.success) {
    print('Servidor en línea: ${response.data}');
  } else {
    print('Error: ${response.error}');
  }
}
```

### 3. Autenticación

#### Login

```dart
Future<void> loginUser() async {
  final authResponse = await apiService.login(
    username: 'operator1',
    password: 'password123',
  );
  
  if (authResponse.success && authResponse.token != null) {
    print('Login exitoso');
    print('Token: ${authResponse.token}');
    print('Usuario: ${authResponse.user?.username}');
    
    // El token se guarda automáticamente en el cliente
  } else {
    print('Error de login: ${authResponse.message}');
  }
}
```

#### Logout

```dart
Future<void> logoutUser() async {
  await apiService.logout();
  print('Sesión cerrada');
}
```

### 4. Registro Biométrico

```dart
import 'package:biometric_verification/data/models/biometric_record_model.dart';

Future<void> registerBiometric() async {
  // Crear solicitud de registro
  final request = BiometricRegistrationRequest(
    documentNumber: '1234567890',
    documentType: 'CC',
    firstName: 'Juan',
    lastName: 'Pérez',
    birthDate: DateTime(1990, 1, 1),
    gender: 'M',
    nationality: 'CO',
    photoBase64: 'base64_encoded_image_here',
    faceEmbedding: 'face_embedding_vector_here',
    tabletId: 'TAB-001',
    operatorId: 'OP-123',
    metadata: {
      'location': 'Bogotá',
      'temperature': 36.5,
    },
  );
  
  // Enviar registro
  final response = await apiService.registerBiometric(request);
  
  if (response.success && response.data != null) {
    print('Registro exitoso');
    print('ID: ${response.data!.id}');
    print('Nombre: ${response.data!.fullName}');
  } else {
    print('Error: ${response.error}');
  }
}
```

### 5. Validación Biométrica

```dart
Future<void> validateBiometric() async {
  // Crear solicitud de validación
  final request = BiometricValidationRequest(
    photoBase64: 'base64_encoded_image_here',
    faceEmbedding: 'face_embedding_vector_here',
    documentNumber: '1234567890', // Opcional
    tabletId: 'TAB-001',
  );
  
  // Enviar validación
  final response = await apiService.validateBiometric(request);
  
  if (response.success) {
    if (response.isMatch) {
      print('¡Coincidencia encontrada!');
      print('Score: ${response.matchScore}');
      print('Persona: ${response.matchedRecord?.fullName}');
    } else {
      print('No se encontró coincidencia');
    }
  } else {
    print('Error: ${response.message}');
  }
}
```

### 6. Obtener Registros

```dart
Future<void> getRecords() async {
  // Obtener todos los registros (con paginación)
  final response = await apiService.getRecords(
    limit: 20,
    skip: 0,
    status: 'approved', // Opcional: filtrar por estado
  );
  
  if (response.success && response.data != null) {
    print('Total de registros: ${response.data!.length}');
    
    for (var record in response.data!) {
      print('${record.fullName} - ${record.documentNumber}');
    }
  } else {
    print('Error: ${response.error}');
  }
}
```

### 7. Obtener Registro por ID

```dart
Future<void> getRecordById(String recordId) async {
  final response = await apiService.getRecordById(recordId);
  
  if (response.success && response.data != null) {
    final record = response.data!;
    print('Nombre: ${record.fullName}');
    print('Documento: ${record.documentNumber}');
    print('Estado: ${record.status}');
    print('Fecha: ${record.createdAt}');
  } else {
    print('Error: ${response.error}');
  }
}
```

## Manejo de Errores

El API Client maneja automáticamente diferentes tipos de errores:

```dart
Future<void> handleErrors() async {
  final response = await apiService.checkHealth();
  
  if (!response.success) {
    // Tipos de errores comunes:
    // - "Tiempo de conexión agotado"
    // - "Error de conexión. Verifique su conexión a internet"
    // - "Error del servidor (500)"
    // - "Error inesperado: ..."
    
    print('Error: ${response.error}');
    print('Código de estado: ${response.statusCode}');
  }
}
```

## Logging

El API Client incluye logging automático usando el paquete `logger`:

- **Requests**: Método, URL, headers y body
- **Responses**: Código de estado y URL
- **Errors**: Detalles completos del error

Los logs se muestran en la consola durante el desarrollo.

## Ejemplo Completo en un Screen

```dart
import 'package:flutter/material.dart';
import 'package:biometric_verification/data/services/api_service.dart';
import 'package:biometric_verification/data/models/biometric_record_model.dart';

class ExampleScreen extends StatefulWidget {
  const ExampleScreen({super.key});

  @override
  State<ExampleScreen> createState() => _ExampleScreenState();
}

class _ExampleScreenState extends State<ExampleScreen> {
  final _apiService = ApiService();
  bool _isLoading = false;
  String _message = '';

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _message = 'Verificando conexión...';
    });

    try {
      final response = await _apiService.checkHealth();
      
      setState(() {
        _isLoading = false;
        _message = response.success
            ? '✓ Servidor conectado'
            : '✗ Error: ${response.error}';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = '✗ Error inesperado: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API Client Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              const CircularProgressIndicator()
            else
              Text(_message),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _testConnection,
              child: const Text('Probar Conexión'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Endpoints Disponibles

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/health` | Verificar estado del servidor |
| POST | `/auth/login` | Autenticación de usuario |
| POST | `/biometric/register` | Registrar datos biométricos |
| POST | `/biometric/validate` | Validar datos biométricos |
| GET | `/records` | Obtener lista de registros |
| GET | `/records/:id` | Obtener registro por ID |

## Notas Importantes

1. **Autenticación**: El token se guarda automáticamente después del login y se incluye en todas las peticiones subsiguientes.

2. **Imágenes Base64**: Las imágenes deben ser convertidas a Base64 antes de enviarlas. Ejemplo:
   ```dart
   import 'dart:convert';
   import 'dart:io';
   
   String imageToBase64(File imageFile) {
     final bytes = imageFile.readAsBytesSync();
     return base64Encode(bytes);
   }
   ```

3. **Timeouts**: Si una operación tarda más del tiempo configurado, se retornará un error de timeout.

4. **Manejo de Errores**: Siempre verifica `response.success` antes de acceder a `response.data`.

5. **Logging**: En producción, considera desactivar o reducir el nivel de logging para mejorar el rendimiento.

## Próximos Pasos

- Implementar caché local con `shared_preferences`
- Agregar retry automático para peticiones fallidas
- Implementar sincronización offline
- Agregar métricas y analytics
