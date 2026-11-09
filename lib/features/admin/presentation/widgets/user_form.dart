import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/form_error_banner.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../housing/domain/entities/housing.dart';
import '../providers/admin_users_view_model.dart';

/// Formulario para registrar o editar un residente o un técnico (HU-4.3,
/// HU-4.4 y HU-4.5). Al registrar se elige el rol y el formulario se adapta:
/// el residente necesita una vivienda y el técnico una especialidad.
///
/// Se abre con `showAdaptiveForm` y se cierra con `true` si se guardó.
class UserForm extends StatefulWidget {
  const UserForm({
    super.key,
    required this.viewModel,
    this.user,
    this.initialRole = ManagedRole.resident,
  });

  final AdminUsersViewModel viewModel;

  /// Usuario que se edita, o `null` para registrar uno nuevo.
  final AppUser? user;

  /// Rol seleccionado al abrir el registro.
  final ManagedRole initialRole;

  @override
  State<UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  final _formKey = GlobalKey<FormState>();
  late final AppUser? _user = widget.user;
  late ManagedRole _role = _user == null
      ? widget.initialRole
      : ManagedRole.of(_user)!;

  late final _name = TextEditingController(text: _user?.name);
  late final _email = TextEditingController(text: _user?.email);
  late final _phone = TextEditingController(text: _user?.phone);
  late final _password = TextEditingController();
  late final _specialty = TextEditingController(text: _user?.specialty);
  late String? _housingId = _user?.housingId;

  bool _saving = false;
  bool _showPassword = false;

  /// Error del servidor, por ejemplo "El correo ya está registrado".
  String? _error;

  bool get _isNew => _user == null;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _specialty.dispose();
    super.dispose();
  }

  List<Housing> get _housingOptions => _isNew
      ? widget.viewModel.availableHousings
      : widget.viewModel.housingOptionsFor(_user!);

  bool get _hasChanges {
    final user = _user;
    if (user == null) return true;
    return _name.text.trim() != user.name.trim() ||
        _email.text.trim().toLowerCase() != user.email.trim().toLowerCase() ||
        _phone.text.trim() != user.phone.trim() ||
        (_role == ManagedRole.resident && _housingId != user.housingId) ||
        (_role == ManagedRole.technician &&
            _specialty.text.trim() != (user.specialty ?? '').trim());
  }

  /// Pregunta con [title] y [message]; devuelve `true` si se confirma.
  Future<bool> _confirm(String title, String message, String action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            key: const Key('userForm.confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  /// Al editar, si hay cambios se pide confirmar antes de descartarlos
  /// (HU-4.5).
  Future<void> _cancel() async {
    if (!_isNew &&
        _hasChanges &&
        !await _confirm(
          'Descartar cambios',
          '¿Deseas descartar los cambios realizados?',
          'Descartar',
        )) {
      return;
    }
    if (mounted) Navigator.pop(context, false);
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) {
      setState(() => _error = 'Revisa los campos marcados en rojo.');
      return;
    }
    if (!_isNew && !_hasChanges) {
      Navigator.pop(context, false);
      return;
    }
    // Al editar se confirma antes de guardar (HU-4.5).
    if (!_isNew &&
        !await _confirm(
          'Guardar cambios',
          '¿Deseas guardar los cambios realizados?',
          'Guardar',
        )) {
      return;
    }
    if (!mounted) return;

    setState(() => _saving = true);
    final vm = widget.viewModel;
    final ok = _isNew
        ? await vm.register(
            role: _role,
            name: _name.text.trim(),
            email: _email.text.trim(),
            phone: _phone.text.trim(),
            password: _password.text,
            housingId: _housingId ?? '',
            specialty: _specialty.text.trim(),
          )
        : await vm.update(
            _user!,
            name: _name.text.trim(),
            email: _email.text.trim(),
            phone: _phone.text.trim(),
            housingId: _housingId ?? '',
            specialty: _specialty.text.trim(),
          );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _saving = false;
        _error = vm.message ?? 'No se pudo guardar. Inténtalo de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_error case final error?) ...[
                  FormErrorBanner(message: error),
                  const SizedBox(height: 16),
                ],
                if (_isNew) ...[
                  Text(
                    'Tipo de usuario',
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<ManagedRole>(
                    key: const Key('userForm.role'),
                    segments: const [
                      ButtonSegment(
                        value: ManagedRole.resident,
                        icon: Icon(Icons.home_outlined),
                        label: Text('Residente'),
                      ),
                      ButtonSegment(
                        value: ManagedRole.technician,
                        icon: Icon(Icons.build_outlined),
                        label: Text('Técnico'),
                      ),
                    ],
                    selected: {_role},
                    onSelectionChanged: _saving
                        ? null
                        : (roles) => setState(() => _role = roles.first),
                  ),
                  const SizedBox(height: 20),
                ],
                TextFormField(
                  key: const Key('userForm.name'),
                  controller: _name,
                  enabled: !_saving,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: Validators.name,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('userForm.email'),
                  controller: _email,
                  enabled: !_saving,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('userForm.phone'),
                  controller: _phone,
                  enabled: !_saving,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: Validators.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    hintText: '10 dígitos',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                if (_isNew) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('userForm.password'),
                    controller: _password,
                    enabled: !_saving,
                    obscureText: !_showPassword,
                    validator: Validators.newPassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      helperText: 'Mínimo 8 caracteres',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        tooltip: _showPassword
                            ? 'Ocultar contraseña'
                            : 'Mostrar contraseña',
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                ..._roleFields(),
              ],
            ),
          ),
          _actions(),
        ],
      ),
    );
  }

  /// Campos que solo pide el rol seleccionado.
  List<Widget> _roleFields() {
    switch (_role) {
      case ManagedRole.resident:
        final options = _housingOptions;
        return [
          DropdownButtonFormField<String>(
            key: const Key('userForm.housing'),
            initialValue: options.any((h) => h.id == _housingId)
                ? _housingId
                : null,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Vivienda',
              prefixIcon: Icon(Icons.apartment_rounded),
            ),
            items: [
              for (final housing in options)
                DropdownMenuItem(
                  value: housing.id,
                  child: Text(
                    housing.active
                        ? housing.label
                        : '${housing.label} (inactiva)',
                  ),
                ),
            ],
            onChanged: _saving
                ? null
                : (value) => setState(() => _housingId = value),
            validator: (value) =>
                value == null ? 'Selecciona una vivienda' : null,
          ),
          if (options.isEmpty) ...[
            const SizedBox(height: 8),
            const FormErrorBanner(
              message:
                  'No hay viviendas disponibles. Registra o libera una '
                  'vivienda en Residencias para asignarla.',
            ),
          ],
        ];
      case ManagedRole.technician:
        return [
          TextFormField(
            key: const Key('userForm.specialty'),
            controller: _specialty,
            enabled: !_saving,
            textCapitalization: TextCapitalization.sentences,
            validator: Validators.specialty,
            decoration: const InputDecoration(
              labelText: 'Especialidad',
              hintText: 'Ej. Electricidad',
              prefixIcon: Icon(Icons.handyman_outlined),
            ),
          ),
        ];
    }
  }

  Widget _actions() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : _cancel,
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                key: const Key('userForm.save'),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Text(_isNew ? 'Registrar' : 'Guardar cambios'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
