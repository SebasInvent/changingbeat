# 👆 Guía de Integración - Lector de Huellas Dactilares

## 🎯 Resumen

Sistema de validación biométrica que combina:
1. **Escaneo de cédula** → Captura imagen del documento
2. **Extracción de huella de cédula** → Procesa la huella impresa
3. **Captura de huella en vivo** → Lector USB
4. **Comparación biométrica** → Valida coincidencia

---

## 🔧 Configuración del Hardware

### Lector de Huellas USB

**Puertos Disponibles:**
```bash
# Listar puertos COM disponibles
node -e "require('serialport').SerialPort.list().then(ports => console.log(ports))"
```

**Configuración Típica:**
- Puerto: `COM3` (ajustar según tu sistema)
- Baud Rate: `9600` o `115200`
- Data Bits: `8`
- Parity: `None`
- Stop Bits: `1`

---

## 📋 Flujo Completo del Sistema

### Modo de Pruebas (MOCK) - SIN Apitude

```
1. Usuario escanea cédula
   ↓
2. Sistema captura imagen (frente y reverso)
   ↓
3. Sistema extrae huella de la imagen (simulado)
   ↓
4. Usuario coloca dedo en lector USB
   ↓
5. Sistema captura huella en vivo
   ↓
6. Sistema compara ambas huellas
   ↓
7. Si coinciden → APROBADO
   Si no coinciden → RECHAZADO
```

### Modo Producción - CON Apitude

```
1. Usuario escanea cédula
   ↓
2. Sistema captura imagen
   ↓
3. Apitude valida con Registraduría
   ↓
4. Apitude verifica facial
   ↓
5. Sistema captura huella USB
   ↓
6. Sistema compara huellas
   ↓
7. Validación completa → APROBADO/RECHAZADO
```

---

## 🚀 Uso del API

### Registro Biométrico CON Validación de Huella

```javascript
POST /api/v1/biometric/register

{
  "documentNumber": "1234567890",
  "documentType": "CC",
  "expeditionDate": "2020-01-15",
  "selfieBase64": "data:image/jpeg;base64,...",
  "frontDocumentBase64": "data:image/jpeg;base64,...",
  "backDocumentBase64": "data:image/jpeg;base64,...",
  "termsAccepted": true,
  "emotion": "neutral",
  
  // NUEVO: Activar validación de huella
  "includeFingerprintValidation": true,
  
  "deviceInfo": {
    "deviceId": "DEVICE_001",
    "deviceModel": "Samsung Galaxy Tab",
    "osVersion": "Android 13",
    "appVersion": "1.0.0"
  },
  "tabletInfo": {
    "tabletId": "TABLET_001",
    "location": {
      "latitude": 4.7110,
      "longitude": -74.0721
    }
  }
}
```

### Respuesta Exitosa

```json
{
  "success": true,
  "message": "Registro validated exitosamente",
  "data": {
    "registrationId": "uuid-123-456",
    "status": "VALIDATED",
    "isValidated": true,
    
    "documentValidation": {
      "isValid": true,
      "status": "VIGENTE"
    },
    
    "facialValidation": {
      "isValid": true,
      "matchScore": 92.5
    },
    
    "fingerprintValidation": {
      "isValid": true,
      "matchScore": 87.3
    },
    
    "mode": "MOCK"  // o "PRODUCTION"
  }
}
```

---

## 🧪 Modo de Pruebas (Actual)

### Características

✅ **NO requiere API key de Apitude**  
✅ **Simula todas las validaciones**  
✅ **Delays realistas** (2-4 segundos)  
✅ **Scores aleatorios** (70-99%)  
✅ **Logs detallados**  

### Comportamiento Simulado

**Validación de Documento:**
- Acepta cualquier número de cédula válido (6+ dígitos)
- Retorna status "VIGENTE"
- Genera nombre aleatorio

**Validación Facial:**
- Verifica que las imágenes no estén vacías
- Genera score entre 70-99%
- Simula detección de emoción

**Validación de Huella:**
- Simula extracción de huella de cédula
- Simula captura de lector USB (4 segundos)
- Genera score de coincidencia 70-99%

---

## 🔌 Integración con Lector USB

### Inicializar Servicio

```javascript
const fingerprintService = require('./src/services/fingerprint.service');

// Inicializar en puerto COM3
await fingerprintService.initialize('COM3', 9600);

// Verificar conexión
if (fingerprintService.isReady()) {
  console.log('✅ Lector de huellas listo');
}
```

### Capturar Huella

```javascript
// Esperar huella del usuario (30 segundos timeout)
const fingerprint = await fingerprintService.captureFingerprint(30000);

console.log('👆 Huella capturada:', fingerprint);
```

### Validar con Documento

```javascript
const result = await fingerprintService.validateFingerprintWithDocument(
  documentImageBase64
);

if (result.success) {
  console.log(`✅ Huella validada: ${result.matchScore}%`);
} else {
  console.log(`❌ Huella no coincide: ${result.error}`);
}
```

---

## 📱 Integración en App Flutter

### Actualizar Modelo

```dart
// lib/models/biometric_registration.dart

class BiometricRegistration {
  // ... campos existentes ...
  
  final bool includeFingerprintValidation;  // NUEVO
  
  BiometricRegistration({
    // ... parámetros existentes ...
    this.includeFingerprintValidation = false,  // NUEVO
  });
  
  Map<String, dynamic> toJson() {
    return {
      // ... campos existentes ...
      'includeFingerprintValidation': includeFingerprintValidation,  // NUEVO
    };
  }
}
```

### Pantalla de Captura de Huella

Crear nueva pantalla: `lib/screens/fingerprint_capture_screen.dart`

```dart
import 'package:flutter/material.dart';

class FingerprintCaptureScreen extends StatefulWidget {
  final String frontDocumentBase64;
  final String backDocumentBase64;
  final String selfieBase64;
  
  const FingerprintCaptureScreen({
    required this.frontDocumentBase64,
    required this.backDocumentBase64,
    required this.selfieBase64,
  });
  
  @override
  State<FingerprintCaptureScreen> createState() => _FingerprintCaptureScreenState();
}

class _FingerprintCaptureScreenState extends State<FingerprintCaptureScreen> {
  bool _isCapturing = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación de Huella'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono de huella
            Icon(
              Icons.fingerprint,
              size: 120,
              color: Theme.of(context).primaryColor,
            ),
            
            const SizedBox(height: 32),
            
            const Text(
              'Coloque su dedo en el lector',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              'El sistema comparará su huella con la de su cédula',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            
            const SizedBox(height: 48),
            
            if (_isCapturing)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _startCapture,
                child: const Text('Iniciar Captura'),
              ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _startCapture() async {
    setState(() {
      _isCapturing = true;
    });
    
    // Aquí se integraría con el backend
    // que a su vez se comunica con el lector USB
    
    await Future.delayed(const Duration(seconds: 4));
    
    setState(() {
      _isCapturing = false;
    });
    
    // Navegar a confirmación
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ConfirmationScreen(
          frontDocumentBase64: widget.frontDocumentBase64,
          backDocumentBase64: widget.backDocumentBase64,
          selfieBase64: widget.selfieBase64,
          fingerprintCaptured: true,  // NUEVO
        ),
      ),
    );
  }
}
```

---

## 🔄 Migración a Producción

### Paso 1: Obtener API Key de Apitude

```bash
# Visita: https://apitude.co/es/contact/
# Solicita acceso a:
# - registraduria-co
# - face-id-co
```

### Paso 2: Configurar .env

```bash
# Agregar al archivo .env
APITUDE_API_KEY=tu_clave_real_aqui
```

### Paso 3: Reiniciar Servidor

```bash
npm start
```

El sistema automáticamente detectará la API key y cambiará de modo MOCK a PRODUCTION.

### Paso 4: Integrar Lector Real

Reemplazar la lógica simulada en `fingerprint.service.js` con:
- Protocolo real de tu lector específico
- Algoritmo de matching real (SourceAFIS, BOZORTH3, etc.)
- Extracción real de huella de imagen (OpenCV + algoritmos biométricos)

---

## 📊 Logs del Sistema

### Modo MOCK Activo

```
17:30:09 [warn]: ⚠️  APITUDE_API_KEY no configurada. Usando servicio MOCK para pruebas.
17:30:09 [info]: 💡 Para usar validación real, configura APITUDE_API_KEY en .env
17:30:09 [info]: 🧪 Modo de Pruebas: Usando validación biométrica simulada
```

### Registro con Huella

```
17:35:12 [info]: 📝 Iniciando registro biométrico para documento: 1234567890
17:35:12 [info]: 🧪 [MOCK] Validación completa simulada para documento 1234567890...
17:35:12 [info]: 🧪 [MOCK] Validando documento 1234567890 con Registraduría...
17:35:14 [info]: ✅ [MOCK] Documento validado: VIGENTE
17:35:14 [info]: 🧪 [MOCK] Iniciando validación biométrica facial simulada...
17:35:17 [info]: ✅ [MOCK] Validación facial: Score 85%
17:35:17 [info]: 🧪 [MOCK] Simulando validación de huella dactilar...
17:35:21 [info]: ✅ [MOCK] Validación de huella: 92%
17:35:21 [info]: ✅ Registro biométrico VALIDATED: uuid-123-456
```

---

## 🛠️ Troubleshooting

### Lector de Huellas No Detectado

```bash
# Verificar puertos disponibles
node -e "require('./src/services/fingerprint.service').listAvailablePorts()"

# Verificar permisos
# Windows: Ejecutar como Administrador
# Linux: sudo usermod -a -G dialout $USER
```

### Error de Timeout

```javascript
// Aumentar timeout en fingerprint.service.js
await fingerprintService.captureFingerprint(60000); // 60 segundos
```

### Score Muy Bajo

- Verificar calidad de imagen de cédula
- Limpiar sensor del lector
- Asegurar que el dedo esté seco y limpio
- Ajustar umbral de coincidencia (default: 70%)

---

## 📈 Próximos Pasos

### Corto Plazo
- [ ] Probar flujo completo en modo MOCK
- [ ] Conectar lector USB real
- [ ] Ajustar timeouts y umbrales
- [ ] Testing con múltiples usuarios

### Mediano Plazo
- [ ] Integrar algoritmo real de matching
- [ ] Implementar extracción de huella de imagen
- [ ] Obtener API key de Apitude
- [ ] Migrar a producción

### Largo Plazo
- [ ] Multi-biometría (huella + facial + iris)
- [ ] Base de datos biométrica local
- [ ] Sincronización con Registraduría
- [ ] Analytics y reportes

---

## 📞 Soporte Técnico

### Lectores Compatibles
- **DigitalPersona U.are.U**
- **ZKTeco**
- **Suprema**
- **Nitgen**
- **Futronic**

### Algoritmos de Matching
- **SourceAFIS** (Open Source)
- **NIST BOZORTH3** (Gobierno USA)
- **Neurotechnology MegaMatcher**
- **Innovatrics**

### Librerías Recomendadas
- `node-fingerprint` - Node.js wrapper
- `opencv4nodejs` - Procesamiento de imagen
- `sharp` - Optimización de imágenes

---

**Versión**: 1.0.0  
**Fecha**: Noviembre 2024  
**Estado**: Modo de Pruebas Activo 🧪
