import 'package:flutter/foundation.dart';

import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_session.dart';

/// ViewModel de la pantalla de perfil del residente (HU-2.1).
///
/// Toma los datos del usuario autenticado desde la sesión y los entrega
/// listos para mostrarse.
class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({AuthSession? session})
    : _session = session ?? AuthSession.instance {
    _session.addListener(notifyListeners);
  }

  static const _noData = 'Sin registrar';
  static const _months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  final AuthSession _session;

  AppUser? get _user => _session.currentUser;

  String get name => _valueOrEmpty(_user?.name);
  String get email => _valueOrEmpty(_user?.email);
  String get phone => _valueOrEmpty(_user?.phone);

  // TODO: mostrar el nombre de la vivienda cuando exista su repositorio;
  // por ahora se muestra el identificador guardado en el usuario.
  String get housing => _valueOrEmpty(_user?.housingId);

  /// Iniciales para el avatar (máximo dos letras).
  String get initials {
    final words = (_user?.name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2);
    final letters = words.map((word) => word[0].toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }

  bool get isAccountActive => _user?.accountStatus == AccountStatus.active;

  String get accountStatus => switch (_user?.accountStatus) {
    AccountStatus.active => 'Activa',
    AccountStatus.suspended => 'Suspendida',
    AccountStatus.disabled => 'Deshabilitada',
    AccountStatus.removed => 'Dada de baja',
    null => _noData,
  };

  String get memberSince {
    final date = _user?.createdAt;
    if (date == null) return _noData;
    return '${date.day} de ${_months[date.month - 1]} de ${date.year}';
  }

  String _valueOrEmpty(String? value) =>
      (value == null || value.trim().isEmpty) ? _noData : value.trim();

  @override
  void dispose() {
    _session.removeListener(notifyListeners);
    super.dispose();
  }
}
