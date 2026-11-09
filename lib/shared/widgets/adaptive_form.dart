import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Ancho a partir del cual se usa el diseño de escritorio (web).
const double wideLayoutWidth = 600;

/// `true` si la pantalla es lo bastante ancha para el diseño de escritorio.
bool isWideLayout(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= wideLayoutWidth;

/// Abre un formulario o un detalle adaptado al dispositivo:
///
/// * En el teléfono, como una pantalla completa que entra deslizándose
///   desde abajo, con su barra y el botón para cerrarla.
/// * En pantallas anchas (web), como una ventana centrada.
///
/// [builder] construye el contenido; para cerrar con un resultado usa
/// `Navigator.pop(context, resultado)` en ambos casos.
Future<T?> showAdaptiveForm<T>({
  required BuildContext context,
  required String title,
  required WidgetBuilder builder,
  double maxWidth = 520,
}) {
  if (isWideLayout(context)) {
    return showDialog<T>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: 720),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DialogHeader(title: title),
              const Divider(height: 1),
              Flexible(child: builder(context)),
            ],
          ),
        ),
      ),
    );
  }

  return Navigator.push<T>(
    context,
    PageRouteBuilder<T>(
      fullscreenDialog: true,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, _, _) =>
          _AdaptiveFormPage(title: title, builder: builder),
      transitionsBuilder: (context, animation, _, child) => SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    ),
  );
}

/// Pantalla completa del formulario en el teléfono.
class _AdaptiveFormPage extends StatelessWidget {
  const _AdaptiveFormPage({required this.title, required this.builder});

  final String title;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Cerrar',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(title),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: SafeArea(top: false, child: builder(context)),
    );
  }
}

/// Título y botón para cerrar la ventana en pantallas anchas.
class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            tooltip: 'Cerrar',
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.maybePop(context),
          ),
        ],
      ),
    );
  }
}

/// Contenido de un formulario abierto con [showAdaptiveForm]: los campos se
/// desplazan y los botones quedan fijos abajo.
class AdaptiveFormLayout extends StatelessWidget {
  const AdaptiveFormLayout({super.key, required this.fields, this.footer});

  /// Campos y textos del formulario.
  final List<Widget> fields;

  /// Botones, por ejemplo Cancelar y Guardar.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    // En el teléfono ocupa toda la pantalla y los botones quedan abajo; en
    // la ventana solo mide lo que necesita.
    final fill = !isWideLayout(context);
    return Column(
      mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          fit: fill ? FlexFit.tight : FlexFit.loose,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: fields,
            ),
          ),
        ),
        if (footer case final footer?)
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border(
                top: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: footer,
            ),
          ),
      ],
    );
  }
}
