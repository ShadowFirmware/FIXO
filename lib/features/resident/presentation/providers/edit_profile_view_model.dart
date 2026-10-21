import 'package:flutter/foundation.dart';

import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_session.dart';
import '../../../housing/data/repositories/housing_repository_impl.dart';
import '../../../housing/domain/repositories/housing_repository.dart';

/// ViewModel de la pantalla para modificar el perfil del residente (HU-2.2).
class EditProfileViewModel extends ChangeNotifier {
  EditProfileViewModel({AuthSession? session, HousingRepository? housings})
    : _session = session ?? AuthSession.instance,
      _housings = housings ?? HousingRepositoryImpl() {
    _loadHousing();
  }

  static const maxNameLength = 80;
  static const phoneLength = 10;

  final AuthSession _session;
  final HousingRepository _housings;
  bool _disposed = false;

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

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  AppUser? get _user => _session.currentUser;

  /// Datos actuales con los que se llena el formulario.
  String get initialName => _user?.name.trim() ?? '';
  String get initialPhone => _user?.phone.trim() ?? '';
  String get email => _user?.email ?? '';

  String _name = '';
  String _phone = '';
  bool _hasChanges = false;

  /// `true` si el nombre o el teléfono son distintos a los guardados.
  bool get hasChanges => _hasChanges;

  /// Registra lo que el residente escribe en el formulario.
  void edit({required String name, required String phone}) {
    _name = name;
    _phone = phone;
    final hasChanges =
        _name.trim() != initialName || _phone.trim() != initialPhone;
    if (hasChanges == _hasChanges) return;
    _hasChanges = hasChanges;
    notifyListeners();
  }
}
