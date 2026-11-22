import 'package:flutter/foundation.dart';

import '../../../../core/errors/conduct_report_failure.dart';
import '../../../../core/utils/validators.dart';
import '../../../incidents/data/datasources/evidence_picker.dart';
import '../../../incidents/domain/entities/evidence_file.dart';
import '../../domain/entities/conduct_report.dart';
import '../../domain/usecases/report_technician.dart';

/// Lo común de los formularios de reporte de conducta: motivo, descripción,
/// evidencias opcionales y envío. Lo usan el residente que reporta al
/// técnico (HU-7.1) y el técnico que reporta al residente (HU-7.2).
abstract class ConductReportFormViewModel extends ChangeNotifier {
  ConductReportFormViewModel({EvidencePicker? picker})
    : _picker = picker ?? EvidencePicker();

  final EvidencePicker _picker;
  bool _disposed = false;

  static const maxDescriptionLength = 500;

  // Mismos límites que las evidencias de las incidencias (HU-2.3).
  static const maxEvidence = ReportTechnician.maxEvidence;
  static const maxPhotoBytes = 10 * 1024 * 1024;
  static const maxVideoBytes = 50 * 1024 * 1024;

  /// Motivos que se pueden elegir.
  List<ConductReason> get reasons;

  /// Guarda el reporte con los datos ya validados.
  @protected
  Future<ConductReport> send(ConductReason reason);

  /// Otro error del formulario antes del motivo, o `null`. Por ejemplo, que
  /// falte elegir a quién se reporta.
  @protected
  String? validateTarget() => null;

  ConductReason? _reason;
  ConductReason? get reason => _reason;

  /// Se muestra si se intenta enviar sin elegir el motivo.
  String? _reasonError;
  String? get reasonError => _reasonError;

  void selectReason(ConductReason reason) {
    if (_reason == reason) return;
    _reason = reason;
    _reasonError = null;
    notifyListeners();
  }

  /// Lo que se escribe sobre lo ocurrido.
  String description = '';

  /// Revisa a quién se reporta, el motivo y la descripción. Devuelve el
  /// primer error, o `null` si todo es válido.
  String? validate() {
    _reasonError = _reason == null
        ? ConductReportFailure.reasonRequired.message
        : null;
    final target = validateTarget();
    notifyListeners();
    return target ?? _reasonError ?? Validators.conductDescription(description);
  }

  final List<EvidenceFile> _evidence = [];

  /// Fotos, videos o capturas del chat, opcionales.
  List<EvidenceFile> get evidence => List.unmodifiable(_evidence);
  bool get canAddEvidence => _evidence.length < maxEvidence && !_saving;

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
    if (_saving || !_evidence.remove(file)) return;
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

  static bool _fitsSizeLimit(EvidenceFile file) =>
      file.sizeBytes <= (file.isVideo ? maxVideoBytes : maxPhotoBytes);

  bool _saving = false;

  /// Se están subiendo las evidencias y guardando el reporte.
  bool get isSaving => _saving;

  /// Motivo por el que no se envió, listo para mostrarse.
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Envía el reporte. Devuelve el reporte guardado, o `null` si los datos
  /// son inválidos o falló; en ese caso el motivo queda en [errorMessage].
  Future<ConductReport?> submit() async {
    if (_saving) return null;
    final invalid = validate();
    if (invalid != null) {
      _errorMessage = invalid;
      notifyListeners();
      return null;
    }

    _saving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      return await send(_reason!);
    } on ConductReportIncompleteException catch (e) {
      _errorMessage = e.message;
    } on ConductReportFailure catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = ConductReportFailure.unknown.message;
    } finally {
      _saving = false;
      if (!_disposed) notifyListeners();
    }
    return null;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
