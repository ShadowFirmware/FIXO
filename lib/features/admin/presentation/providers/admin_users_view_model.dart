import 'package:flutter/foundation.dart';

import '../../../auth/domain/entities/app_user.dart';
import '../../../housing/domain/entities/housing.dart';
import 'resident_admin_view_model.dart';
import 'technician_admin_view_model.dart';

/// Rol que se puede registrar desde la sección Usuarios.
enum ManagedRole {
  resident('Residente', 'Residentes'),
  technician('Técnico', 'Técnicos');

  const ManagedRole(this.label, this.plural);

  final String label;
  final String plural;

  static ManagedRole? of(AppUser user) => switch (user.role) {
    UserRole.resident => resident,
    UserRole.technician => technician,
    UserRole.admin => null,
  };
}

/// ViewModel de la sección Usuarios del administrador: reúne la gestión de
/// residentes (HU-4.3, 4.5, 4.6) y de técnicos (HU-4.4, 4.5, 4.6) en una
/// sola lista. Cada acción se delega al ViewModel del rol que corresponde.
class AdminUsersViewModel extends ChangeNotifier {
  AdminUsersViewModel({
    ResidentAdminViewModel? residents,
    TechnicianAdminViewModel? technicians,
    ManagedRole? initialRole,
  }) : _residents = residents ?? ResidentAdminViewModel(),
       _technicians = technicians ?? TechnicianAdminViewModel(),
       _roleFilter = initialRole {
    _residents.addListener(notifyListeners);
    _technicians.addListener(notifyListeners);
  }

  final ResidentAdminViewModel _residents;
  final TechnicianAdminViewModel _technicians;

  Future<void> load() => Future.wait([_residents.load(), _technicians.load()]);

  bool get isLoading => _residents.isLoading || _technicians.isLoading;

  /// Error al cargar, si alguna de las dos listas falló.
  String? get loadError =>
      (_residents.residents.isEmpty ? _residents.errorMessage : null) ??
      (_technicians.technicians.isEmpty ? _technicians.errorMessage : null);

  /// Residentes y técnicos, ordenados por nombre.
  List<AppUser> get users =>
      [..._residents.residents, ..._technicians.technicians]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  ManagedRole? _roleFilter;

  /// Rol seleccionado en el filtro, o `null` para todos.
  ManagedRole? get roleFilter => _roleFilter;

  void setRoleFilter(ManagedRole? role) {
    if (role == _roleFilter) return;
    _roleFilter = role;
    notifyListeners();
  }

  String _query = '';
  String get query => _query;

  void setQuery(String query) {
    if (query == _query) return;
    _query = query;
    notifyListeners();
  }

  int countOf(ManagedRole? role) => role == null
      ? users.length
      : users.where((user) => ManagedRole.of(user) == role).length;

  /// Usuarios que cumplen el filtro de rol y la búsqueda por nombre,
  /// correo o teléfono.
  List<AppUser> get results {
    final text = _query.trim().toLowerCase();
    return [
      for (final user in users)
        if ((_roleFilter == null || ManagedRole.of(user) == _roleFilter) &&
            (text.isEmpty ||
                user.name.toLowerCase().contains(text) ||
                user.email.toLowerCase().contains(text) ||
                user.phone.contains(text)))
          user,
    ];
  }

  static const noUsersMessage =
      'Aún no hay residentes ni técnicos registrados.';
  static const noResultsMessage =
      'No hay usuarios que coincidan con la búsqueda.';

  /// Viviendas activas y libres, para registrar a un residente.
  List<Housing> get availableHousings => _residents.availableHousings;

  /// Viviendas que puede tener [resident] al editarlo: la suya, aunque
  /// esté inactiva, y las activas libres.
  List<Housing> housingOptionsFor(AppUser resident) => [
    for (final housing in _residents.housings)
      if (housing.id == resident.housingId ||
          (housing.active &&
              (housing.residentId == null ||
                  housing.residentId == resident.uid)))
        housing,
  ];

  String housingLabel(String? housingId) => _residents.housingLabel(housingId);

  /// Mensaje del último registro, edición, baja o habilitación.
  String? _message;
  String? get message => _message;

  Future<bool> register({
    required ManagedRole role,
    required String name,
    required String email,
    required String phone,
    required String password,
    String housingId = '',
    String specialty = '',
  }) {
    return _run(
      role,
      () => switch (role) {
        ManagedRole.resident => _residents.register(
          name: name,
          email: email,
          phone: phone,
          password: password,
          housingId: housingId,
        ),
        ManagedRole.technician => _technicians.register(
          name: name,
          email: email,
          phone: phone,
          password: password,
          specialty: specialty,
        ),
      },
    );
  }

  Future<bool> update(
    AppUser user, {
    required String name,
    required String email,
    required String phone,
    String housingId = '',
    String specialty = '',
  }) {
    final role = ManagedRole.of(user)!;
    final emailChanged =
        email.trim().toLowerCase() != user.email.trim().toLowerCase();
    return _run(
      role,
      // La app no puede cambiar el correo de acceso de otra persona: queda
      // pendiente hasta que el usuario abra el enlace (HU-4.5).
      note: emailChanged
          ? 'El correo cambiará a ${email.trim().toLowerCase()} cuando '
                '${user.name} inicie sesión y abra el enlace que le '
                'enviaremos. Mientras tanto, sigue entrando con su correo '
                'actual.'
          : null,
      () => switch (role) {
        ManagedRole.resident => _residents.update(
          user,
          name: name,
          email: email,
          phone: phone,
          housingId: housingId,
        ),
        ManagedRole.technician => _technicians.update(
          user,
          name: name,
          email: email,
          phone: phone,
          specialty: specialty,
        ),
      },
    );
  }

  /// Da de baja (inhabilita) a [user] (HU-4.6).
  Future<bool> remove(AppUser user) {
    final role = ManagedRole.of(user)!;
    return _run(
      role,
      () => switch (role) {
        ManagedRole.resident => _residents.remove(user),
        ManagedRole.technician => _technicians.remove(user),
      },
    );
  }

  /// Vuelve a habilitar a [user].
  Future<bool> enable(AppUser user) {
    final role = ManagedRole.of(user)!;
    return _run(
      role,
      () => switch (role) {
        ManagedRole.resident => _residents.enable(user),
        ManagedRole.technician => _technicians.enable(user),
      },
    );
  }

  /// Ejecuta [action] y guarda su mensaje. Si salió bien, agrega [note].
  Future<bool> _run(
    ManagedRole role,
    Future<bool> Function() action, {
    String? note,
  }) async {
    final ok = await action();
    final message = switch (role) {
      ManagedRole.resident =>
        ok ? _residents.successMessage : _residents.errorMessage,
      ManagedRole.technician =>
        ok ? _technicians.successMessage : _technicians.errorMessage,
    };
    _message = ok && note != null ? '$message $note' : message;
    notifyListeners();
    return ok;
  }

  @override
  void dispose() {
    _residents
      ..removeListener(notifyListeners)
      ..dispose();
    _technicians
      ..removeListener(notifyListeners)
      ..dispose();
    super.dispose();
  }
}
