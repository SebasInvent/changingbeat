# 📱 Guía del Dashboard de Tablets

## 🎯 Descripción General

Sistema de gestión centralizado que permite controlar y monitorear todas las tablets Android conectadas al sistema biométrico desde un dashboard web único.

---

## 🌟 Características Principales

### Dashboard Central
- **Vista en tiempo real** de todas las tablets
- **Estadísticas globales** del sistema
- **Estado de conexión** (Online/Offline)
- **Monitoreo de batería** y almacenamiento
- **Configuración remota** de cada tablet

### Por Cada Tablet
- **ID único** y nombre personalizado
- **Ubicación física** (edificio, piso, zona)
- **Información del dispositivo** (modelo, OS, etc.)
- **Estadísticas de uso**:
  - Total de registros
  - Total de verificaciones
  - Tasa de éxito
  - Tiempo promedio de procesamiento
- **Estado del hardware**:
  - Cámara
  - Lector de huellas
  - Batería
  - Almacenamiento
- **Logs de eventos** recientes

---

## 🚀 Acceso al Dashboard

### URL
```
http://localhost:3000/admin-tablets.html
```

### Características del Dashboard

#### 1. Estadísticas Globales (Top)
- **Total Tablets**: Número de tablets registradas
- **Online**: Tablets actualmente conectadas
- **Registros Totales**: Suma de todos los registros
- **Tasa de Éxito**: Porcentaje global de validaciones exitosas

#### 2. Grid de Tablets
Cada tarjeta muestra:
- Nombre y estado (Online/Offline)
- ID único
- Ubicación
- Modelo del dispositivo
- Estadísticas de uso
- Nivel de batería con barra de progreso
- Botones de acción:
  - **⚙️ Configurar**: Abrir panel de configuración
  - **📊 Detalles**: Ver información completa

#### 3. Panel de Configuración
Permite configurar remotamente:
- **Modo de operación**:
  - Solo Registro
  - Solo Verificación
  - Ambos
- **Validaciones habilitadas**:
  - ✓ Facial
  - ✓ Huella dactilar
  - ✓ Documento
- **Interfaz**:
  - Tema (Claro/Oscuro)
  - Idioma
  - Mensaje personalizado
- **Horarios de operación**:
  - Días activos
  - Horas de inicio/fin

---

## 📡 API Endpoints

### Registrar Tablet
```http
POST /api/v1/tablets/register

{
  "tabletId": "TABLET_001",
  "name": "Tablet Entrada Principal",
  "deviceInfo": {
    "manufacturer": "Samsung",
    "model": "Galaxy Tab S8",
    "osVersion": "13",
    "androidVersion": "Android 13"
  },
  "appInfo": {
    "version": "1.0.0",
    "buildNumber": "1"
  },
  "location": {
    "name": "Entrada Principal",
    "building": "Edificio A",
    "floor": "Piso 1"
  }
}
```

### Heartbeat (Mantener Conexión)
```http
POST /api/v1/tablets/:tabletId/heartbeat

{
  "battery": {
    "level": 85,
    "isCharging": false
  },
  "storage": {
    "total": 32000000000,
    "available": 15000000000,
    "used": 17000000000
  },
  "signalStrength": 80
}
```

### Reportar Evento
```http
POST /api/v1/tablets/:tabletId/event

{
  "type": "REGISTRATION",
  "message": "Nuevo usuario registrado",
  "data": {
    "documentNumber": "1234567890",
    "success": true
  }
}
```

### Listar Tablets
```http
GET /api/v1/tablets
```

### Obtener Tablet Específica
```http
GET /api/v1/tablets/:tabletId
```

### Actualizar Configuración
```http
PATCH /api/v1/tablets/:tabletId/configuration

{
  "operationMode": "BOTH",
  "enabledValidations": {
    "facial": true,
    "fingerprint": true,
    "document": true
  },
  "ui": {
    "theme": "light",
    "language": "es"
  }
}
```

### Estadísticas Globales
```http
GET /api/v1/tablets/stats/global
```

### Estadísticas de Tablet
```http
GET /api/v1/tablets/:tabletId/stats
```

### Habilitar/Deshabilitar
```http
PATCH /api/v1/tablets/:tabletId/toggle

{
  "isEnabled": true
}
```

### Eliminar Tablet
```http
DELETE /api/v1/tablets/:tabletId
```

---

## 📱 Integración en App Flutter

### Auto-Registro al Iniciar

La app Flutter se registra automáticamente al iniciar:

```dart
// En main.dart
final tabletService = TabletService();
await tabletService.initialize();
```

### Heartbeat Automático

Cada 30 segundos envía:
- Estado de batería
- Espacio de almacenamiento
- Señal WiFi

### Reportar Eventos

```dart
// Después de un registro exitoso
tabletService.reportEvent(
  'REGISTRATION',
  'Usuario registrado exitosamente',
  data: {'documentNumber': '1234567890'}
);

// En caso de error
tabletService.reportEvent(
  'ERROR',
  'Error al capturar imagen',
  data: {'error': 'Camera not available'}
);
```

---

## 🔄 Flujo de Funcionamiento

### 1. Inicio de Tablet
```
App Flutter inicia
    ↓
Genera/Recupera ID único
    ↓
Registra en backend
    ↓
Inicia heartbeat cada 30s
    ↓
Dashboard muestra tablet ONLINE
```

### 2. Configuración Remota
```
Admin abre dashboard
    ↓
Selecciona tablet
    ↓
Modifica configuración
    ↓
Guarda cambios
    ↓
Próximo heartbeat recibe nueva config
    ↓
App aplica cambios automáticamente
```

### 3. Monitoreo en Tiempo Real
```
Tablet procesa registro
    ↓
Reporta evento al backend
    ↓
Backend actualiza estadísticas
    ↓
Dashboard se actualiza (auto-refresh 10s)
    ↓
Admin ve evento en tiempo real
```

---

## 📊 Modelo de Datos

### Tablet Schema

```javascript
{
  _id: String (UUID),
  tabletId: String (único),
  name: String,
  
  deviceInfo: {
    manufacturer: String,
    model: String,
    osVersion: String,
    androidVersion: String,
    serialNumber: String
  },
  
  appInfo: {
    version: String,
    buildNumber: String,
    installedAt: Date,
    lastUpdated: Date
  },
  
  location: {
    name: String,
    address: String,
    coordinates: { latitude, longitude },
    building: String,
    floor: String,
    zone: String
  },
  
  connectionStatus: {
    isOnline: Boolean,
    lastSeen: Date,
    ipAddress: String,
    signalStrength: Number
  },
  
  configuration: {
    operationMode: 'REGISTRATION' | 'VERIFICATION' | 'BOTH',
    enabledValidations: {
      facial: Boolean,
      fingerprint: Boolean,
      document: Boolean
    },
    timeouts: {
      captureTimeout: Number,
      validationTimeout: Number
    },
    ui: {
      theme: 'light' | 'dark',
      language: String,
      showLogo: Boolean,
      customMessage: String
    },
    schedule: {
      enabled: Boolean,
      workingHours: [...]
    }
  },
  
  statistics: {
    totalRegistrations: Number,
    totalVerifications: Number,
    successfulValidations: Number,
    failedValidations: Number,
    averageProcessingTime: Number,
    lastRegistration: Date,
    lastVerification: Date
  },
  
  hardware: {
    camera: { available, resolution },
    fingerprint: { available, model, port },
    battery: { level, isCharging },
    storage: { total, available, used }
  },
  
  recentEvents: [{
    type: String,
    message: String,
    timestamp: Date,
    data: Mixed
  }],
  
  status: 'ACTIVE' | 'INACTIVE' | 'MAINTENANCE' | 'ERROR',
  isEnabled: Boolean
}
```

---

## 🎨 Personalización del Dashboard

### Colores y Tema

Editar en `admin-tablets.html`:

```css
.header {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.btn-primary {
    background: #667eea;
}
```

### Auto-Refresh

Cambiar intervalo (default: 10 segundos):

```javascript
refreshInterval = setInterval(loadData, 10000); // ms
```

### Heartbeat de Tablets

Cambiar intervalo en Flutter (default: 30 segundos):

```dart
Stream.periodic(const Duration(seconds: 30))
```

---

## 🔒 Seguridad

### Consideraciones

1. **Autenticación**: Agregar login para acceder al dashboard
2. **Autorización**: Roles de admin vs operador
3. **HTTPS**: Usar en producción
4. **Rate Limiting**: Limitar peticiones por IP
5. **Validación**: Verificar datos de entrada

### Implementación Recomendada

```javascript
// Middleware de autenticación
router.use('/tablets', authMiddleware);

// Middleware de autorización
router.use('/tablets', requireRole('admin'));
```

---

## 📈 Métricas y Análisis

### KPIs Disponibles

- **Uptime**: Porcentaje de tiempo online
- **Success Rate**: Tasa de validaciones exitosas
- **Average Processing Time**: Tiempo promedio de procesamiento
- **Registrations per Hour**: Registros por hora
- **Peak Usage Times**: Horarios de mayor uso

### Exportar Datos

```javascript
// Endpoint para exportar estadísticas
GET /api/v1/tablets/export?format=csv&startDate=2024-01-01&endDate=2024-12-31
```

---

## 🐛 Troubleshooting

### Tablet No Aparece en Dashboard

1. Verificar que la app esté corriendo
2. Revisar URL del backend en `app_config.dart`
3. Verificar conectividad de red
4. Revisar logs del backend

### Tablet Aparece Offline

1. Verificar heartbeat en logs
2. Revisar última conexión (`lastSeen`)
3. Verificar que la app no esté en background
4. Reiniciar app en tablet

### Configuración No Se Aplica

1. Verificar que el heartbeat esté funcionando
2. La configuración se aplica en el próximo heartbeat (30s)
3. Revisar logs de la app Flutter

---

## 🚀 Próximas Mejoras

### Corto Plazo
- [ ] Notificaciones push a tablets
- [ ] Actualización remota de APK
- [ ] Reinicio remoto de tablets
- [ ] Captura de pantalla remota

### Mediano Plazo
- [ ] Dashboard móvil (app de admin)
- [ ] Alertas por email/SMS
- [ ] Integración con sistemas de tickets
- [ ] Reportes automáticos

### Largo Plazo
- [ ] Machine Learning para predecir fallos
- [ ] Optimización automática de configuración
- [ ] Balanceo de carga entre tablets
- [ ] Clustering geográfico

---

## 📞 Soporte

### Logs del Sistema

**Backend:**
```bash
tail -f logs/combined.log | grep TABLET
```

**App Flutter:**
```dart
LoggerService.info('Mensaje de log');
```

### Comandos Útiles

```bash
# Ver tablets online
curl http://localhost:3000/api/v1/tablets?isOnline=true

# Ver estadísticas
curl http://localhost:3000/api/v1/tablets/stats/global

# Deshabilitar tablet
curl -X PATCH http://localhost:3000/api/v1/tablets/TABLET_001/toggle \
  -H "Content-Type: application/json" \
  -d '{"isEnabled": false}'
```

---

**Versión**: 1.0.0  
**Fecha**: Noviembre 2024  
**Estado**: Producción Ready ✅
