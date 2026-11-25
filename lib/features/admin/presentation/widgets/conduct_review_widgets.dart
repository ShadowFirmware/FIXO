import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formats.dart';
import '../../../../shared/widgets/adaptive_form.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../conduct_reports/domain/entities/conduct_report.dart';
import '../../../incidents/presentation/widgets/evidence_gallery.dart';
import '../../../notifications/data/models/notification_notices.dart';
import '../providers/conduct_review_view_model.dart';
import 'pending_incident_widgets.dart' show DialogButtons;

/// Color e ícono de cada estado de un reporte de conducta (HU-7.3).
extension ConductReportStatusStyle on ConductReportStatus {
  Color get color => switch (this) {
    ConductReportStatus.pendingReview => AppColors.orange,
    ConductReportStatus.validated => AppColors.success,
    ConductReportStatus.rejected => AppColors.error,
  };

  IconData get icon => switch (this) {
    ConductReportStatus.pendingReview => Icons.hourglass_empty_rounded,
    ConductReportStatus.validated => Icons.check_circle_outline_rounded,
    ConductReportStatus.rejected => Icons.cancel_outlined,
  };
}

/// "Juan Pérez (Técnico)". Si el reporte no guardó el nombre, solo el rol.
String conductUserLabel(String name, UserRole role) {
  final roleName = NotificationNotices.roleLabel(role);
  final clean = name.trim();
  return clean.isEmpty ? roleName : '$clean ($roleName)';
}

/// "INC-0007 · Fuga en baño".
String conductIncidentLabel(ConductReport report) =>
    report.incidentTitle.trim().isEmpty
    ? report.incidentNumber
    : '${report.incidentNumber} · ${report.incidentTitle.trim()}';

String conductDateLabel(DateTime? date) =>
    date == null ? 'Sin registrar' : DateFormats.dateTime(date);

/// "Sin evidencias", "1 evidencia" o "3 evidencias".
String conductEvidenceLabel(ConductReport report) {
  final count = report.evidence.length;
  if (count == 0) return 'Sin evidencias';
  return '$count evidencia${count == 1 ? '' : 's'}';
}

/// Etiqueta con el color del estado del reporte.
class ConductStatusChip extends StatelessWidget {
  const ConductStatusChip({super.key, required this.status});

  final ConductReportStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 14, color: status.color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: status.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de un reporte de conducta, para la vista del teléfono.
class ConductReviewCard extends StatelessWidget {
  const ConductReviewCard({
    super.key,
    required this.report,
    required this.onTap,
    this.onValidate,
    this.onReject,
  });

  final ConductReport report;
  final VoidCallback onTap;

  /// Solo se muestran mientras el reporte está Pendiente de revisión.
  final VoidCallback? onValidate;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: AppColors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.reason.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          report.reportNumber,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConductStatusChip(status: report.status),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                report.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              _InfoLine(
                Icons.outlined_flag_rounded,
                'Reportó: '
                '${conductUserLabel(report.reporterName, report.reporterRole)}',
              ),
              _InfoLine(
                Icons.person_outline,
                'Reportado: '
                '${conductUserLabel(report.reportedName, report.reportedRole)}',
              ),
              _InfoLine(
                Icons.assignment_outlined,
                conductIncidentLabel(report),
              ),
              _InfoLine(
                Icons.schedule_outlined,
                conductDateLabel(report.createdAt),
              ),
              _InfoLine(
                Icons.photo_library_outlined,
                conductEvidenceLabel(report),
              ),
              if (report.isPendingReview &&
                  (onValidate != null || onReject != null)) ...[
                const SizedBox(height: 12),
                ConductReviewButtons(
                  onReject: onReject,
                  onValidate: onValidate,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Botones Rechazar y Validar, del mismo ancho.
class ConductReviewButtons extends StatelessWidget {
  const ConductReviewButtons({
    super.key,
    required this.onReject,
    required this.onValidate,
    this.keyPrefix = 'conductReview',
  });

  final VoidCallback? onReject;
  final VoidCallback? onValidate;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              key: Key('$keyPrefix.reject'),
              onPressed: onReject,
              icon: const Icon(Icons.close_rounded),
              label: const Text('Rechazar'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              key: Key('$keyPrefix.validate'),
              onPressed: onValidate,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Validar'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Detalle completo de un reporte de conducta con sus evidencias. Si sigue
/// Pendiente de revisión, también ofrece Rechazar y Validar.
Future<void> showConductReportDetail(
  BuildContext context,
  ConductReport report, {
  required ConductReviewActions actions,
}) {
  return showAdaptiveForm<void>(
    context: context,
    title: '${report.reportNumber} · ${report.reason.label}',
    builder: (context) => AdaptiveFormLayout(
      fields: [
        Align(
          alignment: Alignment.centerLeft,
          child: ConductStatusChip(status: report.status),
        ),
        const SizedBox(height: 12),
        _DetailRow('Identificador', report.reportNumber),
        _DetailRow(
          'Reportado por',
          conductUserLabel(report.reporterName, report.reporterRole),
        ),
        _DetailRow(
          'Usuario reportado',
          conductUserLabel(report.reportedName, report.reportedRole),
        ),
        _DetailRow('Incidencia relacionada', conductIncidentLabel(report)),
        _DetailRow('Motivo', report.reason.label),
        _DetailRow(
          'Descripción de lo ocurrido',
          report.description.trim().isEmpty
              ? 'Sin registrar'
              : report.description,
        ),
        _DetailRow('Fecha', conductDateLabel(report.createdAt)),
        if (!report.isPendingReview) ...[
          _DetailRow('Fecha de revisión', conductDateLabel(report.reviewedAt)),
          if ((report.reviewerName ?? '').trim().isNotEmpty)
            _DetailRow('Revisado por', report.reviewerName!.trim()),
        ],
        const SizedBox(height: 8),
        Text(
          'Evidencias',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        EvidenceGallery(urls: report.evidence),
      ],
      footer: report.isPendingReview
          ? ConductReviewButtons(
              keyPrefix: 'conductDetail',
              onReject: () {
                Navigator.pop(context);
                actions.reject(report);
              },
              onValidate: () {
                Navigator.pop(context);
                actions.validate(report);
              },
            )
          : OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(value, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// Confirmación de Validar y Rechazar. Muestra el resultado en un
/// SnackBar; si se cancela no hace nada.
class ConductReviewActions {
  ConductReviewActions(this.context, this.viewModel);

  final BuildContext context;
  final ConductReviewViewModel viewModel;

  Future<void> validate(ConductReport report) async {
    final confirmed = await _confirm(
      title: 'Validar reporte',
      message:
          '¿Confirmas que la conducta reportada en ${report.reportNumber} '
          'contra '
          '${conductUserLabel(report.reportedName, report.reportedRole)} es '
          'válida? El reporte contará como antecedente de conducta del '
          'usuario. Esta decisión no se puede cambiar.',
      confirmLabel: 'Validar',
    );
    if (!confirmed) return;
    await viewModel.validate(report);
    _showResult();
  }

  Future<void> reject(ConductReport report) async {
    final confirmed = await _confirm(
      title: 'Rechazar reporte',
      message:
          '¿Confirmas que el reporte ${report.reportNumber} no es válido? No '
          'contará como antecedente de conducta de '
          '${conductUserLabel(report.reportedName, report.reportedRole)}. '
          'Esta decisión no se puede cambiar.',
      confirmLabel: 'Rechazar',
      destructive: true,
    );
    if (!confirmed) return;
    await viewModel.reject(report);
    _showResult();
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    if (!context.mounted) return false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          DialogButtons(
            onCancel: () => Navigator.pop(context, false),
            onConfirm: () => Navigator.pop(context, true),
            confirmLabel: confirmLabel,
            destructive: destructive,
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  void _showResult() {
    if (!context.mounted) return;
    final message = viewModel.successMessage ?? viewModel.errorMessage;
    if (message == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
