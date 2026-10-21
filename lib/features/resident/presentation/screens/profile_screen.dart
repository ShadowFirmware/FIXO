import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/fixo_app_bar.dart';
import '../../../auth/presentation/providers/auth_session.dart';
import '../providers/profile_view_model.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_info_section.dart';

/// HU-2.1 Consultar perfil.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _viewModel = ProfileViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      // El contenido pasa por detrás de la barra superior para aprovechar
      // toda la pantalla cuando las barras se ocultan al hacer scroll.
      extendBodyBehindAppBar: true,
      appBar: const FixoAppBar(title: 'Mi perfil'),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final vm = _viewModel;
          // El padding del MediaQuery ya incluye el alto de ambas barras.
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
                    ),
                    const SizedBox(height: 28),
                    ProfileInfoSection(
                      title: 'Información personal',
                      tiles: [
                        ProfileInfoTile(
                          icon: Icons.person_outline_rounded,
                          label: 'Nombre completo',
                          value: vm.name,
                        ),
                        ProfileInfoTile(
                          icon: Icons.email_outlined,
                          label: 'Correo electrónico',
                          value: vm.email,
                        ),
                        ProfileInfoTile(
                          icon: Icons.phone_outlined,
                          label: 'Teléfono',
                          value: vm.phone,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ProfileInfoSection(
                      title: 'Vivienda',
                      footnote:
                          'Solo un administrador puede cambiar tu vivienda '
                          'asignada.',
                      tiles: [
                        ProfileInfoTile(
                          icon: Icons.apartment_rounded,
                          label: 'Vivienda asignada',
                          value: vm.housing,
                          readOnly: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ProfileInfoSection(
                      title: 'Cuenta',
                      tiles: [
                        ProfileInfoTile(
                          icon: Icons.verified_user_outlined,
                          label: 'Estado de la cuenta',
                          value: vm.accountStatus,
                          trailing: _StatusDot(active: vm.isAccountActive),
                        ),
                        ProfileInfoTile(
                          icon: Icons.calendar_today_outlined,
                          label: 'Miembro desde',
                          value: vm.memberSince,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, RouteNames.editProfile),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Modificar perfil'),
                    ),
                    const SizedBox(height: 12),
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

/// Punto de color que acompaña al estado de la cuenta.
class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.success : AppColors.error,
      ),
    );
  }
}
