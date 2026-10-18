import 'package:flutter/foundation.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Sesión de la app: guarda el usuario autenticado para que cualquier
/// pantalla pueda consultarlo.
///
/// Firebase Authentication conserva la sesión en el dispositivo, así que al
/// abrir la app de nuevo [restore] recupera al usuario sin pedir credenciales.
class AuthSession extends ChangeNotifier {
  AuthSession._(this._repository);

  static final AuthSession instance = AuthSession._(AuthRepositoryImpl());

  final AuthRepository _repository;

  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  void start(AppUser user) {
    _currentUser = user;
    notifyListeners();
  }

  /// Devuelve el usuario de la sesión guardada, o `null` si hay que iniciar
  /// sesión de nuevo.
  Future<AppUser?> restore() async {
    _currentUser = await _repository.restoreSession();
    notifyListeners();
    return _currentUser;
  }

  Future<void> signOut() async {
    await _repository.signOut();
    _currentUser = null;
    notifyListeners();
  }
}
