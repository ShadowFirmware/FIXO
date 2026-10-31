import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/fixo_app_bar.dart';
import '../../../auth/presentation/providers/auth_session.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../housing/domain/entities/housing.dart';

import '../providers/resident_admin_view_model.dart';

/// Pantalla de gestión de residentes del administrador.
class AdminResidentsScreen extends StatefulWidget {
  const AdminResidentsScreen({super.key});

  @override
  State<AdminResidentsScreen> createState() => _AdminResidentsScreenState();
}

class _AdminResidentsScreenState extends State<AdminResidentsScreen> {
  late final ResidentAdminViewModel _viewModel = ResidentAdminViewModel();
  late final bool _ownsViewModel = true;

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

  Future<void> _showRegistrationDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    String? selectedHousingId;

    final registered = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Registrar residente'),
          content: SizedBox(
            width: 480,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nombre completo'),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Ingresa el nombre'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Correo electrónico'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v == null || !v.contains('@')
                          ? 'Correo no válido'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: 'Teléfono'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordController,
                      decoration:
                          const InputDecoration(labelText: 'Contraseña'),
                      obscureText: true,
                      validator: (v) => v == null || v.length < 8
                          ? 'Mínimo 8 caracteres'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedHousingId,
                      decoration:
                          const InputDecoration(labelText: 'Vivienda'),
                      items: _viewModel.availableHousings
                          .map(
                            (Housing h) => DropdownMenuItem(
                              value: h.id,
                              child: Text(h.label),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setDialogState(() => selectedHousingId = v),
                      validator: (v) =>
                          v == null ? 'Selecciona una vivienda' : null,
                    ),
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
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final ok = await _viewModel.register(
                          name: nameController.text,
                          email: emailController.text,
                          phone: phoneController.text,
                          password: passwordController.text,
                          housingId: selectedHousingId ?? '',
                        );
                        if (ok && context.mounted) Navigator.pop(context, true);
                      },
                      child: const Text('Registrar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (registered == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_viewModel.successMessage ?? 'Residente registrado')),
      );
    } else if (registered == false && _viewModel.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_viewModel.errorMessage!)),
      );
    }
  }

  Future<void> _viewResident(AppUser resident) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(resident.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Correo: ${resident.email}'),
            Text('Teléfono: ${resident.phone}'),
            Text('Vivienda: ${resident.housingId ?? "Sin asignar"}'),
            Text('Estado: ${resident.accountStatus.value}'),
            Text('Conducta: ${resident.conductStatus?.value ?? "N/A"}'),
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

  Future<void> _deleteResident(AppUser resident) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar residente'),
        content: Text('¿Eliminar a ${resident.name}?'),
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
                    child: const Text('Eliminar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await _viewModel.delete(resident);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (_viewModel.successMessage ?? 'Eliminado')
              : (_viewModel.errorMessage ?? 'Error'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(child: Text('Administrador')),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Inicio'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, RouteNames.adminHome);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('Residentes'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Ver perfil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, RouteNames.adminProfile);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.error),
              title: const Text('Cerrar sesión'),
              onTap: () {
                Navigator.pop(context);
                signOutAndGoToLogin(context);
              },
            ),
          ],
        ),
      ),
      appBar: FixoAppBar(
        title: 'Residentes',
        leading: Builder(
          builder: (context) => FixoAppBarAction(
            icon: Icons.menu_rounded,
            tooltip: 'Menú',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          FixoAppBarAction(
            icon: Icons.person_add_alt_1_rounded,
            tooltip: 'Agregar residente',
            onPressed: _showRegistrationDialog,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading && _viewModel.residents.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_viewModel.residents.isEmpty) {
            return const Center(child: Text('No hay residentes registrados'));
          }
          final isMobile = MediaQuery.sizeOf(context).width < 600;
          if (isMobile) {
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _viewModel.residents.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final r = _viewModel.residents[index];
                return Card(
                  child: ListTile(
                    title: Text(r.name),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'view':
                            _viewResident(r);
                            break;
                          case 'edit':
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Edición no implementada'),
                              ),
                            );
                            break;
                          case 'delete':
                            _deleteResident(r);
                            break;
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'view',
                          child: Text('Ver detalles'),
                        ),
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Editar'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Eliminar'),
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
                DataColumn(label: Text('Nombre')),
                DataColumn(label: Text('Correo')),
                DataColumn(label: Text('Teléfono')),
                DataColumn(label: Text('Vivienda')),
                DataColumn(label: Text('Opciones')),
              ],
              rows: _viewModel.residents.map((r) {
                return DataRow(cells: [
                  DataCell(Text(r.name)),
                  DataCell(Text(r.email)),
                  DataCell(Text(r.phone)),
                  DataCell(Text(r.housingId ?? '')),
                  DataCell(Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility_outlined),
                        onPressed: () => _viewResident(r),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Edición no implementada'),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteResident(r),
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