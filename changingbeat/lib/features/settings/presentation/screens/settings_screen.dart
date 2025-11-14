import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';

/// Pantalla de configuración
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _autoSync = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: ListView(
        children: [
          // Información de la app
          _buildSection(
            title: 'Información',
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Versión de la aplicación'),
                subtitle: Text(AppConstants.appVersion),
              ),
              ListTile(
                leading: const Icon(Icons.tablet),
                title: const Text('ID del dispositivo'),
                subtitle: const Text('TAB-001'), // TODO: Obtener ID real
              ),
              ListTile(
                leading: const Icon(Icons.cloud),
                title: const Text('Servidor API'),
                subtitle: Text(AppConstants.apiBaseUrl),
              ),
            ],
          ),

          const Divider(),

          // Configuración de notificaciones
          _buildSection(
            title: 'Notificaciones',
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.volume_up),
                title: const Text('Sonido'),
                subtitle: const Text('Reproducir sonidos de notificación'),
                value: _soundEnabled,
                onChanged: (value) {
                  setState(() => _soundEnabled = value);
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.vibration),
                title: const Text('Vibración'),
                subtitle: const Text('Vibrar en notificaciones'),
                value: _vibrationEnabled,
                onChanged: (value) {
                  setState(() => _vibrationEnabled = value);
                },
              ),
            ],
          ),

          const Divider(),

          // Configuración de sincronización
          _buildSection(
            title: 'Sincronización',
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.sync),
                title: const Text('Sincronización automática'),
                subtitle: const Text('Sincronizar datos automáticamente'),
                value: _autoSync,
                onChanged: (value) {
                  setState(() => _autoSync = value);
                },
              ),
              ListTile(
                leading: const Icon(Icons.sync_alt),
                title: const Text('Sincronizar ahora'),
                subtitle: const Text('Última sincronización: Nunca'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // TODO: Implementar sincronización manual
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sincronizando datos...'),
                    ),
                  );
                },
              ),
            ],
          ),

          const Divider(),

          // Acciones
          _buildSection(
            title: 'Acciones',
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: AppTheme.errorColor),
                title: const Text('Limpiar caché'),
                subtitle: const Text('Eliminar datos temporales'),
                onTap: () {
                  _showClearCacheDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.bug_report),
                title: const Text('Enviar reporte de errores'),
                subtitle: const Text('Ayúdanos a mejorar la aplicación'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // TODO: Implementar envío de reporte
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Función en desarrollo'),
                    ),
                  );
                },
              ),
            ],
          ),

          const Divider(),

          // Información legal
          _buildSection(
            title: 'Legal',
            children: [
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Términos y condiciones'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // TODO: Mostrar términos y condiciones
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: const Text('Política de privacidad'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // TODO: Mostrar política de privacidad
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ...children,
      ],
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar caché'),
        content: const Text(
          '¿Está seguro que desea eliminar todos los datos temporales?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Caché limpiado correctamente'),
                  backgroundColor: AppTheme.accentColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }
}
