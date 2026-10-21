import 'package:flutter/foundation.dart';

import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_session.dart';

/// ViewModel de la pantalla para modificar el perfil del residente (HU-2.2).
class EditProfileViewModel extends ChangeNotifier {
  EditProfileViewModel({AuthSession? session})
    : _session = session ?? AuthSession.instance;

  final AuthSession _session;

  AppUser? get _user => _session.currentUser;

  /// Datos actuales con los que se llena el formulario.
  String get initialName => _user?.name.trim() ?? '';
  String get initialPhone => _user?.phone.trim() ?? '';
  String get email => _user?.email ?? '';
}
