import 'package:flutter/material.dart';

/// Acción de navegación que muestra [PlaceholderView].
class PlaceholderAction {
  const PlaceholderAction(this.label, this.onPressed);

  final String label;
  final VoidCallback onPressed;
}

/// Contenido temporal para pantallas que aún no tienen diseño.
/// Solo muestra el nombre de la pantalla y botones para navegar.
class PlaceholderView extends StatelessWidget {
  const PlaceholderView({
    super.key,
    required this.title,
    this.actions = const [],
  });

  final String title;
  final List<PlaceholderAction> actions;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            for (final action in actions) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: action.onPressed,
                child: Text(action.label),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
