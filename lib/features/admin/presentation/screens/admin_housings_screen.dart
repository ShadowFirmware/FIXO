import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/fixo_app_bar.dart';
import '../../../housing/domain/entities/housing.dart';

import '../providers/housing_admin_view_model.dart';
import '../widgets/admin_drawer.dart';

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Formulario para registrar una residencia, o para editar [housing].
  Future<void> _showHousingForm({Housing? housing}) async {
    final isEditing = housing != null;
    final formKey = GlobalKey<FormState>();
    final buildingController =
        TextEditingController(text: housing?.building ?? '');
    final numberController = TextEditingController(text: housing?.number ?? '');
    HousingType? selectedType = housing?.type;
    String? dialogError;

    bool hasChanges() =>
        selectedType != housing?.type ||
        buildingController.text.trim() != (housing?.building ?? '').trim() ||
        numberController.text.trim() != (housing?.number ?? '').trim();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Editar residencia' : 'Registrar residencia'),
          content: SizedBox(
            width: 480,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<HousingType>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de residencia',
                      ),
                      items: HousingType.values
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.displayName),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setDialogState(() => selectedType = v),
                      validator: (v) =>
                          v == null ? 'Selecciona el tipo de residencia' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: buildingController,
                      decoration: const InputDecoration(
                        labelText: 'Edificio, torre o sección (opcional)',
                        hintText: 'Ej. Torre A',
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: numberController,
                      decoration: const InputDecoration(
                        labelText: 'Número o identificador',
                        hintText: 'Ej. 4B',
                      ),
                      onChanged: (_) => setDialogState(() {}),
                      validator: (v) =>
                          HousingAdminViewModel.validateNumber(v ?? ''),
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        dialogError!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        if (isEditing && hasChanges()) {
                          final discard = await _confirm(
                            title: 'Descartar cambios',
                            message:
                                '¿Deseas descartar los cambios realizados?',
                            confirmLabel: 'Descartar',
                          );
                          if (!discard) return;
                        }
                        if (context.mounted) Navigator.pop(context, false);
                      },
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ListenableBuilder(
                      listenable: _viewModel,
                      builder: (context, _) => ElevatedButton(
                        onPressed: _viewModel.isLoading
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                if (isEditing && !hasChanges()) {
                                  Navigator.pop(context, false);
                                  return;
                                }
                                final ok = isEditing
                                    ? await _viewModel.update(
                                        housing,
                                        type: selectedType,
                                        number: numberController.text,
                                        building: buildingController.text,
                                      )
                                    : await _viewModel.register(
                                        type: selectedType,
                                        number: numberController.text,
                                        building: buildingController.text,
                                      );
                                if (!context.mounted) return;
                                if (ok) {
                                  Navigator.pop(context, true);
                                } else {
                                  setDialogState(
                                    () => dialogError = _viewModel.errorMessage,
                                  );
                                }
                              },
                        child: Text(isEditing ? 'Guardar' : 'Registrar'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  Future<void> _viewHousing(Housing housing) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(housing.label),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipo: ${housing.type.displayName}'),
            Text('Edificio / sección: ${housing.building ?? "No aplica"}'),
            Text('Número: ${housing.number}'),
            Text('Estado: ${housing.active ? "Activa" : "Inactiva"}'),
            Text('Ocupación: ${_occupancy(housing)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
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
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      drawer: const AdminDrawer(currentRoute: RouteNames.adminHousings),
      appBar: FixoAppBar(
        title: 'Residencias',
        leading: Builder(
          builder: (context) => FixoAppBarAction(
            icon: Icons.menu_rounded,
            tooltip: 'Menú',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          FixoAppBarAction(
            icon: Icons.add_home_outlined,
            tooltip: 'Agregar residencia',
            onPressed: _showHousingForm,
          ),
        ],
      ),
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
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Tipo')),
                DataColumn(label: Text('Edificio / Sección')),
                DataColumn(label: Text('Número')),
                DataColumn(label: Text('Estado')),
                DataColumn(label: Text('Ocupación')),
                DataColumn(label: Text('Opciones')),
              ],
              rows: _viewModel.housings.map((h) {
                return DataRow(cells: [
                  DataCell(Text(h.type.displayName)),
                  DataCell(Text(h.building ?? '—')),
                  DataCell(Text(h.number)),
                  DataCell(Text(h.active ? 'Activa' : 'Inactiva')),
                  DataCell(Text(_occupancy(h))),
                  DataCell(Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility_outlined),
                        tooltip: 'Ver',
                        onPressed: () => _viewHousing(h),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Editar',
                        onPressed: () => _showHousingForm(housing: h),
                      ),
                      if (h.active)
                        IconButton(
                          icon: const Icon(Icons.block_outlined),
                          tooltip: 'Inactivar',
                          onPressed: () => _toggleActive(h),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.check_circle_outline),
                          tooltip: 'Activar',
                          onPressed: () => _toggleActive(h),
                        ),
                    ],
                  )),
                ]);
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
