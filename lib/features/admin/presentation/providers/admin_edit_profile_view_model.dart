import 'package:flutter/foundation.dart';

import '../../../../core/errors/profile_failure.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_session.dart';
import '../../../resident/data/repositories/profile_repository_impl.dart';
import '../../../resident/domain/repositories/profile_repository.dart';

/// ViewModel para modificar el perfil del administrador (HU-4.2).
class AdminEditProfileViewModel extends ChangeNotifier {
  AdminEditProfileViewModel({
    AuthSession? session,
    ProfileRepository? profiles,
  })  : _session = session ?? AuthSession.instance,
        _profiles = profiles ?? ProfileRepositoryImpl() {
    _name = initialName;
    _email = initialEmail;
    _phone = initialPhone;
  }

  static const maxNameLength = 80;
  static const phoneLength = 10;

  final AuthSession _session;
  final ProfileRepository _profiles;
  bool _disposed = false;

  AppUser? get _user => _session.currentUser;

  String get initialName => _user?.name.trim() ?? '';
  String get initialEmail => _user?.email.trim() ?? '';
  String get initialPhone => _user?.phone.trim() ?? '';

  String _name = '';
  String _email = '';
  String _phone = '';
  bool _hasChanges = false;
  bool _isSaving = false;
  String? _errorMessage;

  bool get hasChanges => _hasChanges;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  void edit({required String name, required String email, required String phone}) {
    _name = name;
    _email = email;
    _phone = phone;
    final hasChanges = _normalizedName != initialName ||
        _email.trim() != initialEmail ||
        _phone.trim() != initialPhone;
    if (hasChanges == _hasChanges) return;
    _hasChanges = hasChanges;
    notifyListeners();
  }

  String get _normalizedName => _name.trim().replaceAll(RegExp(r'\s+'), ' ');

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
      final email = _email.trim();
      final phone = _phone.trim();
      await _profiles.updateProfile(
        uid: user.uid,
        name: name,
        email: email,
        phone: phone,
        currentEmail: initialEmail,
      );
      _session.update(user.copyWith(name: name, email: email, phone: phone));
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
