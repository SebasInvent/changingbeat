# 🎯 Conectar Sistema FaceOpen con Dashboard

## ✅ LO QUE SABEMOS:

Tu sistema de reconocimiento facial:
- **Software**: Face Recognition System
- **Ubicación**: `C:\Program Files (x86)\Face recognition system`
- **Base de Datos**: SQL Server (FaceOpen)
- **Puerto BD**: 26888
- **Estado**: ✅ Funcionando (reconoce a Eduardo Cuervo)

---

## 🔧 OPCIONES DE INTEGRACIÓN

### **OPCIÓN 1: Monitorear Base de Datos** 📊 (Recomendado)

#### **Paso 1: Iniciar SQL Server**

El sistema usa SQL Server. Necesitamos iniciarlo:

```powershell
# Buscar servicios de SQL
Get-Service | Where-Object {$_.Name -like "*SQL*"}

# Iniciar el servicio (ajusta el nombre)
Start-Service "MSSQL$LESUNMINISQL"
```

#### **Paso 2: Ejecutar Monitor**

```powershell
npm run monitor:faceopen
```

Este script:
- Se conecta a la BD FaceOpen
- Detecta cuando Eduardo es reconocido
- Envía el evento al dashboard automáticamente

---

### **OPCIÓN 2: Monitorear Archivos del Sistema** 📁

Si el sistema guarda fotos o logs cuando reconoce a alguien:

#### **Script de Monitoreo de Carpetas:**

```powershell
# Ejecutar este script en PowerShell
$folder = "C:\Program Files (x86)\Face recognition system"
$filter = "*.*"

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $folder
$watcher.Filter = $filter
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

$action = {
    $path = $Event.SourceEventArgs.FullPath
    $changeType = $Event.SourceEventArgs.ChangeType
    Write-Host "📸 Archivo detectado: $path"
    
    # Si contiene "Eduardo" o "Cuervo"
    if ($path -match "Eduardo|Cuervo") {
        Write-Host "✅ Es Eduardo Cuervo!"
        
        # Enviar al dashboard
        $body = @{
            personId = "dd87444b-4cfc-4adb-8222-53ee7e26c956"
            ip = "192.168.1.201"
            temp = 36.5
        } | ConvertTo-Json
        
        Invoke-RestMethod -Uri "http://localhost:3000/api/v1/terminals/identify-callback" `
            -Method POST -Body $body -ContentType "application/json"
    }
}

Register-ObjectEvent $watcher "Created" -Action $action
Register-ObjectEvent $watcher "Changed" -Action $action

Write-Host "👀 Monitoreando carpeta: $folder"
Write-Host "Presiona Ctrl+C para detener"

while ($true) { Start-Sleep 1 }
```

---

### **OPCIÓN 3: Interceptar Sonido** 🔊

Ya que el sistema emite un sonido diciendo "Eduardo Cuervo", podemos:

1. **Usar software de captura de audio**
2. **Detectar cuando se reproduce el sonido**
3. **Enviar evento al dashboard**

#### **Script con Reconocimiento de Audio:**

```javascript
// Requiere: npm install node-record-lpcm16 @google-cloud/speech
const record = require('node-record-lpcm16');
const speech = require('@google-cloud/speech');
const axios = require('axios');

const client = new speech.SpeechClient();

const recording = record.record({
  sampleRateHertz: 16000,
  threshold: 0,
  verbose: false,
  recordProgram: 'sox', // o 'rec'
  silence: '10.0',
});

const recognizeStream = client
  .streamingRecognize({
    config: {
      encoding: 'LINEAR16',
      sampleRateHertz: 16000,
      languageCode: 'es-ES',
    },
    interimResults: false,
  })
  .on('data', async (data) => {
    const transcript = data.results[0]?.alternatives[0]?.transcript || '';
    
    if (transcript.toLowerCase().includes('eduardo cuervo')) {
      console.log('🎤 Detectado: "Eduardo Cuervo"');
      
      // Enviar al dashboard
      await axios.post('http://localhost:3000/api/v1/terminals/identify-callback', {
        personId: 'dd87444b-4cfc-4adb-8222-53ee7e26c956',
        ip: '192.168.1.201',
        temp: 36.5
      });
    }
  });

recording.stream().pipe(recognizeStream);
console.log('🎤 Escuchando audio del sistema...');
```

---

### **OPCIÓN 4: Usar el Sistema Antiguo** 🔄

Si tienes el código del sistema antiguo funcionando:

#### **Modificar el Código Existente:**

Busca en el código donde se hace el reconocimiento y agrega:

```javascript
// Cuando se reconoce a alguien
function onPersonRecognized(personName, personId) {
    // Código existente...
    
    // AGREGAR ESTO:
    const axios = require('axios');
    axios.post('http://localhost:3000/api/v1/terminals/identify-callback', {
        personId: personId,
        ip: '192.168.1.201',
        temp: 36.5
    }).catch(err => console.error('Error enviando evento:', err));
}
```

---

### **OPCIÓN 5: Webhook/API del Sistema** 🌐

Si el sistema tiene configuración de webhooks:

1. **Busca en la interfaz del sistema:**
   - Configuración
   - Notificaciones
   - Webhooks
   - Callbacks
   - HTTP Notifications

2. **Configura esta URL:**
   ```
   http://localhost:3000/api/v1/terminals/identify-callback
   ```

---

## 🚀 SOLUCIÓN RÁPIDA (Mientras investigamos)

### **Usar Simulación Temporal:**

Mientras configuramos la integración real, puedes:

```powershell
# Terminal 1: Servidor
npm start

# Terminal 2: Dashboard
start http://localhost:3000

# Terminal 3: Simulación de Eduardo
npm run test:eduardo
```

Esto simula que Eduardo es detectado cada 3 segundos.

---

## 📋 CHECKLIST DE INVESTIGACIÓN

Para ayudarte mejor, necesito que verifiques:

### **1. Archivos del Sistema**
- [ ] ¿Hay archivos .exe en la carpeta del sistema?
- [ ] ¿Cuál es el ejecutable principal?
- [ ] ¿Hay archivos de configuración (.ini, .conf, .xml)?

### **2. Base de Datos**
- [ ] ¿SQL Server está corriendo?
- [ ] ¿Puedes conectarte con SQL Server Management Studio?
- [ ] ¿Qué tablas tiene la BD FaceOpen?

### **3. Logs y Eventos**
- [ ] ¿Se crean archivos cuando Eduardo es reconocido?
- [ ] ¿Dónde se guardan las fotos capturadas?
- [ ] ¿Hay logs de texto que se actualicen?

### **4. Interfaz**
- [ ] ¿El sistema tiene interfaz gráfica?
- [ ] ¿Hay panel web de administración?
- [ ] ¿Qué opciones de configuración tiene?

---

## 🎯 PRÓXIMOS PASOS

### **Paso 1: Identificar el Método**

Ejecuta estos comandos y comparte los resultados:

```powershell
# Ver procesos del sistema
Get-Process | Where-Object {$_.Path -like "*Face recognition*"}

# Ver servicios
Get-Service | Where-Object {$_.DisplayName -like "*Face*"}

# Listar archivos ejecutables
Get-ChildItem "C:\Program Files (x86)\Face recognition system" -Recurse -Include *.exe

# Ver si SQL Server está corriendo
Get-Service | Where-Object {$_.Name -like "*SQL*"}
```

### **Paso 2: Probar Conexión a BD**

Si SQL Server está corriendo:

```powershell
npm run monitor:faceopen
```

### **Paso 3: Monitorear Archivos**

Mientras tanto, ejecuta el monitor de archivos para ver si se crean archivos nuevos cuando Eduardo es detectado.

---

## 💡 MIENTRAS TANTO...

El dashboard ya está funcionando y listo para recibir eventos. Solo necesitamos conectar tu sistema de cámaras.

**Prueba el sistema completo:**

```powershell
# Terminal 1
npm start

# Terminal 2
npm run test:eduardo

# Navegador
http://localhost:3000
```

Verás cómo funcionará cuando lo conectemos con tu sistema real.

---

## 📞 ¿NECESITAS AYUDA?

Comparte:
1. Capturas de pantalla de la interfaz del sistema
2. Contenido de archivos de configuración
3. Nombres de los ejecutables principales
4. Si SQL Server está corriendo o no

Con esa información, puedo crear el script exacto que necesitas.
