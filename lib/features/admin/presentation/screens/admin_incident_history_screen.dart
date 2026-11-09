import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../providers/admin_incident_history_view_model.dart';
import '../widgets/admin_page.dart';
import '../widgets/admin_history_filters.dart';
import '../widgets/history_incident_detail.dart';
import '../widgets/history_incident_widgets.dart';

/// HU-4.11 Consultar historial de incidencias: todos los reportes, sin
/// importar su estado.
class AdminIncidentHistoryScreen extends StatefulWidget {
  const AdminIncidentHistoryScreen({super.key, this.viewModel});

  /// Solo para pruebas; normalmente la pantalla crea el suyo.
  final AdminIncidentHistoryViewModel? viewModel;

  @override
  State<AdminIncidentHistoryScreen> createState() =>
      _AdminIncidentHistoryScreenState();
}

class _AdminIncidentHistoryScreenState
    extends State<AdminIncidentHistoryScreen> {
  late final AdminIncidentHistoryViewModel _viewModel =
      widget.viewModel ?? AdminIncidentHistoryViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.start();
  }

  @override
  void dispose() {
    if (widget.viewModel == null) _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      currentRoute: RouteNames.adminIncidentHistory,
      title: 'Historial',
      subtitle: 'Todas las incidencias',
      actions: [
        AdminPageAction(
          key: const Key('history.exportPdf'),
          icon: Icons.picture_as_pdf_outlined,
          label: 'Exportar a PDF',
          onPressed: _exportPdf,
        ),
      ],
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_viewModel.isExporting) const LinearProgressIndicator(),
            Expanded(child: _content(context)),
          ],
        ),
      ),
    );
  }

  /// Exporta lo que se ve en pantalla, con los filtros aplicados.
  Future<void> _exportPdf() async {
    final message = await _viewModel.exportPdf();
    if (message == null || !mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _content(BuildContext context) {
    final vm = _viewModel;
    switch (vm.state) {
      case AdminHistoryState.loading:
        return const Center(child: CircularProgressIndicator());
      case AdminHistoryState.error:
        return HistoryEmptyMessage(
          icon: Icons.cloud_off_outlined,
          text: vm.errorMessage!,
        );
      case AdminHistoryState.loaded when vm.incidents.isEmpty:
        return HistoryEmptyMessage(
          icon: Icons.receipt_long_outlined,
          text: vm.emptyMessage!,
        );
      case AdminHistoryState.loaded:
        break;
    }

    final filters = AdminHistoryFilters(viewModel: vm);
    final items = vm.results;
    if (items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          filters,
          Expanded(
            child: HistoryEmptyMessage(
              icon: Icons.search_off_rounded,
              text: vm.emptyMessage!,
            ),
          ),
        ],
      );
    }

    // En el teléfono los filtros se desplazan junto con las tarjetas para
    // dejarles más espacio.
    final isMobile = MediaQuery.sizeOf(context).width < 900;
    if (isMobile) {
      return ListView.separated(
        padding: const EdgeInsets.only(bottom: 12),
        itemCount: items.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index == 0) return filters;
          final record = items[index - 1];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: HistoryIncidentCard(
              key: ValueKey(record.id),
              record: record,
              onTap: () => showHistoryIncidentDetail(context, record),
            ),
          );
        },
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        filters,
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: HistoryIncidentTable(
              items: items,
              onView: (record) => showHistoryIncidentDetail(context, record),
            ),
          ),
        ),
      ],
    );
  }
}
