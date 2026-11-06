import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/fixo_app_bar.dart';
import '../providers/edit_profile_view_model.dart';
import '../widgets/profile_form_widgets.dart';

/// HU-2.2 Modificar perfil.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _viewModel = EditProfileViewModel();

  @override
  void initState() {
    super.initState();
    _nameController.text = _viewModel.initialName;
    _phoneController.text = _viewModel.initialPhone;
    _nameController.addListener(_onEdited);
    _phoneController.addListener(_onEdited);
  }

  void _onEdited() =>
      _viewModel.edit(name: _nameController.text, phone: _phoneController.text);

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    // Si hay datos inválidos se marcan en el formulario y no se guarda nada.
    if (_viewModel.isSaving || !_formKey.currentState!.validate()) return;

    final saved = await _viewModel.save();
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    if (!saved) {
      messenger.showSnackBar(SnackBar(content: Text(_viewModel.errorMessage!)));
      return;
    }
    messenger.showSnackBar(
      const SnackBar(content: Text('Tu perfil se actualizó correctamente')),
    );
    Navigator.pop(context);
  }

  /// Oculta el contador de caracteres que agrega `maxLength`.
  static Widget? _hideCounter(
    BuildContext context, {
    required int currentLength,
    required bool isFocused,
    required int? maxLength,
  }) => null;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);

    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      extendBodyBehindAppBar: true,
      appBar: const FixoAppBar(title: 'Modificar perfil'),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          padding.top + 16,
          20,
          padding.bottom + 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProfileFormSection(
                    title: 'Información personal',
                    children: [
                      TextFormField(
                        key: const Key('editProfile.name'),
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        maxLength: EditProfileViewModel.maxNameLength,
                        buildCounter: _hideCounter,
                        validator: Validators.name,
                        autofillHints: const [AutofillHints.name],
                        decoration: const InputDecoration(
                          labelText: 'Nombre completo',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('editProfile.phone'),
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(
                            EditProfileViewModel.phoneLength,
                          ),
                        ],
                        autofillHints: const [AutofillHints.telephoneNumber],
                        onFieldSubmitted: (_) => _submit(),
                        validator: Validators.phone,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ProfileFormSection(
                    title: 'Datos de la cuenta',
                    footnote:
                        'El correo y la vivienda no se pueden modificar desde '
                        'aquí. Solo un administrador puede cambiar tu '
                        'vivienda asignada.',
                    children: [
                      ProfileReadOnlyField(
                        icon: Icons.email_outlined,
                        label: 'Correo electrónico',
                        value: _viewModel.email,
                      ),
                      const SizedBox(height: 16),
                      ListenableBuilder(
                        listenable: _viewModel,
                        builder: (context, _) => ProfileReadOnlyField(
                          icon: Icons.apartment_rounded,
                          label: 'Vivienda asignada',
                          value: _viewModel.housing,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  ListenableBuilder(
                    listenable: _viewModel,
                    builder: (context, _) => ElevatedButton.icon(
                      onPressed: _viewModel.hasChanges && !_viewModel.isSaving
                          ? _submit
                          : null,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      icon: _viewModel.isSaving
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(
                        _viewModel.isSaving ? 'Guardando…' : 'Guardar cambios',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.maybePop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

