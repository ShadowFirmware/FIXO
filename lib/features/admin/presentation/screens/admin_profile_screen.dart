import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/fixo_app_bar.dart';
import '../../../auth/presentation/providers/auth_session.dart';
import '../../../resident/presentation/widgets/profile_header.dart';
import '../providers/admin_profile_view_model.dart';

/// HU-4.1 Consultar perfil del administrador.
class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key, this.viewModel});

  final AdminProfileViewModel? viewModel;

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  late final AdminProfileViewModel _viewModel =
      widget.viewModel ?? AdminProfileViewModel();
  late final bool _ownsViewModel = widget.viewModel == null;

  @override
  void dispose() {
    if (_ownsViewModel) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      extendBodyBehindAppBar: true,
      appBar: const FixoAppBar(title: 'Mi perfil'),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final vm = _viewModel;
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ProfileHeader(
                      initials: vm.initials,
                      name: vm.name,
                      email: vm.email,
                      roleLabel: 'Administrador',
                      roleIcon: Icons.admin_panel_settings_outlined,
                      roleColor: AppColors.primary,
                    ),
                    const SizedBox(height: 32),
                    OutlinedButton.icon(
                      onPressed: () => signOutAndGoToLogin(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(
                          color: AppColors.error.withValues(alpha: 0.5),
                        ),
                      ),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Cerrar sesión'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
