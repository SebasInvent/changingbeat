import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';

/// Pantalla principal del dashboard
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Cargar datos del dashboard al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de Acceso Biométrico'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.settings);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fingerprint),
            label: 'Captura',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Registros',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildCaptureTab();
      case 2:
        return _buildRecordsTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return Consumer2<AuthProvider, DashboardProvider>(
      builder: (context, authProvider, dashboardProvider, child) {
        final user = authProvider.currentUser;

        return RefreshIndicator(
          onRefresh: () => dashboardProvider.refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tarjeta de bienvenida con usuario
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: AppTheme.primaryColor,
                              child: Text(
                                user?.username.substring(0, 1).toUpperCase() ??
                                    'U',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Bienvenido, ${user?.username ?? "Usuario"}',
                              style: Theme.of(context).textTheme.titleLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rol: ${user?.role ?? "Operador"}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.primaryColor,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sistema de Verificación Biométrica',
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Indicador de carga o error
                    if (dashboardProvider.isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (dashboardProvider.errorMessage != null)
                      Card(
                        color: AppTheme.errorColor.withOpacity(0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              const Icon(Icons.error,
                                  color: AppTheme.errorColor),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  dashboardProvider.errorMessage!,
                                  style: const TextStyle(
                                      color: AppTheme.errorColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Estadísticas rápidas
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.person_add,
                            title: 'Registros Hoy',
                            value: '${dashboardProvider.todayRecords}',
                            color: AppTheme.accentColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.check_circle,
                            title: 'Exitosos',
                            value: '${dashboardProvider.successfulRecords}',
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Botón principal de captura
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushNamed(AppRoutes.capture);
                      },
                      icon: const Icon(Icons.camera_alt, size: 28),
                      label: const Text('Iniciar Captura Biométrica'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Botón secundario de registros
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushNamed(AppRoutes.records);
                      },
                      icon: const Icon(Icons.history),
                      label: const Text('Ver Historial de Registros'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.fingerprint,
            size: 100,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 24),
          Text(
            'Captura Biométrica',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.capture);
            },
            child: const Text('Iniciar Captura'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.history,
            size: 100,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 24),
          Text(
            'Historial de Registros',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.records);
            },
            child: const Text('Ver Registros'),
          ),
        ],
      ),
    );
  }

  /// Manejar logout
  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Está seguro que desea cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().logout();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
        );
      }
    }
  }
}
