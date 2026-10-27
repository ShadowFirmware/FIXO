import 'package:flutter/foundation.dart';

import '../../../../core/errors/auth_failure.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../housing/data/repositories/housing_repository_impl.dart';
import '../../../housing/domain/entities/housing.dart';
import '../../../housing/domain/repositories/housing_repository.dart';

/// ViewModel para registrar un residente (HU-4.3).
class RegisterResidentViewModel extends ChangeNotifier {
  RegisterResidentViewModel({
    AuthRemoteDataSource? auth,
    HousingRepository? housings,
  })  : _auth = auth ?? AuthRemoteDataSource(),
        _housings = housings ?? HousingRepositoryImpl() {
    _loadHousings();
  }

  final AuthRemoteDataSource _auth;
  final HousingRepository _housings;
  bool _disposed = false;

  List<Housing> _housingsList = [];
  bool _loadingHousings = false;
  String? _housingsError;

  List<Housing> get housings => _housingsList;
  bool get loadingHousings => _loadingHousings;
  String? get housingsError => _housingsError;

  Housing? _selectedHousing;
  Housing? get selectedHousing => _selectedHousing;

  String _name = '';
  String _email = '';
  String _phone = '';
  String _password = '';

  bool _isSaving = false;
  String? _errorMessage;
  bool _success = false;

  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  bool get success => _success;

  Future<void> _loadHousings() async {
    _loadingHousings = true;
    if (!_disposed) notifyListeners();
    try {
      final list = await _housings.getAll();
      _housingsList = list.where((h) => h.active && h.residentId == null).toList();
    } catch (_) {
      _housingsError = 'No se pudieron cargar las viviendas';
    } finally {
      _loadingHousings = false;
      if (!_disposed) notifyListeners();
    }
  }

  void setHousing(Housing? housing) {
    _selectedHousing = housing;
    notifyListeners();
  }

  void edit({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) {
    _name = name;
    _email = email;
    _phone = phone;
    _password = password;
  }

  Future<bool> register() async {
    if (_isSaving) return false;

    final invalid = Validators.name(_name) ??
        Validators.email(_email) ??
        Validators.phone(_phone) ??
        _validatePassword(_password);
    if (invalid != null) {
      _errorMessage = invalid;
      notifyListeners();
      return false;
    }

    if (_selectedHousing == null) {
      _errorMessage = 'Selecciona una vivienda';
      notifyListeners();
      return false;
    }

    if (!_selectedHousing!.active || _selectedHousing!.residentId != null) {
      _errorMessage = 'La vivienda seleccionada no está disponible';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    _success = false;
    if (!_disposed) notifyListeners();

    try {
      await _auth.createUser(email: _email.trim(), password: _password);
      final uid = _auth.currentUid;
      if (uid == null) throw AuthFailure.unknown;

      final user = UserModel(
        uid: uid,
        name: _normalizedName,
        email: _email.trim(),
        phone: _phone.trim(),
        role: UserRole.resident,
        accountStatus: AccountStatus.active,
        conductStatus: ConductStatus.good,
        housingId: _selectedHousing!.id,
      );

      await _auth.createUserDocument(user);
      await _housings.assignResident(housingId: _selectedHousing!.id, residentId: uid);

      _success = true;
      return true;
    } on Exception catch (e) {
      if (e.toString().contains('email-already-in-use')) {
        _errorMessage = AuthFailure.emailAlreadyInUse.message;
      } else if (e.toString().contains('weak-password')) {
        _errorMessage = 'La contraseña debe tener mínimo 8 caracteres';
      } else if (e.toString().contains('invalid-email')) {
        _errorMessage = Validators.email(_email);
      } else {
        _errorMessage = AuthFailure.unknown.message;
      }
    } finally {
      _isSaving = false;
      if (!_disposed) notifyListeners();
    }
    return false;
  }

  String get _normalizedName => _name.trim().replaceAll(RegExp(r'\s+'), ' ');

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Ingresa una contraseña';
    if (value.length < 8) return 'La contraseña debe tener mínimo 8 caracteres';
    return null;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
