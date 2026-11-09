import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/adaptive_form.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../providers/admin_users_view_model.dart';
import '../widgets/admin_page.dart';
import '../widgets/user_form.dart';
import '../widgets/user_widgets.dart';

/// Sección Usuarios del administrador: residentes y técnicos en una sola
/// lista, con su registro (HU-4.3 y HU-4.4), edición (HU-4.5) y baja
/// (HU-4.6).
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key, this.initialRole, this.viewModel});

  /// Rol filtrado al abrir, por ejemplo desde la ruta anterior de Técnicos.
  final ManagedRole? initialRole;

  /// Solo para pruebas; normalmente la pantalla crea el suyo.
  final AdminUsersViewModel? viewModel;

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  late final _viewModel =
      widget.viewModel ?? AdminUsersViewModel(initialRole: widget.initialRole);

  @override
  void initState() {
    super.initState();
    _viewModel.load();
  }

  @override
  void dispose() {
    if (widget.viewModel == null) _viewModel.dispose();
    super.dispose();
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _register() async {
    final saved = await showAdaptiveForm<bool>(
      context: context,
      title: 'Registrar usuario',
      builder: (_) => UserForm(
        viewModel: _viewModel,
        initialRole: _viewModel.roleFilter ?? ManagedRole.resident,
      ),
    );
    if (saved == true && mounted) _notify(_viewModel.message ?? 'Registrado');
  }

  Future<void> _edit(AppUser user) async {
    final role = ManagedRole.of(user)!;
    final saved = await showAdaptiveForm<bool>(
      context: context,
      title: 'Editar ${role.label.toLowerCase()}',
      builder: (_) => UserForm(viewModel: _viewModel, user: user),
    );
    if (saved == true && mounted) _notify(_viewModel.message ?? 'Guardado');
  }

  Future<void> _view(AppUser user) {
    return showAdaptiveForm<void>(
      context: context,
      title: 'Detalle del usuario',
      builder: (_) => UserDetails(
        user: user,
        housing: _viewModel.housingLabel(user.housingId),
      ),
    );
  }

  /// Da de baja o vuelve a habilitar a [user], después de confirmar.
  Future<void> _toggle(AppUser user) async {
    final active = user.accountStatus == AccountStatus.active;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(active ? 'Dar de baja' : 'Habilitar'),
        content: Text(
          active
              ? '${user.name} ya no podrá iniciar sesión. Podrás habilitarlo '
                    'de nuevo más adelante.'
              : '${user.name} podrá volver a iniciar sesión.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            key: const Key('users.confirmToggle'),
            style: TextButton.styleFrom(
              foregroundColor: active ? AppColors.error : AppColors.primary,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(active ? 'Dar de baja' : 'Habilitar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = active
        ? await _viewModel.remove(user)
        : await _viewModel.enable(user);
    if (mounted) {
      _notify(_viewModel.message ?? (ok ? 'Listo' : 'No se pudo completar.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = isWideLayout(context);
    // En la web, Agregar va en el encabezado; en el teléfono, flotante.
    final sidebar = AdminPage.isWide(context);

    return AdminPage(
      currentRoute: RouteNames.adminUsers,
      title: 'Usuarios',
      subtitle: 'Residentes y técnicos',
      actions: [
        if (sidebar)
          AdminPageAction(
            key: const Key('users.add'),
            icon: Icons.person_add_alt_1_rounded,
            label: 'Agregar usuario',
            onPressed: _register,
          ),
      ],
      floatingActionButton: sidebar
          ? null
          : FloatingActionButton.extended(
              key: const Key('users.add'),
              onPressed: _register,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Agregar'),
            ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Toolbar(viewModel: _viewModel),
                Expanded(child: _content(wide)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(bool wide) {
    final vm = _viewModel;
    if (vm.isLoading && vm.users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.loadError case final error? when vm.users.isEmpty) {
      return _Message(
        icon: Icons.error_outline_rounded,
        text: error,
        action: OutlinedButton.icon(
          onPressed: vm.load,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Reintentar'),
        ),
      );
    }
    if (vm.users.isEmpty) {
      return const _Message(
        icon: Icons.group_outlined,
        text: AdminUsersViewModel.noUsersMessage,
      );
    }
    final results = vm.results;
    if (results.isEmpty) {
      return const _Message(
        icon: Icons.search_off_rounded,
        text: AdminUsersViewModel.noResultsMessage,
      );
    }
    return wide ? _table(results) : _list(results);
  }

  Widget _list(List<AppUser> users) {
    return ListView.separated(
      // Deja espacio para el botón flotante.
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      itemCount: users.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final user = users[index];
        return _UserCard(
          key: ValueKey(user.uid),
          user: user,
          detail: _detailOf(user),
          onTap: () => _view(user),
          menu: _menu(user),
        );
      },
    );
  }

  Widget _table(List<AppUser> users) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Card(
        clipBehavior: Clip.antiAlias,
        // Ocupa todo el ancho y, si las columnas no caben, se desplaza.
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                columnSpacing: 24,
                headingRowColor: WidgetStateProperty.all(AppColors.surfaceAlt),
                columns: const [
                  DataColumn(label: Text('Nombre')),
                  DataColumn(label: Text('Rol')),
                  DataColumn(label: Text('Correo')),
                  DataColumn(label: Text('Teléfono')),
                  DataColumn(label: Text('Vivienda / especialidad')),
                  DataColumn(label: Text('Cuenta')),
                  DataColumn(label: Text('Acciones')),
                ],
                rows: [
                  for (final user in users)
                    DataRow(
                      cells: [
                        DataCell(Text(user.name), onTap: () => _view(user)),
                        DataCell(_roleTag(user)),
                        DataCell(Text(user.email)),
                        DataCell(Text(user.phone)),
                        DataCell(Text(_detailOf(user))),
                        DataCell(_statusTag(user)),
                        DataCell(_menu(user)),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Vivienda del residente o especialidad del técnico.
  String _detailOf(AppUser user) => switch (ManagedRole.of(user)) {
    ManagedRole.resident => _viewModel.housingLabel(user.housingId),
    ManagedRole.technician =>
      user.specialty?.trim().isNotEmpty ?? false
          ? user.specialty!
          : 'Sin especialidad',
    null => '',
  };

  Widget _menu(AppUser user) {
    final active = user.accountStatus == AccountStatus.active;
    return PopupMenuButton<String>(
      key: Key('users.menu.${user.uid}'),
      tooltip: 'Opciones',
      onSelected: (value) => switch (value) {
        'view' => _view(user),
        'edit' => _edit(user),
        _ => _toggle(user),
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'view',
          child: ListTile(
            leading: Icon(Icons.visibility_outlined),
            title: Text('Ver detalles'),
          ),
        ),
        const PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit_outlined),
            title: Text('Editar'),
          ),
        ),
        PopupMenuItem(
          value: 'toggle',
          child: ListTile(
            leading: Icon(
              active ? Icons.block_outlined : Icons.check_circle_outline,
              color: active ? AppColors.error : AppColors.success,
            ),
            title: Text(active ? 'Dar de baja' : 'Habilitar'),
          ),
        ),
      ],
    );
  }
}

Widget _roleTag(AppUser user) {
  final role = ManagedRole.of(user)!;
  return UserTag(label: role.label, icon: role.icon, color: AppColors.primary);
}

Widget _statusTag(AppUser user) =>
    UserTag(label: user.accountStatus.label, color: user.accountStatus.color);

/// Búsqueda y filtro por rol.
class _Toolbar extends StatefulWidget {
  const _Toolbar({required this.viewModel});

  final AdminUsersViewModel viewModel;

  @override
  State<_Toolbar> createState() => _ToolbarState();
}

class _ToolbarState extends State<_Toolbar> {
  late final _search = TextEditingController(text: widget.viewModel.query);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('users.search'),
                  controller: _search,
                  onChanged: vm.setQuery,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre, correo o teléfono',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: vm.query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Borrar búsqueda',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _search.clear();
                              vm.setQuery('');
                            },
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip(null, 'Todos'),
                for (final role in ManagedRole.values) _chip(role, role.plural),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(ManagedRole? role, String label) {
    final vm = widget.viewModel;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        key: Key('users.role.${role?.name ?? 'all'}'),
        label: Text('$label (${vm.countOf(role)})'),
        selected: vm.roleFilter == role,
        onSelected: (_) => vm.setRoleFilter(role),
      ),
    );
  }
}

/// Tarjeta de un usuario en el teléfono.
class _UserCard extends StatelessWidget {
  const _UserCard({
    super.key,
    required this.user,
    required this.detail,
    required this.onTap,
    required this.menu,
  });

  final AppUser user;
  final String detail;
  final VoidCallback onTap;
  final Widget menu;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final role = ManagedRole.of(user)!;

    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  initialsOf(user.name),
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${role.label} · $detail',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [_roleTag(user), _statusTag(user)],
                    ),
                  ],
                ),
              ),
              menu,
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text(
                text,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              if (action != null) ...[const SizedBox(height: 16), action!],
            ],
          ),
        ),
      ),
    );
  }
}
