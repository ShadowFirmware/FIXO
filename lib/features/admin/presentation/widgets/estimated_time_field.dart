import 'package:flutter/material.dart';

import '../../../../core/utils/date_formats.dart';
import '../providers/pending_incidents_view_model.dart';

/// Campo de la hora estimada de llegada (HU-4.9). La fecha y la hora se
/// eligen con los selectores del sistema, no se escriben a mano.
class EstimatedTimeField extends StatelessWidget {
  const EstimatedTimeField({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final String? errorText;

  /// Hora sugerida: dentro de una hora, redondeada al siguiente cuarto.
  static DateTime suggestedTime(DateTime now) {
    final inOneHour = now.add(const Duration(hours: 1));
    final extra = (15 - inOneHour.minute % 15) % 15;
    return DateTime(
      inOneHour.year,
      inOneHour.month,
      inOneHour.day,
      inOneHour.hour,
      inOneHour.minute + extra,
    );
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final initial = value ?? suggestedTime(now);
    final today = DateTime(now.year, now.month, now.day);

    final date = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(today) ? today : initial,
      firstDate: today,
      lastDate: today.add(
        const Duration(days: PendingIncidentsViewModel.maxDaysAhead),
      ),
      helpText: 'Fecha de llegada',
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: 'Hora de llegada',
    );
    if (time == null) return;

    onChanged(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = value;

    return InkWell(
      key: const Key('assign.estimatedTime'),
      borderRadius: BorderRadius.circular(12),
      onTap: () => _pick(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Fecha y hora de llegada',
          prefixIcon: const Icon(Icons.schedule_outlined),
          suffixIcon: const Icon(Icons.edit_calendar_outlined),
          errorText: errorText,
        ),
        isEmpty: selected == null,
        child: Text(selected == null ? '' : DateFormats.dateTime(selected)),
      ),
    );
  }
}
