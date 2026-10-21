import 'package:flutter/foundation.dart';

import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_session.dart';

/// ViewModel de la pantalla para modificar el perfil del residente (HU-2.2).
class EditProfileViewModel extends ChangeNotifier {
  EditProfileViewModel({AuthSession? session})
    : _session = session ?? AuthSession.instance;

  static const maxNameLength = 80;
  static const phoneLength = 10;

  final AuthSession _session;

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
