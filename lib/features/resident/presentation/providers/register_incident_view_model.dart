import 'package:flutter/foundation.dart';

import '../../../../core/utils/validators.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_session.dart';
import '../../../housing/data/repositories/housing_repository_impl.dart';
import '../../../housing/domain/repositories/housing_repository.dart';
import '../../../incidents/data/datasources/evidence_picker.dart';
import '../../../incidents/domain/entities/evidence_file.dart';
import '../../../incidents/domain/entities/incident.dart';

/// ViewModel de la pantalla para registrar una incidencia (HU-2.3).
class RegisterIncidentViewModel extends ChangeNotifier {
  RegisterIncidentViewModel({
    AuthSession? session,
    HousingRepository? housings,
    EvidencePicker? picker,
  }) : _session = session ?? AuthSession.instance,
       _housings = housings ?? HousingRepositoryImpl(),
       _picker = picker ?? EvidencePicker() {
    _loadHousing();
  }

  static const maxTitleLength = 80;
  static const maxDescriptionLength = 500;
  static const maxEvidence = 5;
  static const maxPhotoBytes = 10 * 1024 * 1024;
  static const maxVideoBytes = 50 * 1024 * 1024;

  final AuthSession _session;
  final HousingRepository _housings;
  final EvidencePicker _picker;
  bool _disposed = false;

  AppUser? get _user => _session.currentUser;

  /// Vivienda a la que se asocia la incidencia. Es la del residente y no se
  /// puede cambiar desde el formulario.
  String _housing = 'Cargando…';
  String get housing => _housing;

  bool get hasHousing => (_user?.housingId?.trim() ?? '').isNotEmpty;

  Future<void> _loadHousing() async {
    if (!hasHousing) {
      _housing = 'Sin vivienda asignada';
      return;
    }
    try {
      final housing = await _housings.getById(_user!.housingId!.trim());
      _housing = housing?.label ?? 'No disponible';
    } catch (_) {
      _housing = 'No disponible';
    }
    if (!_disposed) notifyListeners();
  }

  /// Lo que el residente escribe en el formulario.
  String title = '';
  String description = '';

  IncidentType? _type;
  IncidentType? get type => _type;

  /// Se muestra si se intenta registrar sin elegir un tipo.
  String? _typeError;
  String? get typeError => _typeError;

  void selectType(IncidentType type) {
    if (_type == type) return;
    _type = type;
    _typeError = null;
    notifyListeners();
  }

  /// Revisa los campos obligatorios y los datos ingresados. Devuelve el
  /// primer error, o `null` si todo es válido.
  String? validate() {
    _typeError = _type == null ? 'Elige el tipo de incidencia' : null;
    notifyListeners();
    return Validators.incidentTitle(title) ??
        _typeError ??
        Validators.incidentDescription(description);
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

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
