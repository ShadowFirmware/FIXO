import 'package:flutter/foundation.dart';

import '../../../incidents/data/datasources/evidence_picker.dart';
import '../../../incidents/domain/entities/evidence_file.dart';
import '../../../incidents/domain/entities/incident.dart';

/// ViewModel de la pantalla para registrar una incidencia (HU-2.3).
class RegisterIncidentViewModel extends ChangeNotifier {
  RegisterIncidentViewModel({EvidencePicker? picker})
    : _picker = picker ?? EvidencePicker();

  static const maxTitleLength = 80;
  static const maxDescriptionLength = 500;
  static const maxEvidence = 5;

  final EvidencePicker _picker;
  bool _disposed = false;

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

  final List<EvidenceFile> _evidence = [];
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

    final room = maxEvidence - _evidence.length;
    if (picked.length > room) {
      _evidenceMessage = 'Solo puedes adjuntar hasta $maxEvidence evidencias.';
    }
    _evidence.addAll(picked.take(room));
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
