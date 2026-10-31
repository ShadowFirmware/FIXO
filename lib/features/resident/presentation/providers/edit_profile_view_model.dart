import 'package:flutter/foundation.dart';

import '../../../../core/errors/profile_failure.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_session.dart';
import '../../../housing/data/repositories/housing_repository_impl.dart';
import '../../../housing/domain/repositories/housing_repository.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/repositories/profile_repository.dart';

/// ViewModel de la pantalla para modificar el perfil.
class EditProfileViewModel extends ChangeNotifier {
  EditProfileViewModel({
    AuthSession? session,
    HousingRepository? housings,
    ProfileRepository? profiles,
  }) : _session = session ?? AuthSession.instance,
       _housings = housings ?? HousingRepositoryImpl(),
       _profiles = profiles ?? ProfileRepositoryImpl() {
    _name = initialName;
    _email = initialEmail;
    _phone = initialPhone;
    _loadHousing();
  }

  static const maxNameLength = 80;
  static const phoneLength = 10;

  final AuthSession _session;
  final HousingRepository _housings;
  final ProfileRepository _profiles;
  bool _disposed = false;

  AppUser? get _user => _session.currentUser;

  /// Datos actuales con los que se llena el formulario.
  String get initialName => _user?.name.trim() ?? '';
  String get initialEmail => _user?.email.trim() ?? '';
  String get initialPhone => _user?.phone.trim() ?? '';
  String get email => _user?.email ?? '';

  /// Nombre de la vivienda asignada. Es de solo lectura: solo un
  /// administrador puede cambiarla.
  String _housing = 'Cargando…';
  String get housing => _housing;

  Future<void> _loadHousing() async {
    final id = _user?.housingId?.trim() ?? '';
    if (id.isEmpty) {
      _housing = 'Sin registrar';
      return;
    }
    try {
      final housing = await _housings.getById(id);
      _housing = housing?.label ?? 'No disponible';
    } catch (_) {
      _housing = 'No disponible';
    }
    if (!_disposed) notifyListeners();
  }

  String _name = '';
  String _email = '';
  String _phone = '';
  bool _hasChanges = false;
  bool _isSaving = false;
  String? _errorMessage;

  /// `true` si hay cambios respecto a los datos guardados.
  bool get hasChanges => _hasChanges;
  bool get isSaving => _isSaving;

  /// Motivo por el que no se guardó, listo para mostrarse.
  String? get errorMessage => _errorMessage;

  /// Registra lo que el usuario escribe en el formulario.
  void edit({required String name, String? email, required String phone}) {
    _name = name;
    if (email != null) _email = email;
    _phone = phone;
    final hasChanges = _normalizedName != initialName ||
        _email.trim().toLowerCase() != initialEmail.toLowerCase() ||
        _phone.trim() != initialPhone;
    if (hasChanges == _hasChanges) return;
    _hasChanges = hasChanges;
    notifyListeners();
  }

  /// Quita espacios de más: "  Ana   Ruiz " → "Ana Ruiz".
  String get _normalizedName => _name.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Guarda los cambios. Devuelve `false` si no se guardó; en
  /// ese caso el motivo queda en [errorMessage].
  Future<bool> save() async {
    final user = _user;
    if (_isSaving || user == null) return false;

    final invalid = Validators.name(_name) ??
        Validators.email(_email) ??
        Validators.phone(_phone);
    if (invalid != null) {
      _errorMessage = invalid;
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final name = _normalizedName;
      final email = _email.trim().toLowerCase();
      final phone = _phone.trim();
      await _profiles.updateContactInfo(
        uid: user.uid,
        name: name,
        email: email,
        phone: phone,
      );
      _session.update(
        user.copyWith(name: name, phone: phone).copyWithEmail(email),
      );
      _hasChanges = false;
      return true;
    } on ProfileFailure catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = ProfileFailure.unknown.message;
    } finally {
      _isSaving = false;
      if (!_disposed) notifyListeners();
    }
    return false;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
