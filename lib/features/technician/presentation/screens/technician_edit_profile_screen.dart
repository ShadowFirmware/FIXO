import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/fixo_app_bar.dart';
import '../../../../shared/widgets/form_error_banner.dart';
import '../../../resident/presentation/providers/edit_profile_view_model.dart';
import '../../../resident/presentation/widgets/profile_form_widgets.dart';

/// HU-3.2 Modificar perfil del técnico.
class TechnicianEditProfileScreen extends StatefulWidget {
  const TechnicianEditProfileScreen({super.key, this.viewModel});

  final EditProfileViewModel? viewModel;

  @override
  State<TechnicianEditProfileScreen> createState() =>
      _TechnicianEditProfileScreenState();
}

class _TechnicianEditProfileScreenState
    extends State<TechnicianEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  late final EditProfileViewModel _viewModel =
      widget.viewModel ?? EditProfileViewModel();

  @override
  void initState() {
    super.initState();
    _nameController.text = _viewModel.initialName;
    _emailController.text = _viewModel.initialEmail;
    _phoneController.text = _viewModel.initialPhone;
    _nameController.addListener(_onEdited);
    _emailController.addListener(_onEdited);
    _phoneController.addListener(_onEdited);
  }

  void _onEdited() => _viewModel.edit(
    name: _nameController.text,
    email: _emailController.text,
    phone: _phoneController.text,
  );

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    if (widget.viewModel == null) _viewModel.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    // Si hay datos inválidos se marcan en el formulario y no se guarda nada.
    if (_viewModel.isSaving) return;
    if (!_formKey.currentState!.validate()) {
      showIncompleteFormMessage(context);
      return;
    }

    final saved = await _viewModel.save();
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    if (!saved) {
      messenger.showSnackBar(SnackBar(content: Text(_viewModel.errorMessage!)));
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(_viewModel.successMessage)));
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
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      extendBodyBehindAppBar: true,
      appBar: const FixoAppBar(title: 'Modificar perfil'),
      // El alto de la barra superior solo se conoce dentro del Scaffold.
      body: Builder(
        builder: (context) {
          final padding = MediaQuery.paddingOf(context);
          return SingleChildScrollView(
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
                            key: const Key('editProfile.email'),
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: Validators.email,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(
                              labelText: 'Correo electrónico',
                              prefixIcon: Icon(Icons.email_outlined),
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
                            autofillHints: const [
                              AutofillHints.telephoneNumber,
                            ],
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
                        title: 'Trabajo',
                        footnote:
                            'Solo un administrador puede cambiar tu '
                            'especialidad.',
                        children: [
                          ProfileReadOnlyField(
                            icon: Icons.handyman_outlined,
                            label: 'Especialidad',
                            value: _viewModel.specialty,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      ListenableBuilder(
                        listenable: _viewModel,
                        builder: (context, _) => ElevatedButton.icon(
                          onPressed:
                              _viewModel.hasChanges && !_viewModel.isSaving
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
                            _viewModel.isSaving
                                ? 'Guardando…'
                                : 'Guardar cambios',
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
          );
        },
      ),
    );
  }
}
