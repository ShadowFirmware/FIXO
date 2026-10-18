import 'package:flutter/foundation.dart';

import '../../../../core/errors/auth_failure.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/usecases/sign_in.dart';

/// ViewModel de la pantalla de inicio de sesión.
class LoginViewModel extends ChangeNotifier {
  LoginViewModel({SignIn? signIn})
    : _signIn = signIn ?? SignIn(AuthRepositoryImpl());

  final SignIn _signIn;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Devuelve el usuario autenticado, o `null` si falló; en ese caso el
  /// motivo queda en [errorMessage].
  Future<AppUser?> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      return await _signIn(email: email, password: password);
    } on AuthFailure catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = AuthFailure.unknown.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }
}
