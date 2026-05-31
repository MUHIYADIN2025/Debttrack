// lib/utils/pdf_generator.dart
// Generates PDF reports on the Flutter client using the `pdf` package
// Usage: final bytes = await PdfGenerator.customerReport(data);
//        await Printing.sharePdf(bytes: bytes, filename: 'report.pdf');

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/models.dart';

final _numFmt = NumberFormat('#,##0', 'en_US');
String _fmt(double n) => '${_numFmt.format(n.round())} SOS';

class PdfGenerator {
  PdfGenerator._();

  // ── Customer Debt Report ────────────────────────────────────
  static Future<Uint8List> customerReport(
    List<Map<String, dynamic>> report,
    String merchantName,
  ) async {
    final doc  = pw.Document();
    final font = await PdfGoogleFonts.dmSansRegular();
    final bold = await PdfGoogleFonts.dmSansBold();

    final primaryColor = PdfColor.fromHex('4F8EF7');
    final successColor = PdfColor.fromHex('22C55E');
    final dangerColor  = PdfColor.fromHex('EF4444');
    final darkColor    = PdfColor.fromHex('1E2230');
    final grayColor    = PdfColor.fromHex('6B7280');

    final totalDebt      = report.fold<double>(0, (s, r) => s + (r['totalDebt'] as num).toDouble());
    final totalPaid      = report.fold<double>(0, (s, r) => s + (r['totalPaid'] as num).toDouble());
    final totalRemaining = totalDebt - totalPaid;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => pw.Container(
          color: darkColor,
          padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('DebtTrack', style: pw.TextStyle(font: bold, fontSize: 20, color: PdfColors.white)),
                pw.Text('Customer Debt Report', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey300)),
              ]),
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text(merchantName, style: pw.TextStyle(font: bold, fontSize: 11, color: PdfColors.white)),
                pw.Text(DateFormat('dd MMM yyyy').format(DateTime.now()),
                  style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey300)),
              ]),
            ],
          ),
        ),
        build: (ctx) => [
          pw.SizedBox(height: 16),
          // Summary stats
          pw.Row(children: [
            _statBox('Total Debt',      _fmt(totalDebt),      dangerColor,  font, bold),
            pw.SizedBox(width: 8),
            _statBox('Total Collected', _fmt(totalPaid),      successColor, font, bold),
            pw.SizedBox(width: 8),
            _statBox('Total Remaining', _fmt(totalRemaining), PdfColor.fromHex('F59E0B'), font, bold),
          ]),
          pw.SizedBox(height: 20),
          // Table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(2.5),
              1: const pw.FlexColumnWidth(1.8),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FlexColumnWidth(2),
              5: const pw.FlexColumnWidth(1),
            },
            children: [
              // Header row
              pw.TableRow(
                decoration: pw.BoxDecoration(color: darkColor),
                children: ['Customer', 'Phone', 'Total Debt', 'Paid', 'Balance', '%'].map((h) =>
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: pw.Text(h, style: pw.TextStyle(font: bold, fontSize: 9, color: PdfColors.white)),
                  ),
                ).toList(),
              ),
              // Data rows
              ...report.asMap().entries.map((e) {
                final i   = e.key;
                final r   = e.value;
                final c   = r['customer'] as Map;
                final pct = (r['collectionPct'] as num).toInt();
                final bg  = i.isEven ? PdfColors.white : PdfColors.grey100;

                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: bg),
                  children: [
                    _cell(c['name'] ?? '', font),
                    _cell(c['phone'] ?? '—', font),
                    _cell(_fmt((r['totalDebt'] as num).toDouble()), font, color: dangerColor),
                    _cell(_fmt((r['totalPaid'] as num).toDouble()), font, color: successColor),
                    _cell(_fmt((r['balance'] as num).toDouble()), font,
                      color: (r['balance'] as num) > 0 ? dangerColor : successColor),
                    _cell('$pct%', font,
                      color: pct > 70 ? successColor : pct > 40 ? PdfColor.fromHex('F59E0B') : dangerColor),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Generated by DebtTrack • ${DateFormat('dd MMM yyyy – HH:mm').format(DateTime.now())}',
            style: pw.TextStyle(font: font, fontSize: 8, color: grayColor),
          ),
        ],
      ),
    );

    return doc.save();
  }

  // ── Payment Report ──────────────────────────────────────────
  static Future<Uint8List> paymentReport(List<Payment> payments, String merchantName) async {
    final doc  = pw.Document();
    final font = await PdfGoogleFonts.dmSansRegular();
    final bold = await PdfGoogleFonts.dmSansBold();

    final successColor = PdfColor.fromHex('22C55E');
    final darkColor    = PdfColor.fromHex('1E2230');
    final total = payments.fold<double>(0, (s, p) => s + p.amount);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => pw.Container(
          color: darkColor,
          padding: const pw.EdgeInsets.all(16),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('DebtTrack — Payment Report', style: pw.TextStyle(font: bold, fontSize: 16, color: PdfColors.white)),
            pw.Text(merchantName, style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.grey300)),
          ]),
        ),
        build: (ctx) => [
          pw.SizedBox(height: 16),
          pw.Container(
            color: successColor,
            padding: const pw.EdgeInsets.all(14),
            child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Text('Total Collected', style: pw.TextStyle(font: bold, fontSize: 13, color: PdfColors.white)),
              pw.Text(_fmt(total), style: pw.TextStyle(font: bold, fontSize: 16, color: PdfColors.white)),
            ]),
          ),
          pw.SizedBox(height: 16),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.5),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FlexColumnWidth(1.8),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: darkColor),
                children: ['Date', 'Customer', 'Debt', 'Note', 'Amount'].map((h) =>
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(h, style: pw.TextStyle(font: bold, fontSize: 9, color: PdfColors.white)),
                  ),
                ).toList(),
              ),
              ...payments.asMap().entries.map((e) {
                final i = e.key; final p = e.value;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: i.isEven ? PdfColors.white : PdfColors.grey100),
                  children: [
                    _cell(DateFormat('dd/MM/yy').format(p.date), font),
                    _cell(p.customerName ?? '—', font),
                    _cell(p.debtDescription ?? '—', font),
                    _cell(p.note ?? '—', font),
                    _cell(_fmt(p.amount), font, color: successColor),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );

    return doc.save();
  }

  // ── Helpers ──────────────────────────────────────────────────
  static pw.Widget _statBox(String label, String value, PdfColor color, pw.Font font, pw.Font bold) =>
    pw.Expanded(child: pw.Container(
      color: PdfColor(color.red, color.green, color.blue, 0.1),
      padding: const pw.EdgeInsets.all(10),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(label, style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600)),
        pw.SizedBox(height: 4),
        pw.Text(value, style: pw.TextStyle(font: bold, fontSize: 13, color: color)),
      ]),
    ));

  static pw.Widget _cell(String text, pw.Font font, {PdfColor? color}) =>
    pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 8, color: color ?? PdfColors.grey800), overflow: pw.TextOverflow.clip),
    );
}
