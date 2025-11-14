# 🚀 Sistema de Control de Acceso Biométrico

Sistema completo de control de acceso con reconocimiento facial, integración con tabletas Android ATAIdentifica, dashboard en tiempo real y gestión de usuarios.

## 📋 Características

- ✅ **Dashboard Web en Tiempo Real** - Interfaz moderna con WebSocket
- ✅ **Reconocimiento Facial** - Integración con tabletas ATAIdentifica
- ✅ **Gestión de Usuarios** - CRUD completo con roles
- ✅ **Registro de Accesos** - Historial completo con temperatura
- ✅ **Notificaciones en Tiempo Real** - Alertas instantáneas
- ✅ **API RESTful** - Documentación con Swagger
- ✅ **Lector de Cédulas** - Integración con puerto serial MRZ
- ✅ **Base de Datos MongoDB** - Almacenamiento escalable

## 🛠️ Tecnologías

- **Backend:** Node.js + Express.js
- **Base de Datos:** MongoDB
- **Tiempo Real:** Socket.io
- **Frontend:** HTML5 + CSS3 + JavaScript
- **Documentación:** Swagger/OpenAPI
- **Hardware:** Puerto Serial, Tabletas Android

## 📦 Instalación

\\\ash
# Clonar repositorio
git clone <URL_DEL_REPO>
cd server

# Instalar dependencias
npm install

# Configurar variables de entorno (opcional)
cp .env.example .env

# Iniciar servidor
npm start
\\\

## 🚀 Uso Rápido

\\\ash
# Iniciar servidor
npm start

# Abrir dashboard
http://localhost:3000

# Ver documentación API
http://localhost:3000/api-docs
\\\

## 📱 Configuración de Tabletas ATAIdentifica

En cada tableta, configurar las siguientes URLs:

\\\
URL devolución de llamada: http://TU_IP:3000/api/v1/terminals/llamada
Latido URL: http://TU_IP:3000/api/v1/terminals/latido
Dirección registrada: http://TU_IP:3000/api/v1/terminals/url
\\\

Ver guía completa en: [CONFIGURAR_TABLETAS.md](CONFIGURAR_TABLETAS.md)

## 📚 Documentación

- [Guía de Inicio Rápido](QUICK_START.md)
- [Configuración de Tabletas](CONFIGURAR_TABLETAS.md)
- [Integración de Red](NETWORK_CONFIGURATION.md)
- [Configuración de Terminales](TERMINAL_SETUP.md)

## 🧪 Scripts Disponibles

\\\ash
# Desarrollo
npm start              # Iniciar servidor
npm run dev           # Modo desarrollo con nodemon

# Testing
npm run test:eduardo:once    # Simular una detección
npm run test:eduardo         # Simulación continua
npm run simulate             # Simular accesos

# Diagnóstico
npm run diagnose            # Diagnosticar sistema de cámaras
npm run diagnose:network    # Diagnosticar red
npm run explore:tablets     # Explorar tabletas Android
npm run analyze             # Análisis completo del sistema

# Monitoreo
npm run monitor:files       # Monitorear archivos FaceOpen
npm run monitor:faceopen    # Monitorear base de datos FaceOpen

# Utilidades
npm run seed               # Poblar base de datos con datos de prueba
\\\

## 🏗️ Estructura del Proyecto

\\\
server/
├── src/
│   ├── controllers/      # Controladores de rutas
│   ├── models/          # Modelos de MongoDB
│   ├── routes/          # Definición de rutas
│   ├── services/        # Lógica de negocio
│   ├── middlewares/     # Middlewares personalizados
│   ├── websocket/       # Manejador de WebSocket
│   └── config/          # Configuraciones
├── public/              # Archivos estáticos (Dashboard)
├── scripts/             # Scripts de utilidad
├── logs/               # Logs del sistema
└── docs/               # Documentación adicional
\\\

## 🔧 Configuración

### Variables de Entorno

El sistema funciona sin configuración adicional, pero puedes personalizar:

\\\env
PORT=3000
MONGODB_URI=mongodb://localhost:27017/autoregistro
JWT_SECRET=tu_secreto_aqui
NODE_ENV=development
\\\

### Puerto Serial

Configurar en \src/config/constants.js\:

\\\javascript
SERIAL_PORT: 'COM8'  // Puerto del lector de cédulas
\\\

## 📊 API Endpoints

### Autenticación
- \POST /api/v1/auth/register\ - Registrar usuario
- \POST /api/v1/auth/login\ - Iniciar sesión

### Usuarios
- \GET /api/v1/users\ - Listar usuarios
- \POST /api/v1/users\ - Crear usuario
- \PUT /api/v1/users/:id\ - Actualizar usuario
- \DELETE /api/v1/users/:id\ - Eliminar usuario

### Registros
- \GET /api/v1/records\ - Listar registros
- \GET /api/v1/records/stats\ - Estadísticas

### Terminales
- \POST /api/v1/terminals/llamada\ - Callback de identificación
- \POST /api/v1/terminals/latido\ - Callback de heartbeat

Ver documentación completa en: \http://localhost:3000/api-docs\

## 🎯 Características Destacadas

### Dashboard en Tiempo Real
- Notificaciones instantáneas con sonido
- Stream de actividad en vivo
- Gráficas y estadísticas actualizadas
- Indicador de estado de conexión

### Integración con Hardware
- Tabletas Android ATAIdentifica
- Lector de cédulas MRZ (puerto serial)
- Terminales biométricos
- Cámaras de reconocimiento facial

### Seguridad
- Autenticación JWT
- Control de acceso por roles
- Rate limiting en endpoints públicos
- Validación de datos con Joi

## 🤝 Contribuir

Las contribuciones son bienvenidas. Por favor:

1. Fork el proyecto
2. Crea una rama para tu feature (\git checkout -b feature/AmazingFeature\)
3. Commit tus cambios (\git commit -m 'Add some AmazingFeature'\)
4. Push a la rama (\git push origin feature/AmazingFeature\)
5. Abre un Pull Request

## 📝 Licencia

Este proyecto es privado y confidencial.

## 👥 Autores

- Sistema desarrollado para control de acceso biométrico

## 📞 Soporte

Para soporte, consulta la documentación en la carpeta \docs/\ o revisa los archivos:
- \QUICK_START.md\ - Inicio rápido
- \CONFIGURAR_TABLETAS.md\ - Configuración de tabletas
- \TROUBLESHOOTING.md\ - Solución de problemas

---

**Versión:** 2.0.0  
**Última actualización:** Noviembre 2025
