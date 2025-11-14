# 🚀 Guía de Inicio Rápido

## ✅ Sistema Listo - ¿Qué hacer ahora?

### **1️⃣ Iniciar el Servidor**

```bash
# Opción A: Modo desarrollo (recomendado para empezar)
npm run dev

# Opción B: Modo producción
npm start
```

### **2️⃣ Abrir el Dashboard**

Una vez que el servidor inicie, abre tu navegador en:

```
http://localhost:3000
```

**¡Verás el dashboard completo con todas las estadísticas!**

---

## 📊 ¿Qué Puedes Ver en el Dashboard?

- ✅ Total de usuarios en el sistema
- ✅ Registros de acceso del día
- ✅ Estado de terminales biométricos
- ✅ Gráficas de actividad por hora
- ✅ Temperatura promedio
- ✅ Registros recientes en tiempo real
- ✅ Top terminales más activos

---

## 🔗 URLs Importantes

| Servicio | URL |
|----------|-----|
| **Dashboard** | http://localhost:3000 |
| **API Docs (Swagger)** | http://localhost:3000/api-docs |
| **Health Check** | http://localhost:3000/api/v1/health |
| **API Info** | http://localhost:3000/api |

---

## 🎯 Primeros Pasos Recomendados

### **A. Crear un Usuario Administrador**

Usa Postman, Thunder Client, o curl:

```bash
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "Admin",
    "lastName": "Sistema",
    "email": "admin@sistema.com",
    "password": "Admin123456",
    "role": "admin"
  }'
```

### **B. Login y Obtener Token**

```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@sistema.com",
    "password": "Admin123456"
  }'
```

Guarda el `token` de la respuesta.

### **C. Crear Usuarios de Prueba**

```bash
curl -X POST http://localhost:3000/api/v1/users \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TU_TOKEN_AQUI" \
  -d '{
    "firstName": "Juan",
    "lastName": "Pérez",
    "email": "juan@example.com",
    "password": "Juan123456",
    "phone": "3001234567"
  }'
```

### **D. Crear Registros de Prueba**

```bash
curl -X POST http://localhost:3000/api/v1/records \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "ID_DEL_USUARIO",
    "terminalIp": "192.168.1.201",
    "recordType": "entry",
    "temperature": 36.5
  }'
```

---

## 🔧 Configurar Terminales Biométricos

### **Configurar Callback en Terminal**

```bash
curl -X POST http://localhost:3000/api/v1/terminals/callback \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TU_TOKEN" \
  -d '{
    "terminalIp": "192.168.1.201",
    "callbackUrl": "http://TU_IP:3000/api/v1/terminals/identify-callback"
  }'
```

### **Registrar Usuario en Terminal**

```bash
curl -X POST http://localhost:3000/api/v1/terminals/register-user \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TU_TOKEN" \
  -d '{
    "userId": "ID_DEL_USUARIO",
    "terminalIp": "192.168.1.201",
    "photoBase64": "FOTO_EN_BASE64"
  }'
```

---

## 📱 Probar el Sistema

### **1. Ver el Dashboard**
- Abre http://localhost:3000
- Verás las estadísticas actualizándose cada 30 segundos

### **2. Explorar la API**
- Abre http://localhost:3000/api-docs
- Prueba los endpoints directamente desde Swagger

### **3. Ver Logs**
```bash
# Ver logs en tiempo real
Get-Content logs/combined.log -Wait

# Ver solo errores
Get-Content logs/error.log -Wait
```

---

## 🎨 Personalización

### **Cambiar Puerto**
Edita `.env`:
```env
PORT=8080
```

### **Cambiar Intervalo de Auto-refresh del Dashboard**
Edita `public/js/dashboard.js`:
```javascript
const REFRESH_INTERVAL = 60000; // 60 segundos
```

### **Agregar Más Terminales**
Edita `.env`:
```env
TERMINAL_IPS=192.168.1.201,192.168.1.202,192.168.1.208,192.168.1.209
```

---

## 🐛 Solución Rápida de Problemas

### **El servidor no inicia**
```bash
# Verificar que MongoDB esté corriendo
Get-Service MongoDB

# Si no está corriendo
Start-Service MongoDB
```

### **Error "Puerto en uso"**
```bash
# Cambiar el puerto en .env
PORT=8080
```

### **Dashboard no carga datos**
1. Verifica que el servidor esté corriendo
2. Abre http://localhost:3000/api/v1/health
3. Revisa la consola del navegador (F12)

### **No hay datos en el dashboard**
Es normal si es la primera vez. Debes:
1. Crear usuarios
2. Crear algunos registros de prueba
3. Esperar 30 segundos para que actualice

---

## 📚 Documentación Completa

- **README.md** - Documentación detallada del proyecto
- **CHANGELOG.md** - Historial de cambios
- **/api-docs** - Documentación interactiva de la API

---

## ✨ Características Destacadas

### **Dashboard**
- ✅ Actualización automática cada 30 segundos
- ✅ Gráficas interactivas con Chart.js
- ✅ Diseño responsive (funciona en móvil)
- ✅ Indicadores visuales de estado

### **API**
- ✅ 50+ endpoints RESTful
- ✅ Autenticación JWT
- ✅ Validación automática de datos
- ✅ Rate limiting
- ✅ Documentación Swagger

### **Seguridad**
- ✅ Passwords hasheados con bcrypt
- ✅ Tokens JWT con expiración
- ✅ Rate limiting por IP
- ✅ Validación con Joi
- ✅ Headers de seguridad con Helmet

---

## 🎯 Siguiente Nivel

Una vez que domines lo básico, puedes:

1. **Conectar Terminales Reales**
   - Configurar las IPs en `.env`
   - Configurar callbacks
   - Sincronizar usuarios

2. **Integrar Puerto Serial**
   - Conectar lector de cédulas
   - El sistema auto-detectará formato MRZ

3. **Personalizar el Dashboard**
   - Modificar colores en `public/css/dashboard.css`
   - Agregar nuevas métricas en `public/js/dashboard.js`

4. **Crear Reportes**
   - Usar endpoint `/api/v1/records/export`
   - Filtrar por fecha, terminal, usuario

5. **Tests Automatizados**
   - Escribir tests en `tests/`
   - Ejecutar con `npm test`

---

## 💡 Tips Pro

- Usa **Postman** para probar endpoints
- Mantén la documentación actualizada
- Revisa logs regularmente
- Haz backups de MongoDB periódicamente
- Usa variables de entorno para producción

---

**¡Listo para empezar! 🚀**

Ejecuta: `npm run dev` y abre http://localhost:3000
