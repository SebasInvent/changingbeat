# 🚀 SISTEMA DE CONTROL DE ACCESO - INICIO RÁPIDO

## ✅ **ESTADO ACTUAL: SISTEMA OPERATIVO**

```
🟢 Servidor Node.js: CORRIENDO
🟢 MongoDB: CONECTADO  
🟢 Dashboard: DISPONIBLE
🟢 Monitor de archivos: ACTIVO
🟢 WebSocket: FUNCIONANDO
🟢 Usuario Eduardo Cuervo: LISTO
```

---

## 🎯 **ACCESO RÁPIDO:**

### **Dashboard Principal:**
```
http://localhost:3000
```

### **Documentación API:**
```
http://localhost:3000/api-docs
```

---

## 🎥 **CÓMO USAR EL SISTEMA:**

### **Método 1: Cámara Real (Producción)**
```
1. Párate frente a la cámara WDR IR
2. El sistema Face Recognition te reconocerá
3. El evento aparecerá automáticamente en el dashboard
```

### **Método 2: Simulación (Pruebas)**
```powershell
# Simular UNA detección de Eduardo
npm run test:eduardo:once

# Simular detecciones CONTINUAS (cada 3 seg)
npm run test:eduardo
```

---

## 📊 **TERMINALES ACTIVAS:**

### **Terminal 1: Servidor Principal**
```powershell
# Ya está corriendo en segundo plano
# Ver logs:
Get-Content logs\combined.log -Wait -Tail 20
```

### **Terminal 2: Monitor de Archivos FaceOpen**
```powershell
# Ya está corriendo
# Detecta cambios en la base de datos del sistema de cámaras
```

### **Terminal 3: Pruebas (Opcional)**
```powershell
# Para hacer pruebas manuales
npm run test:eduardo:once
```

---

## 🎊 **LO QUE VERÁS EN EL DASHBOARD:**

### **Cuando Eduardo sea detectado:**

1. **Notificación Toast** (esquina superior derecha)
   ```
   ✅ Acceso Autorizado
   Eduardo Cuervo
   Terminal 192.168.1.201 - 35.9°C
   ```

2. **Stream de Actividad en Vivo**
   ```
   ✓ Acceso Autorizado
     Eduardo Cuervo | Terminal 192.168.1.201 | 35.9°C
     01:22:29
   ```

3. **Estadísticas Actualizadas**
   - Contador de registros aumenta
   - Gráficas se actualizan
   - Tabla de registros recientes se refresca

4. **Sonido de Notificación** 🔊

---

## 🔧 **COMANDOS DISPONIBLES:**

```powershell
# Iniciar servidor
npm start

# Monitorear archivos FaceOpen
npm run monitor:files

# Probar con Eduardo (una vez)
npm run test:eduardo:once

# Probar con Eduardo (continuo)
npm run test:eduardo

# Analizar sistema completo
npm run analyze

# Diagnosticar cámaras
npm run diagnose

# Poblar datos de prueba
npm run seed

# Ver logs en tiempo real
Get-Content logs\combined.log -Wait
```

---

## 🎮 **PRUEBA RÁPIDA (30 segundos):**

### **Paso 1: Abre el Dashboard**
```
http://localhost:3000
```

### **Paso 2: Ejecuta una simulación**
```powershell
npm run test:eduardo:once
```

### **Paso 3: Observa**
- ✅ Notificación aparece
- ✅ Stream se actualiza
- ✅ Contador aumenta
- ✅ Sonido se reproduce

---

## 📱 **DISPOSITIVOS CONECTADOS:**

| Dispositivo | Estado | Descripción |
|-------------|--------|-------------|
| **Cámara WDR IR** | 🟢 Conectada | Reconocimiento facial |
| **Puerto COM8** | 🟢 Listo | Lector de cédulas MRZ |
| **MongoDB** | 🟢 Activo | Base de datos principal |
| **SQL Server** | 🟢 Detectado | Base de datos FaceOpen |
| **Terminal .201** | ⚪ Configurado | Biométrico (offline) |
| **Terminal .202** | ⚪ Configurado | Biométrico (offline) |
| **Terminal .208** | ⚪ Configurado | Biométrico (offline) |

---

## 🔍 **MONITOREO:**

### **Ver actividad en tiempo real:**
```powershell
# Logs del servidor
Get-Content logs\combined.log -Wait

# Busca estas líneas cuando Eduardo sea detectado:
# ✅ Acceso autorizado: Eduardo Cuervo
# 📤 Emitiendo nuevo registro a todos los clientes
```

### **Ver estado del sistema:**
```powershell
npm run analyze
```

---

## 🎯 **ARQUITECTURA DEL SISTEMA:**

```
┌─────────────────────────────────────────────┐
│    SERVIDOR (192.168.1.39)                  │
├─────────────────────────────────────────────┤
│                                             │
│  🎥 Cámara WDR IR                          │
│     └─> Face Recognition System             │
│         └─> FaceOpen_Data.MDF              │
│             └─> Monitor de Archivos 🟢      │
│                 └─> Backend API 🟢          │
│                     └─> WebSocket 🟢        │
│                         └─> Dashboard 🟢    │
│                                             │
│  📡 Puerto COM8 🟢                          │
│     └─> Lector MRZ de Cédulas              │
│                                             │
│  💾 Bases de Datos:                         │
│     ├─> MongoDB :27017 🟢                   │
│     └─> SQL Server :26888 🟢                │
│                                             │
└─────────────────────────────────────────────┘
```

---

## 🚨 **SOLUCIÓN DE PROBLEMAS:**

### **Dashboard no carga:**
```powershell
# Verificar servidor
Get-Process -Name node

# Reiniciar si es necesario
npm start
```

### **No aparecen notificaciones:**
```powershell
# Verificar monitor
# Debería estar en Terminal 2

# Si no, ejecutar:
npm run monitor:files
```

### **Probar manualmente:**
```powershell
npm run test:eduardo:once
```

---

## 📚 **DOCUMENTACIÓN ADICIONAL:**

- **`READY_TO_USE.md`** - Guía completa de uso
- **`SYSTEM_ANALYSIS_REPORT.md`** - Análisis técnico del sistema
- **`INTEGRATION_GUIDE.md`** - Opciones de integración
- **`CONNECT_FACEOPEN.md`** - Conexión con Face Recognition
- **`TERMINAL_SETUP.md`** - Configuración de terminales
- **`QUICK_START.md`** - Guía de inicio rápido

---

## 🎊 **¡SISTEMA LISTO!**

### **Todo está funcionando:**
- ✅ Servidor activo
- ✅ Monitor detectando cambios
- ✅ Dashboard mostrando datos
- ✅ WebSocket en tiempo real
- ✅ Base de datos conectada

### **Puedes:**
1. Moverte frente a la cámara
2. Simular eventos con comandos
3. Ver estadísticas en tiempo real
4. Monitorear todos los accesos

---

**¡Disfruta tu sistema de control de acceso! 🚀**

---

**Última actualización:** ${new Date().toLocaleString('es-ES')}  
**Estado:** 🟢 OPERATIVO  
**Versión:** 2.0.0
