import 'package:flutter/material.dart';

import '../../../../shared/widgets/adaptive_form.dart';
import '../../../../shared/widgets/form_error_banner.dart';
import '../../../housing/domain/entities/housing.dart';
import '../providers/housing_admin_view_model.dart';

/// Formulario para registrar una residencia o editar [housing] (HU-4.7).
/// Se abre con `showAdaptiveForm` y se cierra con `true` si se guardó.
class HousingForm extends StatefulWidget {
  const HousingForm({
    super.key,
    required this.viewModel,
    required this.confirmDiscard,
    this.housing,
  });

  final HousingAdminViewModel viewModel;
  final Housing? housing;

  /// Pregunta si se descartan los cambios al cancelar una edición.
  final Future<bool> Function() confirmDiscard;

  @override
  State<HousingForm> createState() => _HousingFormState();
}

class _HousingFormState extends State<HousingForm> {
  final _formKey = GlobalKey<FormState>();
  late final Housing? _housing = widget.housing;
  late HousingType? _type = _housing?.type;
  late final _building = TextEditingController(text: _housing?.building);
  late final _number = TextEditingController(text: _housing?.number);
  bool _saving = false;

  /// Error del servidor, por ejemplo una residencia repetida.
  String? _error;

  bool get _isEditing => _housing != null;

  bool get _hasChanges =>
      _type != _housing?.type ||
      _building.text.trim() != (_housing?.building ?? '').trim() ||
      _number.text.trim() != (_housing?.number ?? '').trim();

  @override
  void dispose() {
    _building.dispose();
    _number.dispose();
    super.dispose();
  }

  Future<void> _cancel() async {
    if (_isEditing && _hasChanges && !await widget.confirmDiscard()) return;
    if (mounted) Navigator.pop(context, false);
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) {
      setState(() => _error = 'Revisa los campos marcados en rojo.');
      return;
    }
    if (_isEditing && !_hasChanges) {
      Navigator.pop(context, false);
      return;
    }

    setState(() => _saving = true);
    final vm = widget.viewModel;
    final ok = _isEditing
        ? await vm.update(
            _housing!,
            type: _type,
            number: _number.text,
            building: _building.text,
          )
        : await vm.register(
            type: _type,
            number: _number.text,
            building: _building.text,
          );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _saving = false;
        _error = vm.errorMessage ?? 'No se pudo guardar. Inténtalo de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: AdaptiveFormLayout(
        fields: [
          if (_error case final error?) ...[
            FormErrorBanner(message: error),
            const SizedBox(height: 16),
          ],
          DropdownButtonFormField<HousingType>(
            key: const Key('housingForm.type'),
            initialValue: _type,
            decoration: const InputDecoration(
              labelText: 'Tipo de residencia',
              prefixIcon: Icon(Icons.home_work_outlined),
            ),
            items: [
              for (final type in HousingType.values)
                DropdownMenuItem(value: type, child: Text(type.displayName)),
            ],
            onChanged: _saving ? null : (v) => setState(() => _type = v),
            validator: (v) =>
                v == null ? 'Selecciona el tipo de residencia' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('housingForm.building'),
            controller: _building,
            enabled: !_saving,
            textCapitalization: TextCapitalization.words,
            validator: (v) => (v?.trim().length ?? 0) > 40
                ? 'El edificio no debe pasar de 40 caracteres'
                : null,
            decoration: const InputDecoration(
              labelText: 'Edificio, torre o sección (opcional)',
              hintText: 'Ej. Torre A',
              prefixIcon: Icon(Icons.apartment_rounded),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('housingForm.number'),
            controller: _number,
            enabled: !_saving,
            textCapitalization: TextCapitalization.characters,
            validator: (v) => HousingAdminViewModel.validateNumber(v ?? ''),
            decoration: const InputDecoration(
              labelText: 'Número o identificador',
              hintText: 'Ej. 4B',
              prefixIcon: Icon(Icons.tag_rounded),
            ),
          ),
        ],
        footer: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : _cancel,
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                key: const Key('housingForm.save'),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Text(_isEditing ? 'Guardar' : 'Registrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
