import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/adaptive_form.dart';
import '../../../housing/domain/entities/housing.dart';

import '../providers/housing_admin_view_model.dart';
import '../widgets/admin_page.dart';
import '../widgets/housing_form.dart';

/// Pantalla de gestión de lugares de residencia del administrador (HU-4.7).
class AdminHousingsScreen extends StatefulWidget {
  const AdminHousingsScreen({super.key, this.viewModel});

  final HousingAdminViewModel? viewModel;

  @override
  State<AdminHousingsScreen> createState() => _AdminHousingsScreenState();
}

class _AdminHousingsScreenState extends State<AdminHousingsScreen> {
  late final HousingAdminViewModel _viewModel =
      widget.viewModel ?? HousingAdminViewModel();
  late final bool _ownsViewModel = widget.viewModel == null;

  @override
  void initState() {
    super.initState();
    _viewModel.load();
  }

  @override
  void dispose() {
    if (_ownsViewModel) _viewModel.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// Formulario para registrar una residencia, o para editar [housing].
  Future<void> _showHousingForm({Housing? housing}) async {
    final isEditing = housing != null;
    final saved = await showAdaptiveForm<bool>(
      context: context,
      title: isEditing ? 'Editar residencia' : 'Registrar residencia',
      builder: (_) => HousingForm(
        viewModel: _viewModel,
        housing: housing,
        confirmDiscard: () => _confirm(
          title: 'Descartar cambios',
          message: '¿Deseas descartar los cambios realizados?',
          confirmLabel: 'Descartar',
        ),
      ),
    );

    if (saved == true) {
      _showMessage(
        _viewModel.successMessage ??
            (isEditing ? 'Residencia actualizada' : 'Residencia registrada'),
      );
    }
  }

  Future<void> _viewHousing(Housing housing) {
    final rows = [
      (Icons.home_work_outlined, 'Tipo', housing.type.displayName),
      (
        Icons.apartment_rounded,
        'Edificio o sección',
        housing.building?.trim().isNotEmpty ?? false
            ? housing.building!
            : 'No aplica',
      ),
      (Icons.tag_rounded, 'Número', housing.number),
      (
        Icons.toggle_on_outlined,
        'Estado',
        housing.active ? 'Activa' : 'Inactiva',
      ),
      (Icons.person_outline_rounded, 'Ocupación', _occupancy(housing)),
    ];
    return showAdaptiveForm<void>(
      context: context,
      title: housing.label,
      builder: (context) => AdaptiveFormLayout(
        fields: [
          for (final (icon, label, value) in rows)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(icon, color: AppColors.primary),
              title: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              subtitle: Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _toggleActive(Housing housing) async {
    final activate = !housing.active;
    final confirmed = await _confirm(
      title: activate ? 'Activar residencia' : 'Inactivar residencia',
      message: activate
          ? '¿Activar ${housing.label}? Se podrán registrar incidencias nuevas.'
          : '¿Marcar ${housing.label} como inactiva? Las incidencias abiertas '
                'seguirán su atención, pero no se podrán registrar nuevas.',
    );
    if (!confirmed) return;
    final ok = await _viewModel.setActive(housing, active: activate);
    _showMessage(
      ok
          ? (_viewModel.successMessage ?? 'Estado actualizado')
          : (_viewModel.errorMessage ?? 'Error'),
    );
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    String confirmLabel = 'Confirmar',
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(confirmLabel),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  static String _occupancy(Housing housing) =>
      housing.residentId == null ? 'Disponible' : 'Ocupada';

  void _onOptionSelected(String value, Housing housing) {
    switch (value) {
      case 'view':
        _viewHousing(housing);
      case 'edit':
        _showHousingForm(housing: housing);
      case 'toggle':
        _toggleActive(housing);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      currentRoute: RouteNames.adminHousings,
      title: 'Residencias',
      actions: [
        AdminPageAction(
          icon: Icons.add_home_outlined,
          label: 'Agregar residencia',
          onPressed: _showHousingForm,
        ),
      ],
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading && _viewModel.housings.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_viewModel.housings.isEmpty) {
            return Center(
              child: Text(
                _viewModel.errorMessage ?? 'No hay residencias registradas',
              ),
            );
          }
          final isMobile = MediaQuery.sizeOf(context).width < 600;
          if (isMobile) {
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _viewModel.housings.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final h = _viewModel.housings[index];
                return Card(
                  child: ListTile(
                    title: Text(h.label),
                    subtitle: Text(
                      '${h.type.displayName} · '
                      '${h.active ? "Activa" : "Inactiva"} · ${_occupancy(h)}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) => _onOptionSelected(value, h),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: Text('Ver detalles'),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Editar'),
                        ),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Text(h.active ? 'Inactivar' : 'Activar'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
          // En la web, la tabla ocupa todo el ancho dentro de una tarjeta y se
          // desplaza si las columnas no caben.
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                        ),
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            AppColors.surfaceAlt,
                          ),
                          columns: const [
                            DataColumn(label: Text('Tipo')),
                            DataColumn(label: Text('Edificio / Sección')),
                            DataColumn(label: Text('Número')),
                            DataColumn(label: Text('Estado')),
                            DataColumn(label: Text('Ocupación')),
                            DataColumn(label: Text('Opciones')),
                          ],
                          rows: _viewModel.housings.map((h) {
                            return DataRow(
                              cells: [
                                DataCell(Text(h.type.displayName)),
                                DataCell(Text(h.building ?? '—')),
                                DataCell(Text(h.number)),
                                DataCell(
                                  Text(h.active ? 'Activa' : 'Inactiva'),
                                ),
                                DataCell(Text(_occupancy(h))),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.visibility_outlined,
                                        ),
                                        tooltip: 'Ver',
                                        onPressed: () => _viewHousing(h),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined),
                                        tooltip: 'Editar',
                                        onPressed: () =>
                                            _showHousingForm(housing: h),
                                      ),
                                      if (h.active)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.block_outlined,
                                          ),
                                          tooltip: 'Inactivar',
                                          onPressed: () => _toggleActive(h),
                                        )
                                      else
                                        IconButton(
                                          icon: const Icon(
                                            Icons.check_circle_outline,
                                          ),
                                          tooltip: 'Activar',
                                          onPressed: () => _toggleActive(h),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
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
