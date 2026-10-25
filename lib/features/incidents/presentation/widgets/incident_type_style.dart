import 'package:flutter/material.dart';

import '../../domain/entities/incident.dart';

/// Ícono de cada tipo de incidencia.
extension IncidentTypeStyle on IncidentType {
  IconData get icon => switch (this) {
    IncidentType.electricity => Icons.lightbulb_outline_rounded,
    IncidentType.water => Icons.water_drop_outlined,
    IncidentType.structure => Icons.foundation_rounded,
    IncidentType.other => Icons.more_horiz_rounded,
  };
}
