# 🧪 Guía de Testing - Control de Acceso Biométrico

## 🚀 CÓMO PROBAR LA APLICACIÓN

### **Opción 1: Emulador Android (Más Rápido)** ⚡

#### **1. Instalar Dependencias**
```bash
cd "c:\Users\Sebastian\Desktop\A1A Face id\changingbeat"
flutter pub get
```

#### **2. Iniciar Emulador**
```bash
# Listar emuladores disponibles
flutter emulators

# Iniciar un emulador (ejemplo)
flutter emulators --launch Pixel_5_API_33

# O desde Android Studio: Tools > Device Manager > Play
```

#### **3. Ejecutar la App**
```bash
flutter run
```

**Nota:** El emulador puede tener limitaciones con la cámara. Para testing completo, usa un dispositivo real.

---

### **Opción 2: Dispositivo Real (Recomendado)** 📱

#### **1. Habilitar Modo Desarrollador en tu Teléfono**
- Android:
  1. Ve a Ajustes > Acerca del teléfono
  2. Toca 7 veces en "Número de compilación"
  3. Ve a Ajustes > Opciones de desarrollador
  4. Activa "Depuración USB"

#### **2. Conectar Dispositivo**
```bash
# Verificar que el dispositivo está conectado
flutter devices

# Deberías ver algo como:
# Android SDK built for x86 (mobile) • emulator-5554 • android-x86 • Android 13 (API 33)
# SM G991B (mobile) • XXXXXXXXX • android-arm64 • Android 13 (API 33)
```

#### **3. Ejecutar en el Dispositivo**
```bash
flutter run
```

Si hay múltiples dispositivos:
```bash
flutter run -d <device-id>
```

---

### **Opción 3: Modo Debug con Hot Reload** 🔥

```bash
# Ejecutar en modo debug (recomendado para desarrollo)
flutter run --debug

# Durante la ejecución:
# - Presiona 'r' para hot reload
# - Presiona 'R' para hot restart
# - Presiona 'q' para salir
```

---

## 🧪 PLAN DE TESTING

### **Fase 1: Testing Básico (15 min)**

#### **Test 1: SplashScreen y Navegación**
- [ ] La app inicia con SplashScreen
- [ ] Muestra animación del logo
- [ ] Verifica permisos de cámara
- [ ] Navega automáticamente al Login (primera vez)

#### **Test 2: Login**
- [ ] Pantalla de login se muestra correctamente
- [ ] Campos de usuario y contraseña funcionan
- [ ] Botón de login está habilitado
- [ ] **Credenciales de prueba:**
  - Usuario: `admin` o `operator`
  - Contraseña: `password123` (ajustar según tu API)
- [ ] Login exitoso navega al Dashboard
- [ ] Login fallido muestra error

#### **Test 3: Dashboard**
- [ ] Muestra nombre de usuario
- [ ] Muestra estadísticas (pueden estar en 0)
- [ ] Botones de navegación funcionan
- [ ] Pull-to-refresh funciona
- [ ] Botón de logout funciona

---

### **Fase 2: Testing de Captura (30 min)**

#### **Test 4: Captura de Documento**
1. Dashboard > "Iniciar Captura Biométrica"
2. Seleccionar "Registro Completo"
3. **DocumentScanScreen:**
   - [ ] Cámara trasera se activa
   - [ ] Guía visual (marco) se muestra
   - [ ] Botón "Capturar" funciona
   - [ ] Imagen capturada se muestra
   - [ ] Botón "Ingresar Datos" abre diálogo
4. **Formulario de Datos:**
   - [ ] Todos los campos se muestran
   - [ ] Tipo de documento seleccionable
   - [ ] Número de documento acepta números
   - [ ] Nombres y apellidos con capitalización
   - [ ] DatePicker funciona
   - [ ] Género seleccionable
   - [ ] Validación funciona (campos requeridos)
   - [ ] Botón "Continuar" navega a Facial

#### **Test 5: Captura Facial SIN Liveness**
1. **Primero, deshabilitar liveness:**
   - Dashboard > Settings
   - Desactivar "Liveness Detection"
   - Volver atrás
2. **Captura Facial:**
   - [ ] Cámara frontal se activa
   - [ ] Óvalo guía se muestra
   - [ ] Feedback de calidad aparece
   - [ ] Auto-captura está ON por defecto
   - [ ] Posicionar rostro en óvalo
   - [ ] Auto-captura funciona (5 frames)
   - [ ] Imagen capturada se muestra
   - [ ] Botón "Continuar" funciona

#### **Test 6: Captura Facial CON Liveness** ⭐
1. **Habilitar liveness:**
   - Dashboard > Settings
   - Activar "Liveness Detection"
   - Volver atrás
2. **Captura con Liveness:**
   - [ ] Cámara frontal se activa
   - [ ] Challenge 1 aparece (ej: "Parpadee 2 veces")
   - [ ] Instrucciones claras
   - [ ] Timer visible (10s)
   - [ ] Progreso se muestra (0% → 50%)
   - [ ] Realizar acción (parpadear)
   - [ ] Challenge 1 pasa ✅
   - [ ] Challenge 2 aparece (ej: "Gire su cabeza")
   - [ ] Realizar acción (girar cabeza)
   - [ ] Challenge 2 pasa ✅
   - [ ] Pantalla "¡Verificación Exitosa!" aparece
   - [ ] Botón "Continuar" activa auto-captura
   - [ ] Auto-captura funciona
   - [ ] Imagen capturada
   - [ ] Registro se envía a API

---

### **Fase 3: Testing de Validación (15 min)**

#### **Test 7: Validación Facial**
1. Dashboard > "Iniciar Captura Biométrica"
2. Seleccionar "Verificación Facial"
3. **Con Liveness:**
   - [ ] Challenges de liveness funcionan
   - [ ] Captura facial funciona
   - [ ] Botón "Validar" funciona
   - [ ] Resultado se muestra (match o no match)

---

### **Fase 4: Testing de Registros (10 min)**

#### **Test 8: Historial de Registros**
1. Dashboard > Tab "Registros" o botón "Ver Historial"
2. **RecordsScreen:**
   - [ ] Lista de registros se carga
   - [ ] Cards muestran información correcta
   - [ ] Badges de estado (Aprobado/Rechazado)
   - [ ] Estadísticas se muestran
   - [ ] Búsqueda funciona
   - [ ] Filtros funcionan
   - [ ] Scroll infinito funciona
   - [ ] Pull-to-refresh funciona
   - [ ] Click en registro muestra detalles

---

### **Fase 5: Testing de Settings (10 min)**

#### **Test 9: Configuración**
1. Dashboard > Settings
2. **Verificar todas las opciones:**
   - [ ] Tablet ID editable
   - [ ] Server URL editable
   - [ ] Auto-Captura toggle funciona
   - [ ] **Liveness Detection toggle funciona** ⭐
   - [ ] Sensibilidad slider funciona (50-95%)
   - [ ] Resolución de cámara seleccionable
   - [ ] Modo Debug toggle funciona
   - [ ] Limpiar Caché funciona
   - [ ] Restablecer Configuración funciona
   - [ ] Información de la app se muestra
   - [ ] Logout funciona

---

### **Fase 6: Testing de Persistencia (5 min)**

#### **Test 10: Sesión y Configuración**
1. **Cerrar la app completamente** (no solo minimizar)
2. **Abrir la app nuevamente**
3. Verificar:
   - [ ] SplashScreen aparece
   - [ ] Auto-navega al Dashboard (sesión guardada)
   - [ ] Configuración se mantiene
   - [ ] Liveness Detection mantiene estado

---

## 🐛 PROBLEMAS COMUNES Y SOLUCIONES

### **Problema 1: "No se encontraron cámaras"**
**Solución:**
- Emulador: Configurar cámara virtual en AVD Manager
- Real: Verificar permisos de cámara en Ajustes del teléfono

### **Problema 2: "Error al conectar con el servidor"**
**Solución:**
```dart
// Verificar que el servidor esté corriendo
// URL por defecto: https://access-control.eukahack.com/api/v1

// Para testing local, cambiar en Settings:
// http://10.0.2.2:3000/api/v1 (emulador)
// http://192.168.x.x:3000/api/v1 (dispositivo real)
```

### **Problema 3: "ML Kit no funciona"**
**Solución:**
- Verificar que Google Play Services esté actualizado
- Primera vez puede tardar en descargar modelos ML Kit
- Requiere conexión a internet la primera vez

### **Problema 4: "Liveness no detecta parpadeo"**
**Solución:**
- Parpadear de forma natural y completa
- Asegurar buena iluminación
- Rostro completamente visible
- No usar lentes oscuros

### **Problema 5: "Auto-captura no funciona"**
**Solución:**
- Verificar que está habilitado (icono en AppBar)
- Posicionar rostro en el óvalo
- Mantener posición estable por 1-2 segundos
- Verificar buena iluminación

---

## 📊 CHECKLIST DE TESTING COMPLETO

### **Funcionalidad Core:**
- [ ] Login/Logout
- [ ] Persistencia de sesión
- [ ] Auto-logout
- [ ] Dashboard con datos
- [ ] Captura de documento
- [ ] Captura facial
- [ ] Liveness detection
- [ ] Registro biométrico
- [ ] Validación biométrica
- [ ] Historial de registros
- [ ] Búsqueda y filtros
- [ ] Settings

### **UI/UX:**
- [ ] Navegación fluida
- [ ] Animaciones suaves
- [ ] Feedback visual claro
- [ ] Mensajes de error informativos
- [ ] Loading indicators
- [ ] Pull-to-refresh
- [ ] Scroll infinito

### **Rendimiento:**
- [ ] App inicia rápido (< 3s)
- [ ] Cámara fluida (> 30 FPS)
- [ ] Detección facial responsive
- [ ] Liveness sin lag
- [ ] Navegación sin delays

### **Seguridad:**
- [ ] Liveness previene foto impresa
- [ ] Liveness previene foto en pantalla
- [ ] Liveness previene video
- [ ] Token encriptado
- [ ] Auto-logout funciona

---

## 🎯 CREDENCIALES DE PRUEBA

### **Para API Real:**
```
URL: https://access-control.eukahack.com/api/v1
Usuario: admin
Contraseña: [Consultar con backend]
```

### **Para API Local (si aplica):**
```
URL: http://localhost:3000/api/v1
Usuario: admin
Contraseña: password123
```

---

## 📱 COMANDOS ÚTILES

### **Ver logs en tiempo real:**
```bash
flutter logs
```

### **Limpiar build:**
```bash
flutter clean
flutter pub get
```

### **Rebuild completo:**
```bash
flutter clean
flutter pub get
flutter run
```

### **Ver dispositivos conectados:**
```bash
flutter devices
```

### **Instalar en dispositivo específico:**
```bash
flutter install -d <device-id>
```

---

## 🎬 GRABACIÓN DE TESTING

Para documentar el testing:

```bash
# Android (requiere adb)
adb shell screenrecord /sdcard/test.mp4

# Detener con Ctrl+C
# Descargar video
adb pull /sdcard/test.mp4
```

---

## ✅ CRITERIOS DE ÉXITO

La app está lista para producción si:

1. ✅ Todos los tests de Fase 1-6 pasan
2. ✅ No hay crashes
3. ✅ Liveness detection funciona correctamente
4. ✅ Registros se guardan en la API
5. ✅ Persistencia funciona
6. ✅ UI es fluida y responsive
7. ✅ Feedback es claro para el usuario

---

## 🚀 SIGUIENTE PASO DESPUÉS DE TESTING

1. **Documentar bugs encontrados**
2. **Ajustar configuración según necesidades**
3. **Capacitar operadores**
4. **Deployment en tablets de producción**
5. **Monitoreo y analytics**

---

**¡Buena suerte con el testing!** 🎉

Si encuentras algún problema, revisa la sección de "Problemas Comunes" o consulta los logs con `flutter logs`.
