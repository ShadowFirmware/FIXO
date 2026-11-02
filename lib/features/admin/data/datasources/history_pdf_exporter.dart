import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../domain/entities/history_incident.dart';
import '../models/history_report.dart';

/// Genera el PDF del historial (HU-4.11) y lo entrega al usuario: en la web
/// se descarga y en el teléfono se abre el menú para compartir o guardar.
class HistoryPdfExporter {
  const HistoryPdfExporter();

  /// Construye el documento con las incidencias en una tabla horizontal.
  Future<Uint8List> build({
    required List<HistoryIncident> records,
    required List<String> filterLines,
    required DateTime generatedAt,
  }) {
    final document = pw.Document(title: HistoryReport.title, author: 'FIXO');
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              HistoryReport.title,
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              HistoryReport.pdfSafe(
                HistoryReport.generatedLine(generatedAt, records.length),
              ),
              style: const pw.TextStyle(fontSize: 9),
            ),
            for (final line in filterLines)
              pw.Text(
                HistoryReport.pdfSafe(line),
                style: const pw.TextStyle(fontSize: 9),
              ),
            pw.SizedBox(height: 8),
          ],
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
        build: (context) => [
          if (records.isEmpty)
            pw.Text('No hay incidencias con los filtros seleccionados.')
          else
            pw.TableHelper.fromTextArray(
              headers: HistoryReport.headers,
              data: [
                for (final row in HistoryReport.rows(records))
                  [for (final cell in row) HistoryReport.pdfSafe(cell)],
              ],
              headerStyle: pw.TextStyle(
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFF0645D5),
              ),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellAlignment: pw.Alignment.topLeft,
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF3F6FC),
              ),
              columnWidths: const {
                0: pw.FixedColumnWidth(48),
                1: pw.FlexColumnWidth(2),
                4: pw.FlexColumnWidth(3),
              },
            ),
        ],
      ),
    );
    return document.save();
  }

  Future<void> share(Uint8List bytes, {required String fileName}) =>
      Printing.sharePdf(bytes: bytes, filename: fileName);
}
