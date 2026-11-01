import 'package:flutter/foundation.dart';

import '../../../../core/errors/auth_failure.dart';
import '../../../../core/errors/profile_failure.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../housing/domain/entities/housing.dart';

import '../../data/repositories/resident_admin_repository_impl.dart';
import '../../domain/repositories/resident_admin_repository.dart';

/// ViewModel para la gestión de residentes por parte del administrador.
class ResidentAdminViewModel extends ChangeNotifier {
  ResidentAdminViewModel({
    ResidentAdminRepository? repository,
  })  : _repository = repository ?? ResidentAdminRepositoryImpl();

  final ResidentAdminRepository _repository;

  bool _disposed = false;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  List<AppUser> _residents = const [];
  List<AppUser> get residents => _residents;

  List<Housing> _availableHousings = const [];
  List<Housing> get availableHousings => _availableHousings;

  List<Housing> _housings = const [];
  List<Housing> get housings => _housings;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _residents = await _repository.listResidents();
      _housings = await _repository.listHousings();
      _availableHousings = _housings.where((h) => h.residentId == null).toList();
    } catch (e) {
      _errorMessage = e is AuthFailure || e is ProfileFailure
          ? e.toString()
          : 'No se pudieron cargar los residentes.';
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String housingId,
  }) async {
    _errorMessage = null;
    _successMessage = null;

    final invalid = Validators.name(name) ??
        Validators.email(email) ??
        Validators.phone(phone) ??
        _validatePassword(password);
    if (invalid != null) {
      _errorMessage = invalid;
      notifyListeners();
      return false;
    }

    if (housingId.isEmpty) {
      _errorMessage = 'Selecciona una vivienda.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();
    try {
      await _repository.registerResident(
        name: name,
        email: email,
        phone: phone,
        password: password,
        housingId: housingId,
      );
      _successMessage = 'Residente registrado correctamente.';
      await load();
      return true;
    } catch (e) {
      _errorMessage = e is AuthFailure || e is ProfileFailure
          ? e.toString()
          : 'No se pudo registrar el residente.';
      _isLoading = false;
      if (!_disposed) notifyListeners();
      return false;
    }
  }

  Future<bool> update(
    AppUser resident, {
    required String name,
    required String email,
    required String phone,
    required String housingId,
  }) async {
    _errorMessage = null;
    _successMessage = null;

    final invalid = Validators.name(name) ??
        Validators.email(email) ??
        Validators.phone(phone);
    if (invalid != null) {
      _errorMessage = invalid;
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();
    try {
      await _repository.updateResident(
        uid: resident.uid,
        name: name,
        email: email,
        phone: phone,
        housingId: housingId,
        previousHousingId: resident.housingId,
      );
      _successMessage = 'Residente actualizado correctamente.';
      await load();
      return true;
    } catch (e) {
      _errorMessage = e is AuthFailure || e is ProfileFailure
          ? e.toString()
          : 'No se pudo actualizar el residente.';
      _isLoading = false;
      if (!_disposed) notifyListeners();
      return false;
    }
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) return 'Ingresa una contraseña';
    if (value.length < 8) return 'La contraseña debe tener al menos 8 caracteres';
    return null;
  }

  Future<bool> delete(AppUser resident) async {
    _errorMessage = null;
    _successMessage = null;
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.deleteResident(
        uid: resident.uid,
        housingId: resident.housingId,
      );
      _successMessage = 'Residente eliminado correctamente.';
      await load();
      return true;
    } catch (e) {
      _errorMessage = e is AuthFailure || e is ProfileFailure
          ? e.toString()
          : 'No se pudo eliminar el residente.';
      _isLoading = false;
      if (!_disposed) notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}