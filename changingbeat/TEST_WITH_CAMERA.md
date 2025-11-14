# 🎥 PRUEBA CON CÁMARA LOCAL - GUÍA PASO A PASO

## ✅ **PREPARACIÓN:**

### **Estado Actual del Sistema:**
```
✅ Servidor Node.js: CORRIENDO
✅ Monitor de archivos: ACTIVO
✅ Dashboard: DISPONIBLE
✅ Cámara WDR IR: CONECTADA
✅ Face Recognition System: INSTALADO
```

---

## 🚀 **PASOS PARA PROBAR:**

### **Paso 1: Verificar que todo esté corriendo**

Abre PowerShell y verifica:

```powershell
# Ver procesos Node activos
Get-Process -Name node

# Deberías ver:
# - Servidor principal (puerto 3000)
# - Monitor de archivos
```

---

### **Paso 2: Abrir el Dashboard**

```powershell
start http://localhost:3000
```

O abre manualmente en tu navegador:
```
http://localhost:3000
```

**Qué verás:**
- 📊 Estadísticas del sistema
- 📋 Tabla de registros recientes
- 🔔 Área de notificaciones (esquina superior derecha)
- 📡 Indicador de conexión WebSocket (debe estar verde)

---

### **Paso 3: Verificar Monitor de Archivos**

El monitor debe estar corriendo. Si no está, ejecútalo:

```powershell
npm run monitor:files
```

**Verás algo como:**
```
═══════════════════════════════════════════════════════
🎥 MONITOR DE ARCHIVOS FACEOPEN
═══════════════════════════════════════════════════════

📂 Rutas monitoreadas:
   DB: C:\Program Files (x86)\Face recognition system\...
   
✅ database: Encontrado
✅ log: Encontrado
✅ dataFolder: Encontrado

🔄 Iniciando monitoreo...
💡 Muévete frente a la cámara para generar eventos
👀 FileWatcher activo en carpeta de datos
```

---

### **Paso 4: Iniciar Face Recognition System**

1. **Busca el ejecutable:**
   ```
   C:\Program Files (x86)\Face recognition system\
   ```

2. **Ejecuta la aplicación de Face Recognition**
   - Busca el archivo `.exe` principal
   - Puede llamarse: `FaceRecognition.exe`, `FaceOpen.exe`, o similar

3. **Verifica que la cámara esté activa**
   - Debe aparecer la imagen de la cámara
   - Debe estar en modo de reconocimiento

---

### **Paso 5: Probar Reconocimiento**

#### **Opción A: Con tu rostro (si estás registrado)**

1. Párate frente a la cámara WDR IR
2. Espera a que el sistema te reconozca
3. Observa:
   - ✅ Face Recognition System muestra tu nombre
   - ✅ Monitor detecta cambio en archivo
   - ✅ Dashboard muestra notificación

#### **Opción B: Registrar a Eduardo Cuervo**

Si Eduardo no está en Face Recognition System:

1. **Abrir Face Recognition System**
2. **Ir a sección de usuarios/personas**
3. **Agregar nuevo usuario:**
   - Nombre: Eduardo Cuervo
   - ID: eduardo-cuervo-001
   - Capturar foto con la cámara
4. **Guardar**
5. **Probar reconocimiento**

---

### **Paso 6: Observar el Dashboard**

Cuando alguien sea reconocido, verás:

#### **1. Notificación Toast (esquina superior derecha)**
```
┌─────────────────────────────────┐
│ ✅ Acceso Autorizado            │
│ Eduardo Cuervo                  │
│ Terminal 192.168.1.201          │
│ Temperatura: 36.5°C             │
└─────────────────────────────────┘
```

#### **2. Stream de Actividad**
```
✓ Acceso Autorizado
  Eduardo Cuervo | Terminal 192.168.1.201 | 36.5°C
  01:35:23
```

#### **3. Contador Actualizado**
El número de "Registros Hoy" aumentará.

#### **4. Tabla de Registros**
Aparecerá una nueva fila con el acceso.

#### **5. Sonido** 🔊
Se reproducirá un sonido de notificación.

---

### **Paso 7: Verificar en Logs**

Abre otra terminal y ejecuta:

```powershell
Get-Content logs\combined.log -Wait -Tail 20
```

**Busca estas líneas:**
```
📸 Base de datos modificada
✅ Evento enviado al dashboard
info: ✅ Acceso autorizado: Eduardo Cuervo
info: 📤 Emitiendo nuevo registro a todos los clientes
```

---

## 🔍 **TROUBLESHOOTING:**

### **Problema 1: Face Recognition no inicia**

```powershell
# Buscar todos los ejecutables
Get-ChildItem "C:\Program Files (x86)\Face recognition system" -Recurse -Include *.exe

# Ejecutar el principal
```

### **Problema 2: Cámara no se ve**

1. Verifica que esté conectada:
   ```powershell
   Get-PnpDevice | Where-Object {$_.FriendlyName -like "*camera*"}
   ```

2. Reinicia Face Recognition System

### **Problema 3: No aparece notificación en dashboard**

1. **Verifica WebSocket:**
   - Debe haber un indicador verde en el dashboard
   - Si está rojo, recarga la página

2. **Verifica el monitor:**
   ```powershell
   # Debe estar corriendo
   Get-Process -Name node
   ```

3. **Prueba manualmente:**
   ```powershell
   npm run test:eduardo:once
   ```
   Si esto funciona, el problema es con Face Recognition.

### **Problema 4: Monitor no detecta cambios**

1. **Verifica permisos:**
   El monitor necesita leer:
   ```
   C:\Program Files (x86)\Face recognition system\DataBase\Data\
   ```

2. **Ejecuta como administrador:**
   ```powershell
   # Cierra el monitor y ejecuta PowerShell como admin
   npm run monitor:files
   ```

---

## 🎮 **PRUEBA RÁPIDA (Sin cámara):**

Si quieres verificar que el dashboard funciona sin usar la cámara:

```powershell
npm run test:eduardo:once
```

Esto simula que Eduardo fue detectado. Deberías ver:
- ✅ Notificación en dashboard
- ✅ Mensaje en logs
- ✅ Contador actualizado

---

## 📊 **FLUJO COMPLETO:**

```
1. Face Recognition System detecta rostro
        ↓
2. Procesa y reconoce a la persona
        ↓
3. Guarda evento en FaceOpen_Data.MDF
        ↓
4. Archivo se modifica (timestamp cambia)
        ↓
5. Monitor detecta cambio con FileWatcher
        ↓
6. Monitor envía POST a /api/v1/terminals/identify-callback
        ↓
7. Backend procesa y guarda en MongoDB
        ↓
8. Backend emite evento WebSocket
        ↓
9. Dashboard recibe evento
        ↓
10. Dashboard muestra notificación
        ↓
11. Usuario ve: "✅ Eduardo Cuervo - 36.5°C"
```

---

## 🎯 **CHECKLIST DE VERIFICACIÓN:**

Antes de probar con la cámara, verifica:

- [ ] Servidor Node.js corriendo (`npm start`)
- [ ] Monitor de archivos activo (`npm run monitor:files`)
- [ ] Dashboard abierto (`http://localhost:3000`)
- [ ] Face Recognition System ejecutándose
- [ ] Cámara WDR IR conectada y funcionando
- [ ] Usuario registrado en Face Recognition System

---

## 💡 **TIPS:**

1. **Primera vez:** Registra tu propio rostro primero para probar
2. **Iluminación:** Asegúrate de tener buena luz
3. **Distancia:** Párate a 50cm-1m de la cámara
4. **Paciencia:** El reconocimiento puede tomar 1-3 segundos
5. **Logs:** Mantén los logs abiertos para debugging

---

## 🎊 **ÉXITO:**

Cuando todo funcione, verás:

```
Terminal 1 (Servidor):
  info: ✅ Acceso autorizado: Eduardo Cuervo
  info: 📤 Emitiendo nuevo registro

Terminal 2 (Monitor):
  ✅ Evento #1 enviado al dashboard
  Fuente: Base de datos FaceOpen

Dashboard:
  🔔 Notificación aparece
  📊 Estadísticas se actualizan
  🔊 Sonido se reproduce
```

---

## 📞 **SI NECESITAS AYUDA:**

1. **Captura de pantalla** del Face Recognition System
2. **Logs del monitor** (Terminal 2)
3. **Logs del servidor** (Terminal 1)
4. **Console del navegador** (F12 en el dashboard)

---

**¡Ahora prueba con la cámara y observa la magia en tiempo real!** 🚀
