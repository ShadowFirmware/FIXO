import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../../incidents/presentation/widgets/evidence_gallery.dart';
import '../../../incidents/presentation/widgets/incident_status_view.dart';
import '../../../resident/presentation/screens/incident_detail_screen.dart';

/// Acomoda el detalle de la incidencia: en el teléfono todo va en una
/// columna; en pantallas anchas, [primary] a la izquierda y [secondary] a
/// la derecha.
class AssignedDetailLayout extends StatelessWidget {
  const AssignedDetailLayout({
    super.key,
    required this.header,
    required this.primary,
    required this.secondary,
  });

  /// Ancho a partir del cual se usan dos columnas.
  static const twoColumnsWidth = 900.0;

  static const _gap = SizedBox(height: 24);

  final Widget header;
  final List<Widget> primary;
  final List<Widget> secondary;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= twoColumnsWidth;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            padding.top + 16,
            20,
            padding.bottom + 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: wide ? 1100 : 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  _gap,
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _column(primary)),
                        const SizedBox(width: 24),
                        Expanded(child: _column(secondary)),
                      ],
                    )
                  else
                    _column([...primary, ...secondary]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _column(List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) _gap,
        children[i],
      ],
    ],
  );
}

/// Tarjeta superior con el número de reporte, el título y el estado.
class AssignedDetailSummary extends StatelessWidget {
  const AssignedDetailSummary({
    super.key,
    required this.incident,
    this.arrival,
    this.countdown,
  });

  final Incident incident;

  /// Hora estimada de llegada ya con formato, si la incidencia la tiene.
  final String? arrival;

  /// Cuánto falta para la llegada, por ejemplo "Faltan 2 h 15 min".
  final String? countdown;

  /// Qué significa el estado para el técnico.
  static String descriptionOf(IncidentStatus status) => switch (status) {
    IncidentStatus.assigned =>
      'Acude a la hora estimada para atender el problema.',
    IncidentStatus.inProgress => 'Estás atendiendo el problema.',
    IncidentStatus.resolved =>
      'Resolviste esta incidencia; ya está en tu historial.',
    IncidentStatus.pending => 'La incidencia está en espera de asignación.',
    IncidentStatus.rejected => 'El administrador rechazó el reporte.',
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final status = incident.status;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  incident.reportNumber,
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              IncidentStatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            incident.title,
            style: textTheme.titleLarge?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            descriptionOf(status),
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 20),
          IncidentStatusProgress(status: status),
          if (arrival case final arrival?) ...[
            const SizedBox(height: 16),
            Container(
              key: const Key('detail.arrival'),
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule_rounded, color: AppColors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Llegada estimada: $arrival',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (countdown case final countdown?)
                          Text(
                            countdown,
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.white.withValues(alpha: 0.85),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Mensaje centrado cuando no se puede mostrar la incidencia.
class AssignedDetailMessage extends StatelessWidget {
  const AssignedDetailMessage({
    super.key,
    required this.icon,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String message;

  /// Botón opcional además de "Volver", por ejemplo "Reintentar".
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        // Los botones del tema ocupan todo el ancho disponible.
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              if (action != null) ...[action!, const SizedBox(height: 12)],
              OutlinedButton(
                onPressed: () => Navigator.maybePop(context),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fotos y videos que adjuntó el residente, con cuántos hay de cada uno.
/// Al tocar uno se abre en pantalla completa.
class AssignedEvidenceSection extends StatelessWidget {
  const AssignedEvidenceSection({
    super.key,
    required this.title,
    required this.urls,
  });

  final String title;
  final List<String> urls;

  /// Por ejemplo "2 fotos · 1 video", o `null` si no hay evidencias.
  static String? summaryOf(List<String> urls) {
    if (urls.isEmpty) return null;
    final videos = urls.where(EvidenceGallery.isVideo).length;
    final photos = urls.length - videos;
    return [
      if (photos > 0) '$photos ${photos == 1 ? 'foto' : 'fotos'}',
      if (videos > 0) '$videos ${videos == 1 ? 'video' : 'videos'}',
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final summary = summaryOf(urls);

    return DetailSection(
      title: title,
      children: [
        if (summary != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.perm_media_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$summary · Toca una para verla completa.',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        EvidenceGallery(urls: urls),
      ],
    );
  }
}

/// Fila de detalle con un botón para copiar el valor, por ejemplo el
/// teléfono del residente para llamarle.
class CopyableDetailRow extends StatelessWidget {
  const CopyableDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.copyValue,
    required this.copiedMessage,
  });

  final IconData icon;
  final String label;
  final String value;

  /// Texto que se copia, o `null` si no hay nada que copiar.
  final String? copyValue;

  /// Aviso que se muestra al copiar, por ejemplo "Teléfono copiado".
  final String copiedMessage;

  @override
  Widget build(BuildContext context) {
    final copy = copyValue;

    return Row(
      children: [
        Expanded(
          child: DetailRow(icon: icon, label: label, value: value),
        ),
        if (copy != null)
          IconButton(
            tooltip: 'Copiar',
            icon: const Icon(Icons.copy_rounded, size: 20),
            color: AppColors.primary,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: copy));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(copiedMessage)));
            },
          ),
      ],
    );
  }
}

/// Pide confirmación para comenzar la atención de la incidencia
/// [reportNumber]. Devuelve `true` si el técnico confirmó.
Future<bool> confirmStartAttention(
  BuildContext context,
  String reportNumber,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('¿Comenzar la atención?'),
      content: Text(
        'La incidencia $reportNumber pasará a "En proceso" y se avisará '
        'al residente.',
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  key: const Key('detail.startConfirm'),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Comenzar'),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  return confirmed == true;
}
