import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Aviso en rojo dentro de un formulario, por ejemplo un error del servidor
/// o un dato que falta.
class FormErrorBanner extends StatelessWidget {
  const FormErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('form.error'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mensaje cuando se intenta enviar un formulario con datos que faltan o no
/// son válidos.
const incompleteFormMessage = 'Revisa los campos marcados en rojo.';

/// Avisa que el formulario tiene datos que faltan o no son válidos. Cada
/// campo ya muestra su error; esto evita que pase desapercibido cuando el
/// campo quedó fuera de la vista.
void showIncompleteFormMessage(
  BuildContext context, [
  String message = incompleteFormMessage,
]) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: AppColors.error,
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}
