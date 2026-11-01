import 'package:flutter/foundation.dart';

import '../../../../core/errors/auth_failure.dart';
import '../../../../core/errors/profile_failure.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/domain/entities/app_user.dart';

import '../../data/repositories/technician_admin_repository_impl.dart';
import '../../domain/repositories/technician_admin_repository.dart';

class TechnicianAdminViewModel extends ChangeNotifier {
  TechnicianAdminViewModel({
    TechnicianAdminRepository? repository,
  })  : _repository = repository ?? TechnicianAdminRepositoryImpl();

  final TechnicianAdminRepository _repository;

  bool _disposed = false;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  List<AppUser> _technicians = const [];
  List<AppUser> get technicians => _technicians;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _technicians = await _repository.listTechnicians();
    } catch (e) {
      _errorMessage = e is AuthFailure || e is ProfileFailure
          ? e.toString()
          : 'No se pudieron cargar los técnicos.';
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
    required String specialty,
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
    if (specialty.trim().isEmpty) {
      _errorMessage = 'Ingresa la especialidad';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();
    try {
      await _repository.registerTechnician(
        name: name,
        email: email,
        phone: phone,
        password: password,
        specialty: specialty,
      );
      _successMessage = 'Técnico registrado correctamente.';
      await load();
      return true;
    } catch (e) {
      _errorMessage = e is AuthFailure || e is ProfileFailure
          ? e.toString()
          : 'No se pudo registrar el técnico.';
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

  Future<bool> update(
    AppUser technician, {
    required String name,
    required String email,
    required String phone,
    required String specialty,
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
    if (specialty.trim().isEmpty) {
      _errorMessage = 'Ingresa la especialidad';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();
    try {
      await _repository.updateTechnician(
        uid: technician.uid,
        name: name,
        email: email,
        phone: phone,
        specialty: specialty,
      );
      _successMessage = 'Técnico actualizado correctamente.';
      await load();
      return true;
    } catch (e) {
      _errorMessage = e is AuthFailure || e is ProfileFailure
          ? e.toString()
          : 'No se pudo actualizar el técnico.';
      _isLoading = false;
      if (!_disposed) notifyListeners();
      return false;
    }
  }

  Future<bool> _remove(AppUser technician) async {
    _errorMessage = null;
    _successMessage = null;
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.removeTechnician(uid: technician.uid);
      _successMessage = 'Técnico dado de baja correctamente.';
      await load();
      return true;
    } catch (e) {
      _errorMessage = e is AuthFailure || e is ProfileFailure
          ? e.toString()
          : 'No se pudo dar de baja al técnico.';
      _isLoading = false;
      if (!_disposed) notifyListeners();
      return false;
    }
  }

  Future<bool> delete(AppUser technician) => _remove(technician);

  Future<bool> remove(AppUser technician) => _remove(technician);

  Future<bool> deactivate(AppUser technician) => _remove(technician);

  Future<bool> _enable(AppUser technician) async {
    _errorMessage = null;
    _successMessage = null;
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.enableTechnician(uid: technician.uid);
      _successMessage = 'Técnico habilitado correctamente.';
      await load();
      return true;
    } catch (e) {
      _errorMessage = e is AuthFailure || e is ProfileFailure
          ? e.toString()
          : 'No se pudo habilitar al técnico.';
      _isLoading = false;
      if (!_disposed) notifyListeners();
      return false;
    }
  }

  Future<bool> enable(AppUser technician) => _enable(technician);

  Future<bool> activate(AppUser technician) => _enable(technician);

  Future<bool> habilitar(AppUser technician) => _enable(technician);

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
