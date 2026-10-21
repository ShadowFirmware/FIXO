import 'package:flutter/foundation.dart';

import '../../../incidents/domain/entities/incident.dart';

/// ViewModel de la pantalla para registrar una incidencia (HU-2.3).
class RegisterIncidentViewModel extends ChangeNotifier {
  static const maxTitleLength = 80;
  static const maxDescriptionLength = 500;

  /// Lo que el residente escribe en el formulario.
  String title = '';
  String description = '';

  IncidentType? _type;
  IncidentType? get type => _type;

  void selectType(IncidentType type) {
    if (_type == type) return;
    _type = type;
    notifyListeners();
  }
}
