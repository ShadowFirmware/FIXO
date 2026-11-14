import 'package:flutter/foundation.dart';

import '../../../../core/errors/incident_failure.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/presentation/providers/auth_session.dart';
import '../../../incidents/data/datasources/evidence_picker.dart';
import '../../../incidents/domain/entities/evidence_file.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../data/repositories/assigned_incident_repository_impl.dart';
import '../../domain/entities/assigned_incident.dart';
import '../../domain/repositories/assigned_incident_repository.dart';
import '../../domain/usecases/register_solution.dart';

/// ViewModel del registro de la solución de una incidencia (HU-3.6).
class SolutionFormViewModel extends ChangeNotifier {
  SolutionFormViewModel({
    required this.item,
    AuthSession? session,
    AssignedIncidentRepository? repository,
    EvidencePicker? picker,
  }) : _session = session ?? AuthSession.instance,
       _repository = repository ?? AssignedIncidentRepositoryImpl(),
       _picker = picker ?? EvidencePicker();

  /// Incidencia a la que se le registra la solución.
  final AssignedIncident item;

  final AuthSession _session;
  final AssignedIncidentRepository _repository;

  /// Por qué no se puede registrar la solución, o `null` si se puede: la
  /// incidencia debe ser del técnico en sesión y estar En proceso. Se
  /// revisa de nuevo al guardar, por si cambió mientras tanto.
  bool get hasRegisteredSolution =>
      item.incident.solution?.trim().isNotEmpty ?? false;

  IncidentFailure? get statusError {
    if (item.incident.technicianId != _session.currentUser?.uid) {
      return IncidentFailure.notAssignedToYou;
    }
    return switch (item.status) {
      // La solución se registra una sola vez (HU-3.7).
      IncidentStatus.inProgress when hasRegisteredSolution =>
        IncidentFailure.solutionAlreadyRegistered,
      IncidentStatus.inProgress => null,
      IncidentStatus.resolved => IncidentFailure.solutionAlreadyRegistered,
      IncidentStatus.assigned => IncidentFailure.attentionNotStarted,
      IncidentStatus.pending ||
      IncidentStatus.rejected => IncidentFailure.solutionNotAvailable,
    };
  }

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
    } on CameraPermissionDeniedException catch (e) {
      picked = const [];
      _evidenceMessage = e.message;
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

  static const missingEvidenceMessage = RegisterSolution.missingEvidenceMessage;

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

  bool _saving = false;

  /// Se están subiendo las evidencias y guardando la solución.
  bool get isSaving => _saving;

  /// Guarda la solución y las evidencias; la incidencia pasa a Resuelta.
  /// Devuelve el mensaje de error, o `null` si se guardó.
  Future<String?> save() async {
    if (_saving || !_reviewing) return null;
    _saving = true;
    notifyListeners();
    try {
      await RegisterSolution(_repository)(
        technician: _session.currentUser,
        incidentId: item.id,
        solution: _description,
        evidence: _evidence,
      );
      return null;
    } on SolutionIncompleteException catch (e) {
      return e.message;
    } on IncidentFailure catch (failure) {
      return failure.message;
    } catch (_) {
      return IncidentFailure.actionFailed.message;
    } finally {
      _saving = false;
      if (!_disposed) notifyListeners();
    }
  }

  /// Vuelve al formulario para corregir la información.
  void edit() {
    if (!_reviewing || _saving) return;
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
