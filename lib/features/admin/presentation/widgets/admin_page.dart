import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/fixo_app_bar.dart';
import 'admin_drawer.dart';

/// Ancho a partir del cual el panel del administrador se ve como una
/// aplicación web: barra lateral fija y encabezado sencillo.
const double adminSidebarWidth = 1000;

/// Acción del encabezado, por ejemplo Agregar o Exportar.
class AdminPageAction {
  const AdminPageAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Key? key;
}

/// Estructura de las pantallas del administrador.
///
/// * En el teléfono: barra superior de FIXO y menú de hamburguesa.
/// * En pantallas anchas (web): barra lateral con las secciones siempre
///   visible, y un encabezado con el título y las acciones como botones.
class AdminPage extends StatelessWidget {
  const AdminPage({
    super.key,
    required this.currentRoute,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions = const [],
    this.floatingActionButton,
    this.extendBodyBehindAppBar = false,
  });

  final String currentRoute;
  final String title;
  final String? subtitle;
  final List<AdminPageAction> actions;
  final Widget body;

  /// Solo se muestra en el teléfono; en la web las acciones van en el
  /// encabezado.
  final Widget? floatingActionButton;

  /// En el teléfono, el contenido pasa por detrás de la barra superior.
  final bool extendBodyBehindAppBar;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= adminSidebarWidth;

  @override
  Widget build(BuildContext context) {
    if (isWide(context)) return _web(context);

    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      drawer: AdminDrawer(currentRoute: currentRoute),
      appBar: FixoAppBar(
        title: title,
        subtitle: subtitle,
        leading: Builder(
          builder: (context) => FixoAppBarAction(
            icon: Icons.menu_rounded,
            tooltip: 'Menú',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          for (final action in actions)
            FixoAppBarAction(
              key: action.key,
              icon: action.icon,
              tooltip: action.label,
              onPressed: action.onPressed,
            ),
        ],
      ),
      floatingActionButton: floatingActionButton,
      body: body,
    );
  }

  Widget _web(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: AppColors.white,
            child: SizedBox(
              width: 272,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Brand(),
                    const Divider(height: 1),
                    Expanded(
                      child: AdminNavigationPanel(currentRoute: currentRoute),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  color: AppColors.white,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(32, 20, 32, 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: textTheme.headlineSmall?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (subtitle != null)
                                Text(
                                  subtitle!,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        for (final action in actions) ...[
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            key: action.key,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 44),
                            ),
                            onPressed: action.onPressed,
                            icon: Icon(action.icon),
                            label: Text(action.label),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                // Sin barra superior flotante, el contenido no necesita
                // margen extra arriba.
                Expanded(
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: body,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Logotipo del panel en la barra lateral.
class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.navy, AppColors.primary],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.handyman_rounded,
              color: AppColors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FIXO',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Administración',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
