import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/settings_provider.dart';

/// Pantalla de configuración de la aplicación
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          if (settings.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: [
              // Sección: Dispositivo
              _buildSectionHeader('Dispositivo'),
              _buildTabletIdTile(context, settings),
              const Divider(),

              // Sección: Servidor
              _buildSectionHeader('Servidor'),
              _buildServerUrlTile(context, settings),
              const Divider(),

              // Sección: Captura
              _buildSectionHeader('Captura Biométrica'),
              _buildAutoCaptureToggle(settings),
              _buildSensitivitySlider(settings),
              _buildCameraResolutionTile(context, settings),
              const Divider(),

              // Sección: Avanzado
              _buildSectionHeader('Avanzado'),
              _buildDebugModeToggle(settings),
              _buildClearCacheTile(context, settings),
              _buildResetSettingsTile(context, settings),
              const Divider(),

              // Sección: Información
              _buildSectionHeader('Información'),
              _buildAppInfoTiles(settings),
              const Divider(),

              // Sección: Sesión
              _buildSectionHeader('Sesión'),
              _buildLogoutTile(context),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildTabletIdTile(BuildContext context, SettingsProvider settings) {
    return ListTile(
      leading: const Icon(Icons.tablet_android, color: AppTheme.primaryColor),
      title: const Text('ID de Tablet'),
      subtitle: Text(settings.tabletId),
      trailing: const Icon(Icons.edit),
      onTap: () => _showTabletIdDialog(context, settings),
    );
  }

  Widget _buildServerUrlTile(BuildContext context, SettingsProvider settings) {
    return ListTile(
      leading: const Icon(Icons.cloud, color: AppTheme.primaryColor),
      title: const Text('URL del Servidor'),
      subtitle: Text(
        settings.serverUrl,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.edit),
      onTap: () => _showServerUrlDialog(context, settings),
    );
  }

  Widget _buildAutoCaptureToggle(SettingsProvider settings) {
    return SwitchListTile(
      secondary: const Icon(Icons.auto_awesome, color: AppTheme.accentColor),
      title: const Text('Auto-Captura'),
      subtitle:
          const Text('Capturar automáticamente cuando la calidad sea óptima'),
      value: settings.autoCapture,
      onChanged: (value) => settings.setAutoCapture(value),
    );
  }

  Widget _buildSensitivitySlider(SettingsProvider settings) {
    return ListTile(
      leading: const Icon(Icons.tune, color: AppTheme.primaryColor),
      title: const Text('Sensibilidad de Detección'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              'Calidad mínima requerida: ${settings.faceDetectionSensitivity.toInt()}%'),
          Slider(
            value: settings.faceDetectionSensitivity,
            min: 50,
            max: 95,
            divisions: 9,
            label: '${settings.faceDetectionSensitivity.toInt()}%',
            onChanged: (value) => settings.setFaceDetectionSensitivity(value),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraResolutionTile(
      BuildContext context, SettingsProvider settings) {
    return ListTile(
      leading: const Icon(Icons.camera_alt, color: AppTheme.primaryColor),
      title: const Text('Resolución de Cámara'),
      subtitle: Text(_getResolutionLabel(settings.cameraResolution)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _showResolutionDialog(context, settings),
    );
  }

  Widget _buildDebugModeToggle(SettingsProvider settings) {
    return SwitchListTile(
      secondary: const Icon(Icons.bug_report, color: Colors.orange),
      title: const Text('Modo Debug'),
      subtitle: const Text('Mostrar información de depuración'),
      value: settings.debugMode,
      onChanged: (value) => settings.setDebugMode(value),
    );
  }

  Widget _buildClearCacheTile(BuildContext context, SettingsProvider settings) {
    return ListTile(
      leading: const Icon(Icons.delete_sweep, color: Colors.orange),
      title: const Text('Limpiar Caché'),
      subtitle: const Text('Eliminar datos temporales'),
      onTap: () => _showClearCacheDialog(context, settings),
    );
  }

  Widget _buildResetSettingsTile(
      BuildContext context, SettingsProvider settings) {
    return ListTile(
      leading: const Icon(Icons.restore, color: AppTheme.errorColor),
      title: const Text('Restablecer Configuración'),
      subtitle: const Text('Volver a valores por defecto'),
      onTap: () => _showResetDialog(context, settings),
    );
  }

  Widget _buildAppInfoTiles(SettingsProvider settings) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.info, color: AppTheme.primaryColor),
          title: const Text('Nombre de la App'),
          subtitle: Text(settings.appName),
        ),
        ListTile(
          leading: const Icon(Icons.tag, color: AppTheme.primaryColor),
          title: const Text('Versión'),
          subtitle: Text('${settings.appVersion} (${settings.buildNumber})'),
        ),
      ],
    );
  }

  Widget _buildLogoutTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.logout, color: AppTheme.errorColor),
      title: const Text('Cerrar Sesión'),
      subtitle: const Text('Salir de la cuenta actual'),
      onTap: () => _showLogoutDialog(context),
    );
  }

  // Diálogos

  void _showTabletIdDialog(BuildContext context, SettingsProvider settings) {
    final controller = TextEditingController(text: settings.tabletId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ID de Tablet'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'ID de Tablet',
            hintText: 'TAB-001',
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              settings.setTabletId(controller.text.trim());
              Navigator.of(context).pop();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showServerUrlDialog(BuildContext context, SettingsProvider settings) {
    final controller = TextEditingController(text: settings.serverUrl);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('URL del Servidor'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'URL del Servidor',
            hintText: 'https://api.example.com/v1',
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final url = controller.text.trim();
              if (url.startsWith('http://') || url.startsWith('https://')) {
                settings.setServerUrl(url);
                Navigator.of(context).pop();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'URL inválida. Debe comenzar con http:// o https://'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showResolutionDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolución de Cámara'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Baja (Más rápido)'),
              value: 'low',
              groupValue: settings.cameraResolution,
              onChanged: (value) {
                if (value != null) {
                  settings.setCameraResolution(value);
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Media'),
              value: 'medium',
              groupValue: settings.cameraResolution,
              onChanged: (value) {
                if (value != null) {
                  settings.setCameraResolution(value);
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Alta (Recomendado)'),
              value: 'high',
              groupValue: settings.cameraResolution,
              onChanged: (value) {
                if (value != null) {
                  settings.setCameraResolution(value);
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Muy Alta (Más lento)'),
              value: 'veryHigh',
              groupValue: settings.cameraResolution,
              onChanged: (value) {
                if (value != null) {
                  settings.setCameraResolution(value);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar Caché'),
        content: const Text(
            '¿Está seguro que desea eliminar todos los datos temporales?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await settings.clearCache();
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Caché eliminado exitosamente'),
                    backgroundColor: AppTheme.accentColor,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restablecer Configuración'),
        content: const Text(
          '¿Está seguro que desea restablecer toda la configuración a valores por defecto?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await settings.resetToDefaults();
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Configuración restablecida'),
                    backgroundColor: AppTheme.accentColor,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Restablecer'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Está seguro que desea cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  String _getResolutionLabel(String resolution) {
    switch (resolution) {
      case 'low':
        return 'Baja';
      case 'medium':
        return 'Media';
      case 'high':
        return 'Alta';
      case 'veryHigh':
        return 'Muy Alta';
      default:
        return resolution;
    }
  }
}
