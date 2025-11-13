# 📱 Sistema de Verificación Biométrica - Guía Completa

## 🎯 Resumen del Proyecto

Sistema completo de verificación biométrica con validación de cédulas colombianas mediante integración con la Registraduría Nacional (ANI) a través de Apitude API.

### Componentes

1. **Backend Node.js** - API REST con MongoDB
2. **App Flutter** - Aplicación Android/iOS/Windows
3. **Integración Apitude** - Validación con Registraduría/ANI

---

## 🚀 Estado del Proyecto

### ✅ Backend - FUNCIONANDO
- Puerto: `http://localhost:3000`
- MongoDB: Conectado
- API Docs: `http://localhost:3000/api-docs`

### ⏳ Frontend Flutter - PENDIENTE
- Código completo ✅
- Requiere: Instalar Flutter

---

## 📋 Endpoints API Disponibles

### Biométricos

```http
POST /api/v1/biometric/register
```
Registrar nuevo usuario con validación biométrica

**Body:**
```json
{
  "documentNumber": "1234567890",
  "documentType": "CC",
  "expeditionDate": "2020-01-15",
  "selfieBase64": "base64_string...",
  "frontDocumentBase64": "base64_string...",
  "backDocumentBase64": "base64_string...",
  "termsAccepted": true,
  "emotion": "neutral",
  "deviceInfo": {
    "deviceId": "DEVICE_001",
    "deviceModel": "Samsung Galaxy",
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

**Respuesta Exitosa:**
```json
{
  "success": true,
  "message": "Registro validated exitosamente",
  "data": {
    "registrationId": "uuid...",
    "status": "VALIDATED",
    "isValidated": true,
    "documentValidation": {
      "isValid": true,
      "status": "VIGENTE"
    },
    "facialValidation": {
      "isValid": true,
      "matchScore": 95.5
    }
  }
}
```

---

```http
POST /api/v1/biometric/validate
```
Validar si un documento está registrado

**Body:**
```json
{
  "documentNumber": "1234567890",
  "documentType": "CC"
}
```

---

```http
GET /api/v1/biometric/stats
```
Obtener estadísticas de registros

**Query Parameters:**
- `startDate`: Fecha inicio (YYYY-MM-DD)
- `endDate`: Fecha fin (YYYY-MM-DD)

---

```http
GET /api/v1/biometric
```
Listar registros (paginado)

**Query Parameters:**
- `page`: Número de página (default: 1)
- `limit`: Registros por página (default: 20)
- `status`: Filtrar por estado (PENDING, VALIDATED, REJECTED, EXPIRED)
- `startDate`: Fecha inicio
- `endDate`: Fecha fin

---

```http
GET /api/v1/biometric/:id
```
Obtener registro por ID

---

```http
GET /api/v1/biometric/document/:documentNumber
```
Obtener registro por número de documento

**Query Parameters:**
- `documentType`: Tipo de documento (default: CC)

---

## 🔧 Configuración

### Variables de Entorno (.env)

```bash
# Servidor
PORT=3000
HOST=0.0.0.0

# Base de Datos
MONGODB_URI=mongodb://localhost:27017/autoregistro

# API Apitude (IMPORTANTE)
APITUDE_API_KEY=tu_api_key_aqui
```

### Obtener API Key de Apitude

1. Visita: https://apitude.co/es/contact/
2. Solicita acceso a:
   - `registraduria-co` (Validación de cédulas)
   - `face-id-co` (Verificación facial)
3. Agrega la API key al archivo `.env`

---

## 📱 App Flutter

### Estructura

```
lib/
├── config/
│   ├── app_config.dart      # URLs y configuración
│   └── theme.dart           # Tema visual
├── models/
│   └── biometric_registration.dart  # Modelos de datos
├── services/
│   ├── api_service.dart     # Conexión con backend
│   ├── camera_service.dart  # Manejo de cámara
│   └── logger_service.dart  # Logging
├── screens/
│   ├── splash_screen.dart
│   ├── terms_screen.dart
│   ├── document_scan_screen.dart
│   ├── facial_capture_screen.dart
│   ├── confirmation_screen.dart
│   └── result_screen.dart
└── main.dart
```

### Flujo de Usuario

1. **Splash** → Solicita permisos
2. **Términos** → Acepta términos y condiciones
3. **Escaneo Documento** → Captura frente y reverso de cédula
4. **Captura Facial** → Selfie con detección de emoción
5. **Confirmación** → Ingresa datos del documento
6. **Resultado** → Muestra resultado de validación

### Configurar URL del Backend

En `lib/config/app_config.dart`:

```dart
static const String baseUrl = 'http://TU_IP:3000/api/v1';
```

**Nota**: Si usas emulador Android, usa `10.0.2.2` en lugar de `localhost`.

---

## 🔒 Seguridad y Privacidad

### Datos Almacenados

- Imágenes en Base64 (encriptadas en BD)
- Datos personales de cédula
- Resultados de validación
- Metadata de dispositivo y ubicación

### Cumplimiento

- ✅ Términos y condiciones explícitos
- ✅ Consentimiento informado
- ✅ Datos encriptados en tránsito (HTTPS)
- ✅ TTL de registros (expiran automáticamente)
- ✅ Logs de auditoría

---

## 🧪 Testing

### Probar Backend

```bash
# Health check
curl http://localhost:3000/api/v1/health

# Stats (sin registros)
curl http://localhost:3000/api/v1/biometric/stats
```

### Probar con Postman

Importa la colección desde: `http://localhost:3000/api-docs`

---

## 📊 Modelo de Datos

### BiometricRegistration

```javascript
{
  _id: String (UUID),
  documentNumber: String,
  documentType: String (CC, TI, CE, PEP, PPT),
  expeditionDate: Date,
  
  personalInfo: {
    fullName: String,
    firstName: String,
    lastName: String,
    // ...
  },
  
  registraduriaValidation: {
    isValid: Boolean,
    status: String (VIGENTE, NO_VIGENTE, SUSPENDIDA),
    validatedAt: Date,
    validationData: {
      area: String,
      city: String,
      // ...
    }
  },
  
  facialVerification: {
    isValid: Boolean,
    matchScore: Number (0-100),
    livenessDetected: Boolean,
    emotionDetected: String,
    // ...
  },
  
  images: {
    frontDocument: String (Base64),
    backDocument: String (Base64),
    selfie: String (Base64)
  },
  
  termsAcceptance: {
    accepted: Boolean,
    acceptedAt: Date,
    ipAddress: String,
    version: String
  },
  
  status: String (PENDING, VALIDATED, REJECTED, EXPIRED),
  
  createdAt: Date,
  updatedAt: Date,
  expiresAt: Date (TTL Index)
}
```

---

## 🚨 Troubleshooting

### Backend no inicia

```bash
# Verificar MongoDB
tasklist | findstr mongod

# Ver logs
tail -f logs/combined.log
```

### APITUDE_API_KEY no configurada

Agrega al archivo `.env`:
```bash
APITUDE_API_KEY=tu_clave_aqui
```

### Error de conexión en Flutter

Verifica:
1. Backend está corriendo
2. URL correcta en `app_config.dart`
3. Si usas emulador: `10.0.2.2:3000` en lugar de `localhost:3000`

### Permisos de cámara en Android

Verifica `AndroidManifest.xml` tenga:
```xml
<uses-permission android:name="android.permission.CAMERA" />
```

---

## 📈 Roadmap

### Fase 1 - Actual ✅
- [x] Backend con endpoints completos
- [x] Integración Apitude API
- [x] App Flutter completa
- [x] Validación con Registraduría

### Fase 2 - Siguiente
- [ ] Instalación Flutter
- [ ] Primera compilación APK
- [ ] Testing en dispositivo real
- [ ] Optimización de imágenes

### Fase 3 - Futuro
- [ ] Dashboard web de administración
- [ ] Reportes y analytics
- [ ] Notificaciones push
- [ ] Multi-idioma

---

## 💡 Consejos

### Performance

- Las imágenes Base64 son pesadas (~2-3MB cada una)
- Usa compresión JPEG con calidad 0.9
- Redimensiona imágenes a máximo 1920px

### UX

- Muestra feedback visual en cada paso
- Countdown antes de captura facial (3 segundos)
- Instrucciones claras en cada pantalla

### Seguridad

- NUNCA expongas la API key en el código
- Usa HTTPS en producción
- Implementa rate limiting
- Logs de auditoría obligatorios

---

## 📞 Soporte

### APIs Utilizadas

- **Apitude**: https://apitude.co/es/docs/
  - Registraduría: `/api/v1.0/requests/registraduria-co/`
  - Face ID: `/api/v1.0/requests/face-id-co/`

### Documentación

- **Flutter**: https://docs.flutter.dev/
- **MongoDB**: https://www.mongodb.com/docs/
- **Express**: https://expressjs.com/

---

## ✅ Checklist de Deployment

### Backend
- [ ] MongoDB en servidor dedicado
- [ ] Variables de entorno configuradas
- [ ] HTTPS habilitado
- [ ] Backups automáticos
- [ ] Monitoring y logs

### App Flutter
- [ ] Compilar en modo release
- [ ] Firmar APK
- [ ] Probar en múltiples dispositivos
- [ ] Optimizar tamaño del APK
- [ ] Publicar en Play Store

---

**Creado**: Noviembre 2024  
**Versión**: 1.0.0  
**Estado**: En Desarrollo 🚧
