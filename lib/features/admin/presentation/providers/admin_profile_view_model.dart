import 'package:flutter/foundation.dart';

import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_session.dart';
import '../../../housing/data/repositories/housing_repository_impl.dart';
import '../../../housing/domain/entities/housing.dart';
import '../../../housing/domain/repositories/housing_repository.dart';

/// ViewModel de la pantalla de perfil del administrador (HU-4.1).
class AdminProfileViewModel extends ChangeNotifier {
  AdminProfileViewModel({AuthSession? session, HousingRepository? housings})
    : _session = session ?? AuthSession.instance,
      _housings = housings ?? HousingRepositoryImpl() {
    _session.addListener(_onSessionChanged);
    _loadHousing();
  }

  static const _noData = 'Sin registrar';
  static const _loading = 'Cargando…';
  static const _unavailable = 'No disponible';
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
  final HousingRepository _housings;

  Housing? _housing;
  String? _requestedHousingId;
  bool _isLoadingHousing = false;
  bool _housingFailed = false;

  AppUser? get _user => _session.currentUser;

  String get name => _valueOrEmpty(_user?.name);
  String get email => _valueOrEmpty(_user?.email);
  String get phone => _valueOrEmpty(_user?.phone);

  String get housing {
    if (_valueOrEmpty(_user?.housingId) == _noData) return _noData;
    if (_isLoadingHousing) return _loading;
    if (_housingFailed || _housing == null) return _unavailable;
    return _housing!.label;
  }

  void _onSessionChanged() {
    if (_user?.housingId != _requestedHousingId) _loadHousing();
    notifyListeners();
  }

  Future<void> _loadHousing() async {
    final id = _user?.housingId?.trim();
    _requestedHousingId = _user?.housingId;
    _housing = null;
    _housingFailed = false;
    _isLoadingHousing = id != null && id.isNotEmpty;
    if (!_isLoadingHousing) {
      if (!_disposed) notifyListeners();
      return;
    }

    Housing? housing;
    var failed = false;
    try {
      housing = await _housings.getById(id!);
    } catch (_) {
      failed = true;
    }

    if (_disposed || _user?.housingId != _requestedHousingId) return;
    _housing = housing;
    _housingFailed = failed;
    _isLoadingHousing = false;
    notifyListeners();
  }

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

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _session.removeListener(_onSessionChanged);
    super.dispose();
  }
}
