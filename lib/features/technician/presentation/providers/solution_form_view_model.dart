import 'package:flutter/foundation.dart';

import '../../domain/entities/assigned_incident.dart';

/// ViewModel del registro de la solución de una incidencia (HU-3.6).
class SolutionFormViewModel extends ChangeNotifier {
  SolutionFormViewModel({required this.item});

  /// Incidencia a la que se le registra la solución.
  final AssignedIncident item;

  static const maxDescriptionLength = 500;

  String _description = '';

  /// Descripción de la solución aplicada, tal como la escribe el técnico.
  String get description => _description;

  void setDescription(String value) {
    if (value == _description) return;
    _description = value;
    notifyListeners();
  }
}
