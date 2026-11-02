import 'package:flutter/foundation.dart';

import '../../../../core/errors/housing_failure.dart';
import '../../../housing/data/repositories/housing_repository_impl.dart';
import '../../../housing/domain/entities/housing.dart';
import '../../../housing/domain/repositories/housing_repository.dart';

/// ViewModel de la gestión de lugares de residencia (HU-4.7).
class HousingAdminViewModel extends ChangeNotifier {
  HousingAdminViewModel({HousingRepository? repository})
    : _repository = repository ?? HousingRepositoryImpl();

  final HousingRepository _repository;

  bool _disposed = false;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  List<Housing> _housings = const [];
  List<Housing> get housings => _housings;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _housings = await _repository.listAll();
    } catch (e) {
      _errorMessage = e is HousingFailure
          ? e.message
          : 'No se pudieron cargar las residencias.';
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  /// Devuelve el primer error de los datos del formulario, o `null`.
  static String? validate({HousingType? type, required String number}) {
    if (type == null) return 'Selecciona el tipo de residencia';
    return validateNumber(number);
  }

  static String? validateNumber(String number) {
    if (number.trim().isEmpty) return 'Ingresa el número o identificador';
    if (number.trim().length > 20) {
      return 'El número no debe exceder 20 caracteres';
    }
    return null;
  }

  Future<bool> register({
    required HousingType? type,
    required String number,
    String? building,
  }) => _run(
    () async {
      await _repository.register(
        type: type!,
        number: number,
        building: building,
      );
    },
    invalid: validate(type: type, number: number),
    success: 'Residencia registrada correctamente.',
    failure: 'No se pudo registrar la residencia.',
  );

  Future<bool> update(
    Housing housing, {
    required HousingType? type,
    required String number,
    String? building,
  }) => _run(
    () => _repository.update(
      id: housing.id,
      type: type!,
      number: number,
      building: building,
    ),
    invalid: validate(type: type, number: number),
    success: 'Residencia actualizada correctamente.',
    failure: 'No se pudo actualizar la residencia.',
  );

  Future<bool> setActive(Housing housing, {required bool active}) => _run(
    () => _repository.setActive(id: housing.id, active: active),
    success: active
        ? 'Residencia activada correctamente.'
        : 'Residencia marcada como inactiva.',
    failure: 'No se pudo cambiar el estado de la residencia.',
  );

  Future<bool> _run(
    Future<void> Function() action, {
    String? invalid,
    required String success,
    required String failure,
  }) async {
    _errorMessage = null;
    _successMessage = null;
    if (invalid != null) {
      _errorMessage = invalid;
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();
    try {
      await action();
      _successMessage = success;
      await load();
      return true;
    } catch (e) {
      _errorMessage = e is HousingFailure ? e.message : failure;
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
