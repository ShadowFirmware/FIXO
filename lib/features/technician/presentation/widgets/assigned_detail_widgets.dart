import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../../incidents/presentation/widgets/incident_status_view.dart';

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
  const AssignedDetailSummary({super.key, required this.incident});

  final Incident incident;

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
