import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Pantalla de historial de registros
class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  String _filterType = 'all';

  // TODO: Reemplazar con datos reales de la API
  final List<Map<String, dynamic>> _mockRecords = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Registros'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros rápidos
          _buildQuickFilters(),

          const Divider(height: 1),

          // Lista de registros
          Expanded(
            child:
                _mockRecords.isEmpty ? _buildEmptyState() : _buildRecordsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip('Todos', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('Hoy', 'today'),
          const SizedBox(width: 8),
          _buildFilterChip('Esta semana', 'week'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterType = value);
        // TODO: Aplicar filtro
      },
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.inbox,
            size: 100,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay registros',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Los registros biométricos aparecerán aquí',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _mockRecords.length,
      itemBuilder: (context, index) {
        final record = _mockRecords[index];
        return _buildRecordCard(record);
      },
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> record) {
    final bool isSuccess = record['success'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSuccess
              ? AppTheme.accentColor.withOpacity(0.2)
              : AppTheme.errorColor.withOpacity(0.2),
          child: Icon(
            isSuccess ? Icons.check : Icons.close,
            color: isSuccess ? AppTheme.accentColor : AppTheme.errorColor,
          ),
        ),
        title: Text(record['name'] ?? 'Sin nombre'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(record['document'] ?? 'Sin documento'),
            const SizedBox(height: 4),
            Text(
              record['timestamp'] ?? 'Sin fecha',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () {
            _showRecordDetails(record);
          },
        ),
        isThreeLine: true,
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar registros'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Todos'),
              leading: Radio<String>(
                value: 'all',
                groupValue: _filterType,
                onChanged: (value) {
                  setState(() => _filterType = value!);
                  Navigator.of(context).pop();
                },
              ),
            ),
            ListTile(
              title: const Text('Exitosos'),
              leading: Radio<String>(
                value: 'success',
                groupValue: _filterType,
                onChanged: (value) {
                  setState(() => _filterType = value!);
                  Navigator.of(context).pop();
                },
              ),
            ),
            ListTile(
              title: const Text('Fallidos'),
              leading: Radio<String>(
                value: 'failed',
                groupValue: _filterType,
                onChanged: (value) {
                  setState(() => _filterType = value!);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showRecordDetails(Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles del registro'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Nombre', record['name'] ?? 'N/A'),
              _buildDetailRow('Documento', record['document'] ?? 'N/A'),
              _buildDetailRow('Fecha', record['timestamp'] ?? 'N/A'),
              _buildDetailRow(
                  'Estado', record['success'] ? 'Exitoso' : 'Fallido'),
              if (record['details'] != null)
                _buildDetailRow('Detalles', record['details']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
