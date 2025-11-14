# 🎥 Guía de Integración: Sistema de Cámaras Existente → Dashboard

## 🎯 Objetivo
Conectar tu sistema de cámaras biométricas (que ya funciona y reconoce a Eduardo Cuervo) con nuestro dashboard para ver todos los eventos en tiempo real.

---

## 🔍 Análisis del Sistema Actual

Tu sistema de cámaras:
- ✅ Ya está funcionando
- ✅ Reconoce caras (Eduardo Cuervo)
- ✅ Emite sonido con el nombre
- ❓ ¿Tiene logs? ¿Base de datos? ¿API?

---

## 🛠️ Métodos de Integración

### **MÉTODO 1: API/Webhook del Sistema de Cámaras** ⭐ (Recomendado)

Si tu sistema de cámaras tiene una API o puede enviar webhooks:

#### **Configuración:**
1. Busca en la configuración de tu sistema de cámaras:
   - "Webhook URL"
   - "Callback URL"
   - "HTTP Notification"
   - "Event Notification"

2. Configura esta URL:
   ```
   http://TU_IP_SERVIDOR:3000/api/v1/terminals/identify-callback
   ```

3. El sistema debe enviar (en formato JSON):
   ```json
   {
     "personId": "eduardo-cuervo-001",
     "ip": "IP_DE_LA_CAMARA",
     "temp": 36.5,
     "timestamp": "2025-11-09T00:58:00Z"
   }
   ```

---

### **MÉTODO 2: Monitorear Base de Datos del Sistema** 📊

Si tu sistema de cámaras guarda eventos en una base de datos:

#### **Script de Monitoreo:**

```javascript
// scripts/monitor-camera-db.js
const mongoose = require('mongoose');
const axios = require('axios');

// Conectar a la BD del sistema de cámaras
const cameraDB = mongoose.createConnection('mongodb://localhost:27017/camera_system');

// Escuchar cambios en la colección de eventos
const EventSchema = new mongoose.Schema({}, { strict: false });
const CameraEvent = cameraDB.model('events', EventSchema);

// Usar Change Streams para detectar nuevos eventos
const changeStream = CameraEvent.watch();

changeStream.on('change', async (change) => {
  if (change.operationType === 'insert') {
    const event = change.fullDocument;
    
    // Si es Eduardo Cuervo
    if (event.personName === 'Eduardo Cuervo') {
      // Enviar a nuestro sistema
      await axios.post('http://localhost:3000/api/v1/terminals/identify-callback', {
        personId: 'dd87444b-4cfc-4adb-8222-53ee7e26c956',
        ip: event.cameraIp || '192.168.1.201',
        temp: event.temperature || 36.5,
        imgBase64: event.photo
      });
      
      console.log('✅ Evento de Eduardo enviado al dashboard');
    }
  }
});
```

---

### **MÉTODO 3: Monitorear Archivos de Log** 📝

Si tu sistema de cámaras escribe logs en archivos:

#### **Script de Monitoreo:**

```javascript
// scripts/monitor-camera-logs.js
const fs = require('fs');
const axios = require('axios');
const { Tail } = require('tail');

// Ruta al archivo de log del sistema de cámaras
const logFile = 'C:\\CameraSystem\\logs\\events.log';

const tail = new Tail(logFile);

tail.on('line', async (line) => {
  // Buscar líneas que mencionen "Eduardo Cuervo"
  if (line.includes('Eduardo Cuervo') || line.includes('EDUARDO CUERVO')) {
    console.log('📸 Detección encontrada en log:', line);
    
    // Extraer información del log (ajustar según formato)
    const timestamp = line.match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)?.[0];
    const cameraIp = line.match(/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/)?.[0];
    
    // Enviar a nuestro sistema
    try {
      await axios.post('http://localhost:3000/api/v1/terminals/identify-callback', {
        personId: 'dd87444b-4cfc-4adb-8222-53ee7e26c956',
        ip: cameraIp || '192.168.1.201',
        temp: 36.5,
        timestamp: timestamp
      });
      
      console.log('✅ Evento enviado al dashboard');
    } catch (error) {
      console.error('❌ Error enviando evento:', error.message);
    }
  }
});

tail.on('error', (error) => {
  console.error('Error leyendo log:', error);
});

console.log('👀 Monitoreando logs de cámaras...');
```

---

### **MÉTODO 4: Capturar Tráfico de Red** 🌐

Si el sistema de cámaras se comunica con un servidor:

#### **Usar Proxy/Interceptor:**

```javascript
// scripts/network-interceptor.js
const http = require('http');
const httpProxy = require('http-proxy');
const axios = require('axios');

// Crear proxy
const proxy = httpProxy.createProxyServer({});

// Servidor proxy
const server = http.createServer((req, res) => {
  let body = '';
  
  req.on('data', chunk => {
    body += chunk.toString();
  });
  
  req.on('end', async () => {
    // Analizar el body
    if (body.includes('Eduardo Cuervo')) {
      console.log('📸 Evento interceptado:', body);
      
      // Enviar a nuestro sistema
      await axios.post('http://localhost:3000/api/v1/terminals/identify-callback', {
        personId: 'dd87444b-4cfc-4adb-8222-53ee7e26c956',
        ip: req.socket.remoteAddress,
        temp: 36.5
      });
    }
    
    // Reenviar la petición original
    proxy.web(req, res, { target: 'http://SERVIDOR_ORIGINAL:PUERTO' });
  });
});

server.listen(8080);
console.log('🔄 Proxy escuchando en puerto 8080');
```

---

### **MÉTODO 5: Script de Polling** 🔄

Si el sistema tiene una API para consultar eventos recientes:

```javascript
// scripts/poll-camera-api.js
const axios = require('axios');

let lastEventId = null;

async function checkNewEvents() {
  try {
    // Consultar API del sistema de cámaras
    const response = await axios.get('http://CAMERA_SYSTEM_IP/api/events/recent');
    const events = response.data;
    
    for (const event of events) {
      // Si es nuevo y es Eduardo
      if (event.id !== lastEventId && event.personName === 'Eduardo Cuervo') {
        lastEventId = event.id;
        
        // Enviar a nuestro sistema
        await axios.post('http://localhost:3000/api/v1/terminals/identify-callback', {
          personId: 'dd87444b-4cfc-4adb-8222-53ee7e26c956',
          ip: event.cameraIp,
          temp: event.temperature,
          imgBase64: event.photo
        });
        
        console.log('✅ Nuevo evento de Eduardo enviado');
      }
    }
  } catch (error) {
    console.error('Error consultando API:', error.message);
  }
}

// Consultar cada 2 segundos
setInterval(checkNewEvents, 2000);
console.log('🔄 Monitoreando API de cámaras...');
```

---

## 📋 Información que Necesito

Para ayudarte a implementar la integración correcta, necesito saber:

### **1. ¿Qué sistema de cámaras usas?**
- [ ] Marca/Modelo: _______________
- [ ] Software: _______________
- [ ] Versión: _______________

### **2. ¿Cómo almacena los eventos?**
- [ ] Base de datos (¿cuál?): _______________
- [ ] Archivos de log (¿dónde?): _______________
- [ ] API REST (¿URL?): _______________
- [ ] No sé / Otro: _______________

### **3. ¿Tiene configuración de webhooks/callbacks?**
- [ ] Sí, en: _______________
- [ ] No
- [ ] No sé

### **4. ¿Puedes acceder a?**
- [ ] Archivos de configuración
- [ ] Base de datos
- [ ] Archivos de log
- [ ] Panel de administración web
- [ ] Documentación de API

### **5. ¿Dónde está instalado?**
- [ ] Misma máquina que nuestro servidor
- [ ] Otra máquina en la red (IP: _______)
- [ ] Servidor remoto

---

## 🚀 Implementación Rápida (Sin conocer el sistema)

Si no sabes los detalles técnicos, podemos usar un **enfoque universal**:

### **Script de Monitoreo Universal:**

```javascript
// scripts/universal-monitor.js
const axios = require('axios');
const fs = require('fs');
const path = require('path');

// Configuración
const CONFIG = {
  // Carpetas comunes donde buscar logs
  logPaths: [
    'C:\\Program Files\\CameraSystem\\logs',
    'C:\\ProgramData\\CameraSystem\\logs',
    'C:\\Logs',
    'C:\\Users\\Public\\Documents\\CameraLogs'
  ],
  
  // Patrones a buscar en archivos
  searchPatterns: [
    'Eduardo Cuervo',
    'EDUARDO CUERVO',
    'eduardo.cuervo',
    'eduardo_cuervo'
  ],
  
  // Intervalo de escaneo (ms)
  scanInterval: 5000
};

let lastScan = {};

async function scanForEvents() {
  for (const logPath of CONFIG.logPaths) {
    if (!fs.existsSync(logPath)) continue;
    
    const files = fs.readdirSync(logPath);
    
    for (const file of files) {
      const filePath = path.join(logPath, file);
      const stats = fs.statSync(filePath);
      
      // Si el archivo fue modificado desde el último escaneo
      if (!lastScan[filePath] || stats.mtime > lastScan[filePath]) {
        lastScan[filePath] = stats.mtime;
        
        // Leer contenido
        const content = fs.readFileSync(filePath, 'utf8');
        
        // Buscar patrones
        for (const pattern of CONFIG.searchPatterns) {
          if (content.includes(pattern)) {
            console.log(`📸 Detección encontrada en ${file}`);
            
            // Enviar evento
            await sendEvent();
            break;
          }
        }
      }
    }
  }
}

async function sendEvent() {
  try {
    await axios.post('http://localhost:3000/api/v1/terminals/identify-callback', {
      personId: 'dd87444b-4cfc-4adb-8222-53ee7e26c956',
      ip: '192.168.1.201',
      temp: 36.5
    });
    console.log('✅ Evento enviado al dashboard');
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

// Iniciar monitoreo
console.log('🔍 Iniciando monitoreo universal...');
setInterval(scanForEvents, CONFIG.scanInterval);
scanForEvents(); // Primera ejecución inmediata
```

---

## 📊 Diagrama de Flujo

```
Sistema de Cámaras
       ↓
   Reconoce a Eduardo
       ↓
   Emite sonido "Eduardo Cuervo"
       ↓
   [AQUÍ NECESITAMOS INTERCEPTAR] ← Script de Integración
       ↓
   POST a /api/v1/terminals/identify-callback
       ↓
   Nuestro Backend
       ↓
   WebSocket → Dashboard
       ↓
   Usuario ve notificación en tiempo real
```

---

## 🎯 Próximos Pasos

**Dime:**

1. **¿Qué sistema de cámaras usas?** (marca/modelo)
2. **¿Dónde se guardan los eventos?** (logs, BD, etc.)
3. **¿Puedes ver algún archivo de log cuando Eduardo es detectado?**
4. **¿El sistema tiene alguna interfaz web de administración?**

Con esa información, puedo crear el script exacto que necesitas para conectar tu sistema de cámaras con el dashboard.

---

## 💡 Mientras Tanto...

Puedes probar el sistema con simulaciones:

```powershell
# Simular que Eduardo es detectado cada 5 segundos
npm run test:eduardo
```

Esto te permite ver cómo funcionará el dashboard cuando lo conectemos con tu sistema real.
