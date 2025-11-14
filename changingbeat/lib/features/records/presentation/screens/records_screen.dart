import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/records_provider.dart';
import '../../../../data/models/biometric_record_model.dart';

/// Pantalla de historial de registros biométricos
class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRecords();
    _setupScrollListener();
  }

  void _loadRecords() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecordsProvider>().loadRecords();
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.8) {
        context.read<RecordsProvider>().loadMoreRecords();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

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
      body: Consumer<RecordsProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Barra de búsqueda
              _buildSearchBar(provider),

              // Filtros activos
              if (provider.statusFilter != null ||
                  provider.startDate != null ||
                  provider.endDate != null)
                _buildActiveFilters(provider),

              // Estadísticas
              if (provider.records.isNotEmpty && !provider.isLoading)
                _buildStatistics(provider),

              // Lista de registros
              Expanded(
                child: _buildRecordsList(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(RecordsProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o documento...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    provider.setSearchQuery(null);
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (value) {
          provider.setSearchQuery(value.isEmpty ? null : value);
        },
      ),
    );
  }

  Widget _buildActiveFilters(RecordsProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (provider.statusFilter != null)
            _buildFilterChip(
              label: 'Estado: ${_getStatusLabel(provider.statusFilter!)}',
              onDeleted: () => provider.setStatusFilter(null),
            ),
          if (provider.startDate != null || provider.endDate != null)
            _buildFilterChip(
              label: 'Fechas: ${_getDateRangeLabel(provider)}',
              onDeleted: () => provider.setDateRange(null, null),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required VoidCallback onDeleted,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Chip(
        label: Text(label),
        deleteIcon: const Icon(Icons.close, size: 18),
        onDeleted: onDeleted,
        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
      ),
    );
  }

  Widget _buildStatistics(RecordsProvider provider) {
    final stats = provider.statistics;

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.list_alt,
            label: 'Total',
            value: '${stats['total']}',
            color: AppTheme.primaryColor,
          ),
          _buildStatItem(
            icon: Icons.check_circle,
            label: 'Aprobados',
            value: '${stats['approved']}',
            color: AppTheme.accentColor,
          ),
          _buildStatItem(
            icon: Icons.cancel,
            label: 'Rechazados',
            value: '${stats['rejected']}',
            color: AppTheme.errorColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildRecordsList(RecordsProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 64, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage!,
              style: const TextStyle(color: AppTheme.errorColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => provider.loadRecords(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final records = provider.filteredRecords;

    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No hay registros',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Los registros biométricos aparecerán aquí',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        itemCount: records.length + (provider.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == records.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          return _buildRecordCard(records[index]);
        },
      ),
    );
  }

  Widget _buildRecordCard(BiometricRecordModel record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () => _showRecordDetails(record),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getStatusColor(record.status),
                    child: Icon(
                      _getStatusIcon(record.status),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.fullName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${record.documentType}: ${record.documentNumber}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(record.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(record.createdAt),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const Spacer(),
                  if (record.operatorId != null) ...[
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Op: ${record.operatorId}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getStatusColor(status)),
      ),
      child: Text(
        _getStatusLabel(status),
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'success':
        return AppTheme.accentColor;
      case 'pending':
        return AppTheme.warningColor;
      case 'rejected':
      case 'failed':
        return AppTheme.errorColor;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'success':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'rejected':
      case 'failed':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'success':
        return 'Aprobado';
      case 'pending':
        return 'Pendiente';
      case 'rejected':
      case 'failed':
        return 'Rechazado';
      default:
        return status;
    }
  }

  String _getDateRangeLabel(RecordsProvider provider) {
    final format = DateFormat('dd/MM/yy');
    if (provider.startDate != null && provider.endDate != null) {
      return '${format.format(provider.startDate!)} - ${format.format(provider.endDate!)}';
    } else if (provider.startDate != null) {
      return 'Desde ${format.format(provider.startDate!)}';
    } else if (provider.endDate != null) {
      return 'Hasta ${format.format(provider.endDate!)}';
    }
    return '';
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => _FilterDialog(
        provider: context.read<RecordsProvider>(),
      ),
    );
  }

  void _showRecordDetails(BiometricRecordModel record) {
    showDialog(
      context: context,
      builder: (context) => _RecordDetailsDialog(record: record),
    );
  }
}

// Diálogo de filtros
class _FilterDialog extends StatefulWidget {
  final RecordsProvider provider;

  const _FilterDialog({required this.provider});

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  String? _selectedStatus;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.provider.statusFilter;
    _startDate = widget.provider.startDate;
    _endDate = widget.provider.endDate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filtros'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Estado:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Todos'),
                  selected: _selectedStatus == null,
                  onSelected: (selected) {
                    setState(() => _selectedStatus = null);
                  },
                ),
                FilterChip(
                  label: const Text('Aprobados'),
                  selected: _selectedStatus == 'approved',
                  onSelected: (selected) {
                    setState(
                        () => _selectedStatus = selected ? 'approved' : null);
                  },
                ),
                FilterChip(
                  label: const Text('Rechazados'),
                  selected: _selectedStatus == 'rejected',
                  onSelected: (selected) {
                    setState(
                        () => _selectedStatus = selected ? 'rejected' : null);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Rango de fechas:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _startDate = date);
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_startDate != null
                        ? DateFormat('dd/MM/yy').format(_startDate!)
                        : 'Desde'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _endDate = date);
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_endDate != null
                        ? DateFormat('dd/MM/yy').format(_endDate!)
                        : 'Hasta'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.provider.clearFilters();
            Navigator.of(context).pop();
          },
          child: const Text('Limpiar'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.provider.setStatusFilter(_selectedStatus);
            widget.provider.setDateRange(_startDate, _endDate);
            Navigator.of(context).pop();
          },
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}

// Diálogo de detalles del registro
class _RecordDetailsDialog extends StatelessWidget {
  final BiometricRecordModel record;

  const _RecordDetailsDialog({required this.record});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Detalles del Registro'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Nombre completo', record.fullName),
            _buildDetailRow('Documento',
                '${record.documentType}: ${record.documentNumber}'),
            _buildDetailRow('Género', record.gender),
            _buildDetailRow('Nacionalidad', record.nationality),
            _buildDetailRow('Fecha de registro',
                DateFormat('dd/MM/yyyy HH:mm:ss').format(record.createdAt)),
            if (record.operatorId != null)
              _buildDetailRow('Operador', record.operatorId!),
            if (record.tabletId != null)
              _buildDetailRow('Tablet', record.tabletId!),
            _buildDetailRow('Estado', record.status),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
