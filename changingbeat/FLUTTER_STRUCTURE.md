# Estructura de la Aplicación Flutter

Este documento describe la arquitectura y organización del código de la aplicación móvil de verificación biométrica.

## Estructura de Carpetas

```
lib/
├── core/                      # Funcionalidad compartida y configuración
│   ├── config/               # Configuración de la app
│   │   └── app_config.dart   # URLs, endpoints, configuración general
│   ├── constants/            # Constantes globales
│   │   └── app_constants.dart
│   ├── router/               # Navegación
│   │   └── app_router.dart   # Rutas y navegación centralizada
│   ├── theme/                # Temas y estilos
│   │   └── app_theme.dart    # Tema Material Design
│   ├── utils/                # Utilidades generales
│   └── widgets/              # Widgets reutilizables globales
│
├── data/                      # Capa de datos
│   ├── models/               # Modelos de datos
│   ├── repositories/         # Repositorios (abstracción de datos)
│   ├── datasources/          # Fuentes de datos (API, local DB)
│   └── clients/              # Clientes HTTP, WebSocket
│
├── features/                  # Módulos funcionales (por feature)
│   ├── auth/                 # Autenticación
│   │   ├── data/            # Modelos y repos específicos de auth
│   │   ├── domain/          # Lógica de negocio de auth
│   │   └── presentation/    # UI de auth
│   │       ├── screens/     # Pantallas de login, registro
│   │       └── widgets/     # Widgets específicos de auth
│   │
│   ├── onboarding/           # Splash, bienvenida, permisos
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │       └── screens/
│   │           ├── splash_screen.dart
│   │           └── welcome_screen.dart
│   │
│   ├── capture/              # Captura biométrica (rostro, documento)
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── dashboard/            # Pantalla principal
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── records/              # Historial de registros
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   └── settings/             # Configuración de la app
│       ├── data/
│       ├── domain/
│       └── presentation/
│
├── shared/                    # Componentes compartidos entre features
│   ├── widgets/              # Widgets compartidos
│   └── components/           # Componentes complejos reutilizables
│
└── main.dart                  # Punto de entrada de la aplicación
```

## Convenciones

### Nomenclatura
- **Archivos**: `snake_case.dart`
- **Clases**: `PascalCase`
- **Variables/funciones**: `camelCase`
- **Constantes**: `SCREAMING_SNAKE_CASE` o `camelCase` según contexto

### Organización por Feature
Cada feature sigue la arquitectura limpia:
- **data/**: Modelos, repositorios, datasources
- **domain/**: Casos de uso, entidades, lógica de negocio
- **presentation/**: Screens, widgets, state management

### Rutas
Todas las rutas están centralizadas en `core/router/app_router.dart`:
```dart
AppRoutes.splash       // '/'
AppRoutes.welcome      // '/welcome'
AppRoutes.login        // '/login'
AppRoutes.dashboard    // '/dashboard'
// ...
```

### Tema
El tema está centralizado en `core/theme/app_theme.dart` con colores y estilos predefinidos:
```dart
AppTheme.primaryColor
AppTheme.secondaryColor
AppTheme.lightTheme
```

### Configuración
Constantes y configuración en `core/constants/app_constants.dart` y `core/config/app_config.dart`:
```dart
AppConstants.apiBaseUrl
AppConstants.apiTimeout
AppConstants.endpointHealth
```

## Estado Actual

### Archivos Base Creados
- ✅ `core/router/app_router.dart` - Router con rutas placeholder
- ✅ `core/theme/app_theme.dart` - Tema Material Design
- ✅ `core/constants/app_constants.dart` - Constantes globales
- ✅ `core/config/app_config.dart` - Configuración de la app
- ✅ `features/onboarding/presentation/screens/splash_screen.dart`
- ✅ `features/onboarding/presentation/screens/welcome_screen.dart`

### Próximos Pasos
1. Crear screens placeholder para cada feature (auth, dashboard, capture, etc.)
2. Implementar API client en `data/clients/`
3. Crear modelos de datos en `data/models/`
4. Implementar state management (Provider ya está en pubspec.yaml)
5. Conectar screens con funcionalidad real
6. Implementar captura biométrica
7. Integrar con backend en `https://access-control.eukahack.com/api/v1`

## Dependencias Principales

- **flutter**: SDK base
- **provider**: State management
- **dio**: Cliente HTTP
- **camera**: Captura de imágenes
- **google_ml_kit**: ML Kit para detección facial
- **permission_handler**: Manejo de permisos
- **shared_preferences**: Almacenamiento local
- **logger**: Logging

Ver `pubspec.yaml` para la lista completa.

## Comandos Útiles

```bash
# Obtener dependencias
flutter pub get

# Ejecutar en modo debug
flutter run

# Construir APK
flutter build apk --release

# Analizar código
flutter analyze

# Formatear código
flutter format lib/
```

## Notas
- Los errores de lint se resuelven automáticamente después de `flutter pub get`
- Todos los screens actuales son placeholders y deben implementarse
- La estructura sigue Clean Architecture adaptada para Flutter
- Se usa Provider para state management (puede cambiarse a Riverpod/Bloc si se prefiere)
