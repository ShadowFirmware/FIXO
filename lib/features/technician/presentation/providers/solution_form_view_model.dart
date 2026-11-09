import 'package:flutter/foundation.dart';

import '../../../../core/utils/validators.dart';
import '../../../incidents/data/datasources/evidence_picker.dart';
import '../../../incidents/domain/entities/evidence_file.dart';
import '../../domain/entities/assigned_incident.dart';

/// ViewModel del registro de la solución de una incidencia (HU-3.6).
class SolutionFormViewModel extends ChangeNotifier {
  SolutionFormViewModel({required this.item, EvidencePicker? picker})
    : _picker = picker ?? EvidencePicker();

  /// Incidencia a la que se le registra la solución.
  final AssignedIncident item;

  final EvidencePicker _picker;
  bool _disposed = false;

  static const maxDescriptionLength = 500;

  // Mismos límites que las evidencias del residente (HU-2.3).
  static const maxEvidence = 5;
  static const maxPhotoBytes = 10 * 1024 * 1024;
  static const maxVideoBytes = 50 * 1024 * 1024;

  String _description = '';

  /// Descripción de la solución aplicada, tal como la escribe el técnico.
  String get description => _description;

  void setDescription(String value) {
    if (value == _description) return;
    _description = value;
    notifyListeners();
  }

  final List<EvidenceFile> _evidence = [];

  /// Fotos y videos del trabajo realizado, en el orden en que se agregaron.
  List<EvidenceFile> get evidence => List.unmodifiable(_evidence);
  bool get canAddEvidence => _evidence.length < maxEvidence;

  /// Mensaje para mostrar si no se pudo agregar una evidencia.
  String? _evidenceMessage;
  String? get evidenceMessage => _evidenceMessage;

  Future<void> addPhotos({required bool fromCamera}) =>
      _add(() => _picker.pickPhotos(fromCamera: fromCamera));

  Future<void> addVideo({required bool fromCamera}) => _add(() async {
    final video = await _picker.pickVideo(fromCamera: fromCamera);
    return [?video];
  });

  void removeEvidence(EvidenceFile file) {
    if (!_evidence.remove(file)) return;
    _evidenceMessage = null;
    notifyListeners();
  }

  Future<void> _add(Future<List<EvidenceFile>> Function() pick) async {
    if (!canAddEvidence) return;
    _evidenceMessage = null;

    List<EvidenceFile> picked;
    try {
      picked = await pick();
    } catch (_) {
      picked = const [];
      _evidenceMessage = 'No se pudo abrir la cámara o la galería.';
    }
    if (_disposed) return;

    // Los archivos muy pesados tardarían mucho en subirse.
    final accepted = picked.where(_fitsSizeLimit).toList();
    if (accepted.length < picked.length) {
      _evidenceMessage =
          'Las fotos pueden pesar hasta 10 MB y los videos hasta 50 MB.';
    }

    final room = maxEvidence - _evidence.length;
    if (accepted.length > room) {
      _evidenceMessage = 'Solo puedes adjuntar hasta $maxEvidence evidencias.';
    }
    _evidence.addAll(accepted.take(room));
    notifyListeners();
  }

  bool _reviewing = false;

  /// El técnico está revisando la solución y las evidencias antes de
  /// guardarlas.
  bool get isReviewing => _reviewing;

  static const missingEvidenceMessage =
      'Agrega al menos una foto o video del trabajo realizado.';

  /// Los errores se muestran después del primer intento de revisar.
  bool _showErrors = false;

  String? get descriptionError => Validators.solutionDescription(_description);

  /// Error de las evidencias obligatorias, o `null` si hay al menos una.
  String? get evidenceError =>
      _showErrors && _evidence.isEmpty ? missingEvidenceMessage : null;

  /// La descripción es válida y hay al menos una evidencia.
  bool get isComplete => descriptionError == null && _evidence.isNotEmpty;

  /// Pasa a revisar la información antes de guardarla, solo si está
  /// completa. Devuelve `false` si falta algo.
  bool review() {
    _showErrors = true;
    _reviewing = isComplete;
    notifyListeners();
    return _reviewing;
  }

  /// Vuelve al formulario para corregir la información.
  void edit() {
    if (!_reviewing) return;
    _reviewing = false;
    notifyListeners();
  }

  static bool _fitsSizeLimit(EvidenceFile file) =>
      file.sizeBytes <= (file.isVideo ? maxVideoBytes : maxPhotoBytes);

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
