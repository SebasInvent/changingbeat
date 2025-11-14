# 🎥 Configuración del Terminal Biométrico

## 📋 Información del Usuario Creado

**Eduardo Cuervo** ya está registrado en el sistema:
- **ID**: `dd87444b-4cfc-4adb-8222-53ee7e26c956`
- **Email**: eduardo.cuervo@example.com
- **Biometric ID**: eduardo-cuervo-001

---

## 🔧 Configurar el Terminal para Enviar Eventos

### **Paso 1: Identificar la IP del Terminal**

El terminal que está reconociendo a Eduardo debe tener una IP. Las IPs configuradas son:
- 192.168.1.201
- 192.168.1.202
- 192.168.1.208

**¿Cuál es la IP de tu terminal?** Necesitamos saberla para configurar el callback.

---

### **Paso 2: Configurar el Callback URL**

El terminal debe enviar los eventos de identificación a:
```
http://TU_IP_DEL_SERVIDOR:3000/api/v1/terminals/identify-callback
```

**Ejemplo:**
Si tu servidor está en la misma máquina que el terminal:
```
http://localhost:3000/api/v1/terminals/identify-callback
```

Si está en otra máquina en la red:
```
http://192.168.1.X:3000/api/v1/terminals/identify-callback
```

---

### **Paso 3: Formato del Callback**

El terminal debe enviar un POST con este formato JSON:

```json
{
  "personId": "dd87444b-4cfc-4adb-8222-53ee7e26c956",
  "ip": "192.168.1.201",
  "temp": 36.5,
  "imgBase64": "data:image/jpeg;base64,..."
}
```

**Campos:**
- `personId`: El ID del usuario (Eduardo Cuervo)
- `ip`: IP del terminal
- `temp`: Temperatura medida (opcional)
- `imgBase64`: Foto capturada en base64 (opcional)

---

## 🧪 Probar Manualmente (Sin Terminal Real)

Si quieres probar que el sistema funciona antes de configurar el terminal:

### **Opción A: Desde PowerShell**

```powershell
$body = @{
    personId = "dd87444b-4cfc-4adb-8222-53ee7e26c956"
    ip = "192.168.1.201"
    temp = 36.5
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:3000/api/v1/terminals/identify-callback" `
    -Method POST `
    -Body $body `
    -ContentType "application/json"
```

### **Opción B: Desde curl**

```bash
curl -X POST http://localhost:3000/api/v1/terminals/identify-callback \
  -H "Content-Type: application/json" \
  -d '{
    "personId": "dd87444b-4cfc-4adb-8222-53ee7e26c956",
    "ip": "192.168.1.201",
    "temp": 36.5
  }'
```

### **Opción C: Desde Postman/Thunder Client**

1. Método: **POST**
2. URL: `http://localhost:3000/api/v1/terminals/identify-callback`
3. Headers: `Content-Type: application/json`
4. Body (raw JSON):
```json
{
  "personId": "dd87444b-4cfc-4adb-8222-53ee7e26c956",
  "ip": "192.168.1.201",
  "temp": 36.5
}
```

---

## 📊 ¿Qué Pasará Cuando Funcione?

Cuando el terminal envíe un evento de identificación:

### **1. En el Dashboard (http://localhost:3000)**
- ✅ Aparecerá una notificación toast: "✅ Acceso Autorizado - Eduardo Cuervo"
- ✅ Se agregará al stream de actividad en vivo
- ✅ Sonará una notificación
- ✅ Las estadísticas se actualizarán
- ✅ Aparecerá en la tabla de registros recientes

### **2. En los Logs del Servidor**
Verás algo como:
```
info: 📨 Callback de identificación recibido
info: ✅ Acceso autorizado: Eduardo Cuervo
info: 📤 Emitiendo nuevo registro a todos los clientes
```

### **3. En la Base de Datos**
Se creará un registro con:
- Usuario: Eduardo Cuervo
- Terminal: IP del terminal
- Tipo: entry
- Temperatura: (si se envió)
- Fecha/Hora: Timestamp actual
- Foto: (si se envió)

---

## 🔍 Verificar que Está Funcionando

### **Ver Logs en Tiempo Real:**

```powershell
Get-Content logs\combined.log -Wait -Tail 20
```

### **Ver Solo Errores:**

```powershell
Get-Content logs\error.log -Wait -Tail 20
```

### **Verificar Registros en la BD:**

```powershell
node -e "
const mongoose = require('mongoose');
const { Record } = require('./src/models');
mongoose.connect('mongodb://localhost:27017/autoregistro').then(async () => {
  const records = await Record.find().sort({createdAt: -1}).limit(5).populate('userId');
  console.log(JSON.stringify(records, null, 2));
  process.exit(0);
});
"
```

---

## 🎯 Configuración del Terminal Real

### **Si tu terminal es compatible con la API:**

1. **Accede a la interfaz web del terminal** (usualmente http://IP_TERMINAL)

2. **Busca la sección de Callbacks o Webhooks**

3. **Configura:**
   - **Callback URL**: `http://TU_IP:3000/api/v1/terminals/identify-callback`
   - **Método**: POST
   - **Formato**: JSON

4. **Guarda y prueba**

### **Usando nuestra API para configurar:**

```powershell
$body = @{
    terminalIp = "192.168.1.201"
    callbackUrl = "http://TU_IP:3000/api/v1/terminals/identify-callback"
} | ConvertTo-Json

# Necesitas un token de admin
Invoke-RestMethod -Uri "http://localhost:3000/api/v1/terminals/callback" `
    -Method POST `
    -Body $body `
    -ContentType "application/json" `
    -Headers @{Authorization = "Bearer TU_TOKEN_AQUI"}
```

---

## 🚨 Troubleshooting

### **Problema: No llegan eventos**

1. **Verifica que el terminal pueda alcanzar el servidor:**
   ```powershell
   Test-NetConnection -ComputerName TU_IP -Port 3000
   ```

2. **Verifica el firewall:**
   - El puerto 3000 debe estar abierto
   - Windows Firewall puede estar bloqueando

3. **Verifica los logs del terminal:**
   - Busca errores de conexión
   - Verifica que esté enviando a la URL correcta

### **Problema: Eventos llegan pero no se registran**

1. **Verifica el formato del JSON:**
   - Debe incluir `personId`
   - El `personId` debe existir en la BD

2. **Verifica los logs del servidor:**
   ```powershell
   Get-Content logs\error.log -Tail 50
   ```

### **Problema: Usuario no encontrado**

El `personId` que envía el terminal debe coincidir con el ID en nuestra BD:
```
dd87444b-4cfc-4adb-8222-53ee7e26c956
```

---

## 📞 Información de Contacto

**Usuario en el Sistema:**
- Nombre: Eduardo Cuervo
- ID: dd87444b-4cfc-4adb-8222-53ee7e26c956
- Email: eduardo.cuervo@example.com

**Endpoints Importantes:**
- Callback: `POST /api/v1/terminals/identify-callback`
- Health: `GET /api/v1/health`
- Dashboard: `http://localhost:3000`

---

## ✅ Checklist de Configuración

- [ ] Usuario Eduardo Cuervo creado en BD
- [ ] IP del terminal identificada
- [ ] Callback URL configurada en el terminal
- [ ] Firewall permite conexiones al puerto 3000
- [ ] Dashboard abierto en navegador
- [ ] Logs del servidor visibles
- [ ] Prueba manual exitosa
- [ ] Terminal enviando eventos automáticamente

---

**¿Necesitas ayuda?** 
Revisa los logs en tiempo real y dime qué ves cuando Eduardo se mueve frente a la cámara.
