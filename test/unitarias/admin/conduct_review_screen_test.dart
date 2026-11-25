import 'package:fixo/app/routes/route_names.dart';
import 'package:fixo/core/theme/app_theme.dart';
import 'package:fixo/features/admin/presentation/providers/conduct_review_view_model.dart';
import 'package:fixo/features/admin/presentation/screens/admin_conduct_reports_screen.dart';
import 'package:fixo/features/admin/presentation/widgets/admin_drawer.dart';
import 'package:fixo/features/conduct_reports/domain/entities/conduct_report.dart';
import 'package:fixo/features/incidents/presentation/widgets/evidence_gallery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'conduct_review_fakes.dart';

/// HU-7.3 Revisar y validar reportes de conducta: interfaz.
void main() {
  late FakeConductReviewRepository repository;
  late ConductReviewViewModel viewModel;

  setUp(() {
    repository = FakeConductReviewRepository();
    viewModel = ConductReviewViewModel(
      repository: repository,
      currentUserId: () => 'uid-admin',
    );
  });

  tearDown(() => viewModel.dispose());

  Future<void> pump(
    WidgetTester tester, {
    Size size = const Size(400, 900),
    String? initialReportId,
    bool emit = true,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AdminConductReportsScreen(
          viewModel: viewModel,
          initialReportId: initialReportId,
        ),
      ),
    );
    if (!emit) return tester.pump();
    repository.emit();
    await tester.pumpAndSettle();
  }

  /// Toca un filtro aunque esté fuera de la vista en el teléfono.
  Future<void> tapFilter(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  /// Botón de confirmación del diálogo.
  Finder dialogButton(String label) => find.descendant(
    of: find.byType(AlertDialog),
    matching: find.widgetWithText(ElevatedButton, label),
  );

  Finder card(int folio) => find.byKey(
    Key('conductReport.${sampleReports()[folio - 1].id}'),
  );

  Finder inCard(int folio, Finder matching) =>
      find.descendant(of: card(folio), matching: matching);

  testWidgets('PU-701 se abre desde el menú y lista los reportes con su '
      'información', (tester) async {
    await pump(tester);

    await tester.tap(find.byTooltip('Menú'));
    await tester.pumpAndSettle();
    final menuItem = tester.widget<ListTile>(
      find.byKey(const Key('adminNav.${RouteNames.adminConductReports}')),
    );
    expect(menuItem.selected, isTrue);
    expect(
      find.descendant(
        of: find.byType(AdminDrawer),
        matching: find.text('Reportes de conducta'),
      ),
      findsOneWidget,
    );
    await tester.tapAt(const Offset(390, 450));
    await tester.pumpAndSettle();

    expect(inCard(1, find.text('RC-0001')), findsOneWidget);
    expect(inCard(1, find.text('Pendiente de revisión')), findsOneWidget);
    expect(inCard(1, find.text('Mala actitud')), findsOneWidget);
    expect(
      inCard(1, find.text('Reportó: María López Hernández (Residente)')),
      findsOneWidget,
    );
    expect(
      inCard(1, find.text('Reportado: Juan Pérez Ramírez (Técnico)')),
      findsOneWidget,
    );
    expect(inCard(1, find.text('INC-0007 · Fuga en baño')), findsOneWidget);
    expect(
      inCard(1, find.text('20 de noviembre de 2026, 4:05 p. m.')),
      findsOneWidget,
    );
    expect(inCard(1, find.text('3 evidencias')), findsOneWidget);
    expect(inCard(1, find.text('Validar')), findsOneWidget);
    expect(inCard(1, find.text('Rechazar')), findsOneWidget);

    await tester.scrollUntilVisible(
      card(3),
      200,
      scrollable: find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      ),
    );
    expect(inCard(2, find.text('Validado')), findsOneWidget);
    expect(inCard(2, find.text('Sin evidencias')), findsOneWidget);
    expect(inCard(3, find.text('Rechazado')), findsOneWidget);
    // Los ya revisados no ofrecen Validar ni Rechazar.
    expect(inCard(2, find.text('Validar')), findsNothing);
    expect(inCard(3, find.text('Rechazar')), findsNothing);
  });

  testWidgets('PU-702 filtra por estado con el número de reportes', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Todos (3)'), findsOneWidget);
    expect(find.text('Pendiente de revisión (1)'), findsOneWidget);
    expect(find.text('Validado (1)'), findsOneWidget);
    expect(find.text('Rechazado (1)'), findsOneWidget);

    await tapFilter(tester, 'Rechazado (1)');
    expect(card(3), findsOneWidget);
    expect(card(1), findsNothing);
    expect(card(2), findsNothing);
  });

  testWidgets('PU-703 avisa si no hay reportes o si no se pudieron cargar', (
    tester,
  ) async {
    repository.reports = [sampleReports().first];
    await pump(tester);

    await tapFilter(tester, 'Validado (0)');
    expect(
      find.text('No hay reportes de conducta con estado Validado'),
      findsOneWidget,
    );

    repository.reports = [];
    repository.emit();
    await tester.pumpAndSettle();
    await tapFilter(tester, 'Todos (0)');
    expect(find.text('No hay reportes de conducta registrados'), findsOneWidget);
  });

  testWidgets('PU-704 sin conexión muestra el error al cargar', (tester) async {
    await pump(tester, emit: false);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    repository.controller.addError(
      Exception('sin conexión'),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        'No se pudieron cargar los reportes de conducta. Inténtalo de nuevo.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('PU-705 el detalle muestra todos los datos y las evidencias', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(inCard(1, find.text('Mala actitud')));
    await tester.pumpAndSettle();

    expect(find.text('RC-0001 · Mala actitud'), findsOneWidget);
    for (final (label, value) in [
      ('Identificador', 'RC-0001'),
      ('Reportado por', 'María López Hernández (Residente)'),
      ('Usuario reportado', 'Juan Pérez Ramírez (Técnico)'),
      ('Incidencia relacionada', 'INC-0007 · Fuga en baño'),
      ('Motivo', 'Mala actitud'),
      ('Descripción de lo ocurrido', 'Me habló de forma grosera al terminar.'),
      ('Fecha', '20 de noviembre de 2026, 4:05 p. m.'),
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
      expect(find.text(value), findsWidgets, reason: label);
    }
    await tester.scrollUntilVisible(
      find.byType(EvidenceGallery),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    final gallery = tester.widget<EvidenceGallery>(
      find.byType(EvidenceGallery),
    );
    expect(gallery.urls, hasLength(3));
    expect(EvidenceGallery.isVideo(gallery.urls[1]), isTrue);
    expect(find.byKey(const Key('conductDetail.validate')), findsOneWidget);
    expect(find.byKey(const Key('conductDetail.reject')), findsOneWidget);
  });

  testWidgets('PU-706 valida desde el detalle tras confirmar', (tester) async {
    await pump(tester);

    await tester.tap(inCard(1, find.text('Mala actitud')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('conductDetail.validate')));
    await tester.pumpAndSettle();

    expect(find.text('Validar reporte'), findsOneWidget);
    expect(find.textContaining('contará como antecedente'), findsOneWidget);
    await tester.tap(dialogButton('Validar'));
    await tester.pumpAndSettle();

    expect(repository.reviews.single.decision, ConductReportStatus.validated);
    expect(find.text('Reporte RC-0001 marcado como Validado.'), findsOneWidget);
    expect(inCard(1, find.text('Validado')), findsOneWidget);
    expect(inCard(1, find.text('Validar')), findsNothing);
    expect(find.text('Validado (2)'), findsOneWidget);
  });

  testWidgets('PU-707 rechaza desde la tarjeta; al cancelar no cambia', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(inCard(1, find.text('Rechazar')));
    await tester.pumpAndSettle();
    expect(find.text('Rechazar reporte'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(repository.reviews, isEmpty);
    expect(inCard(1, find.text('Pendiente de revisión')), findsOneWidget);

    await tester.tap(inCard(1, find.text('Rechazar')));
    await tester.pumpAndSettle();
    await tester.tap(dialogButton('Rechazar'));
    await tester.pumpAndSettle();

    expect(repository.reviews.single.decision, ConductReportStatus.rejected);
    expect(find.text('Reporte RC-0001 marcado como Rechazado.'), findsOneWidget);
    expect(inCard(1, find.text('Rechazado')), findsOneWidget);
  });

  testWidgets('PU-708 un reporte revisado muestra quién y cuándo, sin '
      'Validar ni Rechazar', (tester) async {
    await pump(tester);

    await tester.tap(inCard(2, find.text('Insultos')));
    await tester.pumpAndSettle();

    expect(find.text('Fecha de revisión'), findsOneWidget);
    expect(find.text('21 de noviembre de 2026, 10:00 a. m.'), findsOneWidget);
    expect(find.text('Revisado por'), findsOneWidget);
    expect(find.text('Ana Admin'), findsOneWidget);
    expect(find.text('No se adjuntaron evidencias.'), findsOneWidget);
    expect(find.byKey(const Key('conductDetail.validate')), findsNothing);
    expect(find.byKey(const Key('conductDetail.reject')), findsNothing);
    expect(find.text('Cerrar'), findsOneWidget);
  });

  testWidgets('PU-709 en la web muestra la tabla con las columnas y las '
      'opciones', (tester) async {
    await pump(tester, size: const Size(1600, 1000));

    for (final column in [
      'Identificador',
      'Estado',
      'Reportó',
      'Reportado',
      'Incidencia',
      'Motivo',
      'Descripción',
      'Evidencias',
      'Fecha',
      'Opciones',
    ]) {
      expect(find.text(column), findsOneWidget, reason: column);
    }
    expect(find.text('RC-0001'), findsOneWidget);
    expect(find.text('3 (ver)'), findsNWidgets(2));
    expect(find.text('Sin evidencias'), findsOneWidget);
    // Validar y Rechazar solo en el pendiente; los revisados se pueden ver.
    expect(find.widgetWithText(TextButton, 'Validar'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Rechazar'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Ver'), findsNWidgets(2));
  });

  testWidgets('PU-710 al abrirse desde el aviso muestra el detalle del '
      'reporte', (tester) async {
    await pump(tester, initialReportId: 'inc-9_uid-residente');
    expect(find.text('RC-0003 · Retraso'), findsOneWidget);

    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.text('RC-0003 · Retraso'), findsNothing);
  });

  testWidgets('PU-711 si el reporte del aviso ya no existe, se avisa', (
    tester,
  ) async {
    await pump(tester, initialReportId: 'no-existe');

    expect(find.text('El reporte de conducta ya no existe.'), findsOneWidget);
  });
}
