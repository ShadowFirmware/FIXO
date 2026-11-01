import 'package:flutter/material.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/fixo_app_bar.dart';
import '../../../auth/presentation/providers/auth_session.dart';
import '../../../auth/domain/entities/app_user.dart';

import '../providers/technician_admin_view_model.dart';

/// Pantalla de gestión de técnicos del administrador.
class AdminTechniciansScreen extends StatefulWidget {
  const AdminTechniciansScreen({super.key, this.viewModel});

  final TechnicianAdminViewModel? viewModel;

  @override
  State<AdminTechniciansScreen> createState() => _AdminTechniciansScreenState();
}

class _AdminTechniciansScreenState extends State<AdminTechniciansScreen> {
  late final TechnicianAdminViewModel _viewModel =
      widget.viewModel ?? TechnicianAdminViewModel();
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

  Future<void> _showRegistrationDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final specialtyController = TextEditingController();
    final passwordController = TextEditingController();

    final registered = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Registrar técnico'),
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
                      controller: specialtyController,
                      decoration: const InputDecoration(labelText: 'Especialidad'),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Ingresa la especialidad'
                          : null,
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
                          specialty: specialtyController.text,
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
        SnackBar(content: Text(_viewModel.successMessage ?? 'Técnico registrado')),
      );
    } else if (registered == false && _viewModel.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_viewModel.errorMessage!)),
      );
    }
  }

  Future<void> _viewTechnician(AppUser technician) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(technician.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Correo: ${technician.email}'),
            Text('Teléfono: ${technician.phone}'),
            Text('Especialidad: ${technician.specialty ?? "Sin asignar"}'),
            Text('Estado: ${technician.accountStatus.value}'),
            Text('Conducta: ${technician.conductStatus?.value ?? "N/A"}'),
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

  Future<void> _deleteTechnician(AppUser technician) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar técnico'),
        content: Text('¿Eliminar a ${technician.name}?'),
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
    final ok = await _viewModel.delete(technician);
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
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, RouteNames.adminResidents);
              },
            ),
            ListTile(
              leading: const Icon(Icons.build_outlined),
              title: const Text('Técnicos'),
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
        title: 'Técnicos',
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
            tooltip: 'Agregar técnico',
            onPressed: _showRegistrationDialog,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading && _viewModel.technicians.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_viewModel.technicians.isEmpty) {
            return const Center(child: Text('No hay técnicos registrados'));
          }
          final isMobile = MediaQuery.sizeOf(context).width < 600;
          if (isMobile) {
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _viewModel.technicians.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final t = _viewModel.technicians[index];
                return Card(
                  child: ListTile(
                    title: Text(t.name),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'view':
                            _viewTechnician(t);
                            break;
                          case 'edit':
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Edici?n no implementada'),
                              ),
                            );
                            break;
                          case 'delete':
                            _deleteTechnician(t);
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
                DataColumn(label: Text('Especialidad')),
                DataColumn(label: Text('Opciones')),
              ],
              rows: _viewModel.technicians.map((t) {
                return DataRow(cells: [
                  DataCell(Text(t.name)),
                  DataCell(Text(t.email)),
                  DataCell(Text(t.phone)),
                  DataCell(Text(t.specialty ?? '')),
                  DataCell(Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility_outlined),
                        onPressed: () => _viewTechnician(t),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Edici?n no implementada'),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteTechnician(t),
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
