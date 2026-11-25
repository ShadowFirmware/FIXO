import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../conduct_reports/domain/entities/conduct_report.dart';
import '../providers/conduct_review_view_model.dart';
import '../widgets/admin_page.dart';
import '../widgets/conduct_review_widgets.dart';

/// Revisión de los reportes de conducta (HU-7.3).
class AdminConductReportsScreen extends StatefulWidget {
  const AdminConductReportsScreen({
    super.key,
    this.viewModel,
    this.initialReportId,
  });

  final ConductReviewViewModel? viewModel;

  /// Reporte cuyo detalle se abre al cargar, por ejemplo al tocar el aviso
  /// "Nuevo reporte de conducta".
  final String? initialReportId;

  @override
  State<AdminConductReportsScreen> createState() =>
      _AdminConductReportsScreenState();
}

class _AdminConductReportsScreenState extends State<AdminConductReportsScreen> {
  late final ConductReviewViewModel _viewModel =
      widget.viewModel ?? ConductReviewViewModel();
  late final bool _ownsViewModel = widget.viewModel == null;
  late final _actions = ConductReviewActions(context, _viewModel);
  late String? _pendingReportId = widget.initialReportId;

  @override
  void initState() {
    super.initState();
    _viewModel
      ..addListener(_openInitialReport)
      ..start();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_openInitialReport);
    if (_ownsViewModel) _viewModel.dispose();
    super.dispose();
  }

  /// Abre el detalle de [AdminConductReportsScreen.initialReportId] en
  /// cuanto llegan los reportes, una sola vez.
  void _openInitialReport() {
    final id = _pendingReportId;
    if (id == null || _viewModel.isLoading) return;
    _pendingReportId = null;
    final report = _viewModel.findById(id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (report == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El reporte de conducta ya no existe.')),
        );
      } else {
        _openDetail(report);
      }
    });
  }

  void _openDetail(ConductReport report) =>
      showConductReportDetail(context, report, actions: _actions);

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      currentRoute: RouteNames.adminConductReports,
      title: 'Reportes de conducta',
      subtitle: 'Revisa la evidencia y valida o rechaza cada reporte',
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StatusFilter(viewModel: _viewModel),
            if (_viewModel.isSaving) const LinearProgressIndicator(),
            Expanded(child: _content(context)),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    if (_viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_viewModel.all.isEmpty && _viewModel.errorMessage != null) {
      return _Message(
        icon: Icons.cloud_off_outlined,
        text: _viewModel.errorMessage!,
      );
    }
    final items = _viewModel.reports;
    if (items.isEmpty) {
      final filter = _viewModel.statusFilter;
      return _Message(
        icon: Icons.inbox_outlined,
        text: filter == null
            ? 'No hay reportes de conducta registrados'
            : 'No hay reportes de conducta con estado ${filter.label}',
      );
    }

    final busy = _viewModel.isSaving;
    final isMobile = MediaQuery.sizeOf(context).width < 900;
    if (isMobile) {
      return ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final report = items[index];
          return ConductReviewCard(
            key: Key('conductReport.${report.id}'),
            report: report,
            onTap: () => _openDetail(report),
            onValidate: busy ? null : () => _actions.validate(report),
            onReject: busy ? null : () => _actions.reject(report),
          );
        },
      );
    }
    return _Table(
      items: items,
      busy: busy,
      onView: _openDetail,
      onValidate: _actions.validate,
      onReject: _actions.reject,
    );
  }
}

/// Filtro por estado, con cuántos reportes hay en cada uno.
class _StatusFilter extends StatelessWidget {
  const _StatusFilter({required this.viewModel});

  final ConductReviewViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    Widget chip(ConductReportStatus? status) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        key: Key('conductFilter.${status?.value ?? 'todos'}'),
        label: Text(
          '${status?.label ?? 'Todos'} (${viewModel.countOf(status)})',
        ),
        selected: viewModel.statusFilter == status,
        onSelected: (_) => viewModel.setStatusFilter(status),
      ),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          chip(null),
          for (final status in ConductReportStatus.values) chip(status),
        ],
      ),
    );
  }
}

class _Table extends StatelessWidget {
  const _Table({
    required this.items,
    required this.busy,
    required this.onView,
    required this.onValidate,
    required this.onReject,
  });

  final List<ConductReport> items;
  final bool busy;
  final ValueChanged<ConductReport> onView;
  final ValueChanged<ConductReport> onValidate;
  final ValueChanged<ConductReport> onReject;

  @override
  Widget build(BuildContext context) {
    Widget limited(String text, double width) => SizedBox(
      width: width,
      child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Card(
        color: AppColors.white,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            showCheckboxColumn: false,
            columns: const [
              DataColumn(label: Text('Identificador')),
              DataColumn(label: Text('Estado')),
              DataColumn(label: Text('Reportó')),
              DataColumn(label: Text('Reportado')),
              DataColumn(label: Text('Incidencia')),
              DataColumn(label: Text('Motivo')),
              DataColumn(label: Text('Descripción')),
              DataColumn(label: Text('Evidencias')),
              DataColumn(label: Text('Fecha')),
              DataColumn(label: Text('Opciones')),
            ],
            rows: [
              for (final r in items)
                DataRow(
                  onSelectChanged: (_) => onView(r),
                  cells: [
                    DataCell(Text(r.reportNumber)),
                    DataCell(ConductStatusChip(status: r.status)),
                    DataCell(
                      limited(
                        conductUserLabel(r.reporterName, r.reporterRole),
                        160,
                      ),
                    ),
                    DataCell(
                      limited(
                        conductUserLabel(r.reportedName, r.reportedRole),
                        160,
                      ),
                    ),
                    DataCell(limited(conductIncidentLabel(r), 180)),
                    DataCell(Text(r.reason.label)),
                    DataCell(limited(r.description, 220)),
                    DataCell(
                      Text(
                        r.evidence.isEmpty
                            ? 'Sin evidencias'
                            : '${r.evidence.length} (ver)',
                      ),
                    ),
                    DataCell(Text(conductDateLabel(r.createdAt))),
                    DataCell(
                      r.isPendingReview
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton.icon(
                                  onPressed: busy ? null : () => onValidate(r),
                                  icon: const Icon(Icons.check_rounded),
                                  label: const Text('Validar'),
                                ),
                                TextButton.icon(
                                  onPressed: busy ? null : () => onReject(r),
                                  icon: const Icon(Icons.close_rounded),
                                  label: const Text('Rechazar'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.error,
                                  ),
                                ),
                              ],
                            )
                          : TextButton.icon(
                              onPressed: () => onView(r),
                              icon: const Icon(Icons.visibility_outlined),
                              label: const Text('Ver'),
                            ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
