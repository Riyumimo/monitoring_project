import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/line_item_text_run.dart';
import '../models/offering.dart';
import '../models/payment.dart';
import '../utils/currency.dart';
import '../utils/offering_line_items.dart';
import 'client_directory.dart';

// Palette taken from the Termin invoice mockup.
const PdfColor _navy = PdfColor.fromInt(0xFF194F7A);
const PdfColor _blue = PdfColor.fromInt(0xFF075C9D);
const PdfColor _orange = PdfColor.fromInt(0xFFF57D25);
const PdfColor _orangeDeep = PdfColor.fromInt(0xFFF5821F);
const PdfColor _ink = PdfColor.fromInt(0xFF193044);
const PdfColor _charcoal = PdfColor.fromInt(0xFF243038);
const PdfColor _muted = PdfColor.fromInt(0xFF556575);
const PdfColor _mutedLight = PdfColor.fromInt(0xFF6B7080);
const PdfColor _border = PdfColor.fromInt(0xFFCFDEE8);
const PdfColor _panel = PdfColor.fromInt(0xFFF3F8FC);
const PdfColor _panelAlt = PdfColor.fromInt(0xFFF1F6F9);
const PdfColor _rowLight = PdfColor.fromInt(0xFFE6F2F9);
const PdfColor _rowWhite = PdfColor.fromInt(0xFFFCFDFE);
const PdfColor _excludedRow = PdfColor.fromInt(0xFFDDECF6);
const PdfColor _footerBlue = PdfColor.fromInt(0xFF5B7BAF);

const String _companyName = 'PT. GEOTERRA INDONESIA';
const String _companyTagline = 'Jasa Survei dan Pemetaan';
const String _companyServices = 'Topografi | Batimetri | Drone | LiDAR';
const String _companyFooter = 'Menjadi Mitra, Menjaga Kualitas';

const double _pageMarginLeft = 36;
const double _pageMarginTop = 22;
const double _pageMarginRight = 34;
const double _pageMarginBottom = 22;
const double _bannerWidth = 232;
const double _bannerHeight = _bannerWidth * 131 / 497;
const double _bannerGap = 14;

const List<String> _months = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

/// One row in the invoice's "Description of Work" table.
///
/// Section rows can leave [amount] empty and use [indent] / [emphasized] to
/// reproduce a hierarchical cost breakdown (A, B, 1, a, ...).
class InvoiceLineItem {
  final String sn;
  final String description;
  final List<LineItemTextRun> descriptionRuns;
  final bool rowBold;
  final bool rowItalic;
  final String qty;
  final String uom;
  final double? amount;
  final int indent;
  final bool emphasized;

  /// When true, this row is not included in the invoice's fallback item total.
  final bool excludeFromTotal;

  const InvoiceLineItem({
    required this.sn,
    required this.description,
    this.descriptionRuns = const [],
    this.rowBold = false,
    this.rowItalic = false,
    this.qty = '',
    this.uom = '',
    this.amount,
    this.indent = 0,
    this.emphasized = false,
    this.excludeFromTotal = false,
  });
}

/// Builds a client-facing PDF invoice for [offering].
///
/// The layout and palette follow the company's Termin invoice mockup: navy and
/// orange header, light-blue information panels, itemised work table, billing
/// recap, payment terms, notes, and signature.
///
/// Optional parameters exist so the real PO, tax, and bank details can be
/// supplied later without changing the layout.
Future<Uint8List> buildOfferingInvoicePdf({
  required Offering offering,
  ClientRecord? client,
  List<Payment> payments = const [],
  List<InvoiceLineItem>? items,
  DateTime? issuedAt,
  String invoiceTitle = 'INVOICE',
  String invoiceSubtitle = 'TAGIHAN',
  String poNumber = '',
  DateTime? poDate,
  double taxRate = 0,
  double? contractValue,
  double? invoiceAmount,
  String bankName = '',
  String bankAccountNumber = '',
  String bankAccountName = '',
  String paymentTerm = 'Pembayaran sesuai ketentuan PO/kontrak.',
}) async {
  final document = pw.Document();
  final date = issuedAt ?? DateTime.now();
  final invoiceNumber = _invoiceNumber(offering);
  final contract = contractValue ?? offering.budgetAmount;
  final subtotal = invoiceAmount ?? offering.budgetAmount;
  final tax = (subtotal ?? 0) * taxRate;
  final total = subtotal == null ? null : subtotal + tax;
  final lineItems = items ?? _defaultItems(offering, subtotal);
  final itemTotal = _invoiceItemTotal(lineItems);
  final tableTotal = contract ?? (itemTotal > 0 ? itemTotal : null);
  final hasTax = subtotal != null && taxRate > 0;
  final taxPercent = taxRate * 100;
  final taxLabel = taxPercent % 1 == 0
      ? taxPercent.toStringAsFixed(0)
      : taxPercent.toStringAsFixed(1);
  final isTermin = invoiceSubtitle.toUpperCase().contains('TERMIN');
  final termName = isTermin
      ? invoiceSubtitle.toUpperCase().replaceFirst('TAGIHAN ', '')
      : 'Termin';
  final subtotalLabel =
      invoiceAmount != null && contract != null && contract > 0
      ? '$termName ${_percentLabel(invoiceAmount, contract)} dari nilai '
            'kontrak / Subtotal (DPP)'
      : 'Subtotal (DPP)';
  final terbilang = total == null
      ? '-'
      : '${terbilangRupiah(total)}'
            '${hasTax ? ' (sebelum pemotongan PPh).' : '.'}';
  final logo = await _loadLogo();

  document.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(
          _pageMarginLeft,
          _pageMarginTop,
          _pageMarginRight,
          _pageMarginBottom,
        ),
        buildBackground: (context) {
          if (logo == null || context.pageNumber != 1) {
            return pw.SizedBox.shrink();
          }
          return _banner(logo);
        },
      ),
      footer: _footer,
      build: (context) => [
        if (logo != null)
          pw.SizedBox(height: _bannerHeight - _pageMarginTop + _bannerGap),
        _header(invoiceTitle, invoiceSubtitle, offering),
        pw.SizedBox(height: 8),
        _headerBand(),
        pw.SizedBox(height: 8),
        _parties(
          offering: offering,
          client: client,
          invoiceNumber: invoiceNumber,
          date: date,
          poNumber: poNumber,
          poDate: poDate,
        ),
        pw.SizedBox(height: 8),
        _projectLine(offering, contract),
        pw.SizedBox(height: 6),
        _itemsTable(lineItems, tableTotal),
        pw.SizedBox(height: 8),
        _recap(
          title: 'REKAP ${invoiceSubtitle.toUpperCase()}',
          subtotalLabel: subtotalLabel,
          subtotal: subtotal,
          taxLabel: taxLabel,
          tax: tax,
          total: total,
          hasTax: hasTax,
          terbilang: terbilang,
        ),
        if (payments.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          _paymentHistory(payments),
        ],
        pw.SizedBox(height: 8),
        _paymentAndTerms(
          bankName: bankName,
          bankAccountNumber: bankAccountNumber,
          bankAccountName: bankAccountName,
          paymentTerm: paymentTerm,
          termsTitle: isTermin ? 'KETENTUAN TERMIN' : 'KETENTUAN PEMBAYARAN',
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(child: _notes()),
            pw.SizedBox(width: 22),
            pw.SizedBox(width: 190, child: _signatureBlock()),
          ],
        ),
      ],
    ),
  );

  return document.save();
}

/// A safe file name for the generated invoice, e.g. `Invoice-OFR-2026-014.pdf`.
String invoicePdfFileName(Offering offering) {
  final raw = offering.number.trim().isNotEmpty
      ? offering.number.trim()
      : offering.id;
  final safe = raw.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '-');
  return 'Invoice-$safe.pdf';
}

/// Converts an amount into Indonesian words, e.g. `111000000` becomes
/// `Seratus sebelas juta rupiah`.
String terbilangRupiah(num amount) {
  final rounded = amount.round();
  if (rounded == 0) return 'Nol rupiah';
  final sign = rounded < 0 ? 'Minus ' : '';
  final words = _terbilang(rounded.abs());
  if (words.isEmpty) return '${sign}Nol rupiah';
  final capitalised = words[0].toUpperCase() + words.substring(1);
  return '$sign$capitalised rupiah';
}

String _terbilang(int value) {
  const satuan = [
    '',
    'satu',
    'dua',
    'tiga',
    'empat',
    'lima',
    'enam',
    'tujuh',
    'delapan',
    'sembilan',
    'sepuluh',
    'sebelas',
  ];
  String build(int number) {
    if (number < 12) return satuan[number];
    if (number < 20) return '${build(number - 10)} belas';
    if (number < 100) {
      return '${build(number ~/ 10)} puluh ${build(number % 10)}';
    }
    if (number < 200) return 'seratus ${build(number - 100)}';
    if (number < 1000) {
      return '${build(number ~/ 100)} ratus ${build(number % 100)}';
    }
    if (number < 2000) return 'seribu ${build(number - 1000)}';
    if (number < 1000000) {
      return '${build(number ~/ 1000)} ribu ${build(number % 1000)}';
    }
    if (number < 1000000000) {
      return '${build(number ~/ 1000000)} juta ${build(number % 1000000)}';
    }
    if (number < 1000000000000) {
      return '${build(number ~/ 1000000000)} miliar '
          '${build(number % 1000000000)}';
    }
    return '${build(number ~/ 1000000000000)} triliun '
        '${build(number % 1000000000000)}';
  }

  return build(value).replaceAll(RegExp(r'\s+'), ' ').trim();
}

Future<pw.MemoryImage?> _loadLogo() async {
  try {
    final data = await rootBundle.load('lib/assets/invoice_logo.png');
    return pw.MemoryImage(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  } catch (_) {
    return null;
  }
}

List<InvoiceLineItem> _defaultItems(Offering offering, double? budget) {
  if (offering.lineItems.isNotEmpty) {
    final numbers = lineItemLabels(
      offering.lineItems,
      style: offering.numberingStyle,
    );
    return [
      for (var index = 0; index < offering.lineItems.length; index++)
        InvoiceLineItem(
          sn: numbers[index],
          description: offering.lineItems[index].description,
          descriptionRuns: offering.lineItems[index].descriptionRuns,
          rowBold: offering.lineItems[index].rowBold,
          rowItalic: offering.lineItems[index].rowItalic,
          qty: offering.lineItems[index].qty,
          uom: offering.lineItems[index].uom,
          amount: offering.lineItems[index].amount > 0
              ? offering.lineItems[index].amount
              : null,
          indent: offering.lineItems[index].indent,
          excludeFromTotal: offering.lineItems[index].excludeFromTotal,
        ),
    ];
  }

  final details = [
    if (offering.serviceType.isNotEmpty) offering.serviceType,
    if (offering.address.isNotEmpty) offering.address,
  ].join(' - ');
  return [
    InvoiceLineItem(
      sn: '1',
      description: details.isEmpty
          ? offering.name
          : '${offering.name}\n$details',
      qty: '1',
      uom: 'Lot',
      amount: budget,
    ),
  ];
}

double _invoiceItemTotal(List<InvoiceLineItem> items) {
  if (items.isEmpty) return 0;
  final rootIndent = items
      .map((item) => item.indent)
      .reduce((a, b) => a < b ? a : b);

  var total = 0.0;
  for (var index = 0; index < items.length; index++) {
    if (items[index].indent == rootIndent) {
      total += _effectiveInvoiceItem(items, index);
    }
  }
  return total;
}

double _effectiveInvoiceItem(List<InvoiceLineItem> items, int index) {
  final item = items[index];
  final own = item.excludeFromTotal ? 0.0 : (item.amount ?? 0);
  if (own > 0) return own;

  int? childIndent;
  var total = 0.0;
  for (var i = index + 1; i < items.length; i++) {
    final row = items[i];
    if (row.indent <= item.indent) break;
    childIndent ??= row.indent;
    if (row.indent == childIndent) {
      total += _effectiveInvoiceItem(items, i);
    }
  }
  return total;
}

pw.Widget _banner(pw.MemoryImage logo) {
  return pw.Stack(
    overflow: pw.Overflow.visible,
    children: [
      pw.Positioned(
        left: -_pageMarginLeft,
        top: -_pageMarginTop,
        child: pw.Image(
          logo,
          width: _bannerWidth,
          height: _bannerHeight,
          fit: pw.BoxFit.contain,
        ),
      ),
    ],
  );
}

pw.Widget _header(
  String invoiceTitle,
  String invoiceSubtitle,
  Offering offering,
) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _companyName,
                  style: pw.TextStyle(
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                    color: _orangeDeep,
                    letterSpacing: 0.2,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  _companyTagline,
                  style: const pw.TextStyle(fontSize: 8.5, color: _charcoal),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  _companyServices,
                  style: const pw.TextStyle(fontSize: 8, color: _mutedLight),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 20),
          pw.SizedBox(
            width: 230,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  invoiceTitle,
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: _navy,
                    letterSpacing: 1.2,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  invoiceSubtitle.toUpperCase(),
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: _orange,
                    letterSpacing: 0.6,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  offering.name,
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ],
  );
}

pw.Widget _headerBand() {
  return pw.Column(
    children: [
      pw.Container(height: 0.5, color: _navy),
      pw.Row(
        children: [
          pw.Expanded(
            flex: 26,
            child: pw.Container(height: 10, color: _orange),
          ),
          pw.Expanded(flex: 74, child: pw.Container(height: 10, color: _navy)),
        ],
      ),
    ],
  );
}

pw.Widget _parties({
  required Offering offering,
  required ClientRecord? client,
  required String invoiceNumber,
  required DateTime date,
  required String poNumber,
  required DateTime? poDate,
}) {
  final name = client != null && client.name.isNotEmpty
      ? client.name
      : offering.owner;
  final location = client != null && client.location.isNotEmpty
      ? client.location
      : offering.address;
  final contactLine = [
    if (client != null && client.email.isNotEmpty) client.email,
    if (client != null && client.phone.isNotEmpty) client.phone,
  ].join(' | ');
  final contactLines = <String>[
    if (client != null && client.contactPerson.isNotEmpty) client.contactPerson,
    if (contactLine.isNotEmpty) contactLine,
    if (location.isNotEmpty) location,
  ];

  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Expanded(
        flex: 53,
        child: _panelBox(
          title: 'DITAGIHKAN KEPADA',
          height: 78,
          children: [
            pw.Text(
              name,
              style: pw.TextStyle(
                fontSize: 10.5,
                fontWeight: pw.FontWeight.bold,
                color: _ink,
              ),
            ),
            if (contactLines.isNotEmpty) ...[
              pw.SizedBox(height: 4),
              for (final line in contactLines)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 1.5),
                  child: pw.Text(
                    line,
                    style: const pw.TextStyle(fontSize: 8.2, color: _muted),
                  ),
                ),
            ],
          ],
        ),
      ),
      pw.SizedBox(width: 2.5),
      pw.Expanded(
        flex: 47,
        child: _panelBox(
          title: 'INFORMASI INVOICE',
          height: 78,
          children: [
            _infoRow('Nomor Invoice', invoiceNumber),
            _infoRow('Tanggal Invoice', _formatDate(date)),
            _infoRow('Nomor PO', poNumber.isEmpty ? '-' : poNumber),
            _infoRow('Tanggal PO', poDate == null ? '-' : _formatDate(poDate)),
          ],
        ),
      ),
    ],
  );
}

pw.Widget _projectLine(Offering offering, double? contract) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      _sectionLabel('PROYEK / PROJECT'),
      pw.SizedBox(height: 3),
      pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              offering.name,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: _ink,
              ),
            ),
          ),
          pw.Text(
            '  |  ',
            style: const pw.TextStyle(fontSize: 8, color: _muted),
          ),
          pw.Text(
            'Nilai Kontrak: ',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: _muted,
            ),
          ),
          pw.Text(
            _rupiah(contract),
            style: pw.TextStyle(
              fontSize: 8.2,
              fontWeight: pw.FontWeight.bold,
              color: _muted,
            ),
          ),
        ],
      ),
    ],
  );
}

pw.Widget _itemsTable(List<InvoiceLineItem> items, double? total) {
  return pw.Table(
    border: pw.TableBorder.all(color: _border, width: 0.48),
    columnWidths: const {
      0: pw.FlexColumnWidth(30),
      1: pw.FlexColumnWidth(290),
      2: pw.FlexColumnWidth(34),
      3: pw.FlexColumnWidth(35),
      4: pw.FlexColumnWidth(130),
    },
    defaultVerticalAlignment: pw.TableCellVerticalAlignment.top,
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _navy),
        children: [
          _cell('S/N', header: true, alignRight: true),
          _cell('Description of Work', header: true),
          _cell('Qty', header: true, alignRight: true),
          _cell('UOM', header: true, alignRight: true),
          _cell('Amount (IDR)', header: true, alignRight: true),
        ],
      ),
      for (var i = 0; i < items.length; i++)
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: items[i].excludeFromTotal
                ? _excludedRow
                : _rowWhite
          ),
          children: [
            _cell(
              items[i].sn,
              alignRight: true,
              bold: items[i].emphasized || items[i].rowBold,
              italic: items[i].rowItalic,
            ),
            pw.Padding(
              padding: pw.EdgeInsets.fromLTRB(
                7 + items[i].indent * 12,
                4,
                7,
                4,
              ),
              child: _invoiceDescription(items[i]),
            ),
            _cell(items[i].qty, alignRight: true, bold: items[i].emphasized),
            _cell(items[i].uom, alignRight: true, bold: items[i].emphasized),
            _cell(
              _amount(items[i].amount),
              alignRight: true,
              bold: items[i].emphasized || items[i].rowBold,
              italic: items[i].rowItalic,
            ),
          ],
        ),
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _panelAlt),
        children: [
          _cell(''),
          _cell('Total', bold: true),
          _cell(''),
          _cell(''),
          _cell(_rupiah(total), alignRight: true, bold: true),
        ],
      ),
    ],
  );
}

pw.Widget _invoiceDescription(InvoiceLineItem item) {
  if (item.description.isEmpty) return pw.SizedBox();

  final baseStyle = pw.TextStyle(
    fontSize: 8.4,
    fontWeight: item.emphasized ? pw.FontWeight.bold : pw.FontWeight.normal,
    color: _ink,
  );
  final runs = normalizedLineItemTextRuns(
    item.description,
    item.descriptionRuns,
  );
  if (runs.every((run) => run.isPlain)) {
    return pw.Text(item.description, style: baseStyle);
  }
  return pw.RichText(
    text: pw.TextSpan(
      style: baseStyle,
      children: [
        for (final run in runs)
          pw.TextSpan(
            text: item.description.substring(run.start, run.end),
            style: pw.TextStyle(
              fontWeight: run.bold ? pw.FontWeight.bold : null,
              fontStyle: run.italic ? pw.FontStyle.italic : null,
            ),
          ),
      ],
    ),
  );
}

pw.Widget _cell(
  String text, {
  bool header = false,
  bool bold = false,
  bool italic = false,
  bool alignRight = false,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    child: pw.Text(
      text,
      textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
      style: pw.TextStyle(
        fontSize: header ? 7.5 : 8.4,
        fontWeight: header || bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        fontStyle: italic ? pw.FontStyle.italic : null,
        color: header ? PdfColors.white : _ink,
        letterSpacing: header ? 0.2 : 0,
      ),
    ),
  );
}

pw.Widget _recap({
  required String title,
  required String subtotalLabel,
  required double? subtotal,
  required String taxLabel,
  required double tax,
  required double? total,
  required bool hasTax,
  required String terbilang,
}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      _sectionLabel(title),
      pw.SizedBox(height: 4),
      pw.Row(
        children: [
          pw.Spacer(),
          pw.SizedBox(
            width: 315,
            child: _recapRow(subtotalLabel, _rupiah(subtotal)),
          ),
        ],
      ),
      if (hasTax)
        pw.Row(
          children: [
            pw.Spacer(),
            pw.SizedBox(
              width: 315,
              child: _recapRow('PPN $taxLabel% (sesuai PO)', _rupiah(tax)),
            ),
          ],
        ),
      pw.SizedBox(height: 6),
      pw.Container(
        width: double.infinity,
        color: _orange,
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Text(
              'TOTAL TAGIHAN SEBELUM PPh',
              style: pw.TextStyle(
                fontSize: 8.2,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
            pw.SizedBox(width: 18),
            pw.Text(
              _rupiah(total),
              style: pw.TextStyle(
                fontSize: 9.2,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 6),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Terbilang:',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: _orange,
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Text(
              terbilang,
              style: pw.TextStyle(
                fontSize: 8,
                fontStyle: pw.FontStyle.italic,
                color: _muted,
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

pw.Widget _recapRow(String label, String value) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(vertical: 5),
    decoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: _border, width: 0.48)),
    ),
    child: pw.Row(
      children: [
        pw.Expanded(
          child: pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 8, color: _muted),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 8.2,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
        ),
      ],
    ),
  );
}

pw.Widget _paymentHistory(List<Payment> payments) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      _sectionLabel('RIWAYAT PEMBAYARAN'),
      pw.SizedBox(height: 5),
      pw.Table(
        border: pw.TableBorder.all(color: _border, width: 0.48),
        columnWidths: const {
          0: pw.FlexColumnWidth(1.5),
          1: pw.FlexColumnWidth(1.6),
          2: pw.FlexColumnWidth(2.4),
          3: pw.FlexColumnWidth(1.5),
        },
        defaultVerticalAlignment: pw.TableCellVerticalAlignment.top,
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: _navy),
            children: [
              _cell('Tanggal', header: true),
              _cell('Metode', header: true),
              _cell('Referensi', header: true),
              _cell('Jumlah', header: true, alignRight: true),
            ],
          ),
          for (var i = 0; i < payments.length; i++)
            pw.TableRow(
              decoration: pw.BoxDecoration(
                color: i.isEven ? _rowWhite : _rowLight,
              ),
              children: [
                _cell(_formatDate(payments[i].paidAt)),
                _cell(payments[i].method.label),
                _cell(
                  payments[i].invoiceNumber.isNotEmpty
                      ? payments[i].invoiceNumber
                      : payments[i].proofName.isNotEmpty
                      ? payments[i].proofName
                      : '-',
                ),
                _cell(
                  _amount(payments[i].amount),
                  alignRight: true,
                  bold: true,
                ),
              ],
            ),
        ],
      ),
    ],
  );
}

pw.Widget _paymentAndTerms({
  required String bankName,
  required String bankAccountNumber,
  required String bankAccountName,
  required String paymentTerm,
  required String termsTitle,
}) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Expanded(
        flex: 53,
        child: _panelBox(
          title: 'INFORMASI PEMBAYARAN',
          children: [
            _bankRow('Bank', bankName.isEmpty ? '-' : bankName),
            _bankRow(
              'Nomor rekening',
              bankAccountNumber.isEmpty ? '-' : bankAccountNumber,
            ),
            _bankRow(
              'Atas nama',
              bankAccountName.isEmpty ? '-' : bankAccountName,
            ),
          ],
        ),
      ),
      pw.SizedBox(width: 2.5),
      pw.Expanded(
        flex: 47,
        child: _panelBox(
          title: termsTitle,
          children: [
            _termLine(paymentTerm),
            _termLine('Jangka pembayaran 7 hari sesuai ketentuan dalam PO.'),
            _termLine('Invoice asli dan dokumen pendukung disampaikan.'),
          ],
        ),
      ),
    ],
  );
}

pw.Widget _panelBox({
  required String title,
  required List<pw.Widget> children,
  double? height,
}) {
  return pw.Container(
    height: height,
    padding: const pw.EdgeInsets.fromLTRB(10, 8, 9, 8),
    decoration: const pw.BoxDecoration(
      color: _panel,
      border: pw.Border(left: pw.BorderSide(color: _orange, width: 2.6)),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisSize: pw.MainAxisSize.min,
      children: [_sectionLabel(title), pw.SizedBox(height: 5), ...children],
    ),
  );
}

pw.Widget _notes() {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      _sectionLabel('CATATAN'),
      pw.SizedBox(height: 4),
      pw.Text(
        'PPN mengikuti ketentuan PO. PPh dipotong pemberi kerja sesuai '
        'ketentuan perpajakan yang berlaku; nilai transfer menyesuaikan '
        'bukti potong.',
        style: const pw.TextStyle(fontSize: 7.6, color: _muted),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        'Lengkapi nomor invoice, rekening, dan dokumen pajak sebelum '
        'pengiriman.',
        style: const pw.TextStyle(fontSize: 7.6, color: _muted),
      ),
    ],
  );
}

pw.Widget _signatureBlock() {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        'Hormat kami,',
        style: const pw.TextStyle(fontSize: 8.4, color: _ink),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        _companyName,
        style: pw.TextStyle(
          fontSize: 8.4,
          fontWeight: pw.FontWeight.bold,
          color: _ink,
        ),
      ),
      pw.SizedBox(height: 40),
      pw.Container(width: 150, height: 0.7, color: PdfColors.black),
      pw.SizedBox(height: 4),
      pw.Text(
        '(________________)',
        style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.black),
      ),
      pw.SizedBox(height: 2),
      pw.Text(
        'Direktur',
        style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.black),
      ),
    ],
  );
}

pw.Widget _infoRow(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 72,
          child: pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 7.8, color: _muted),
          ),
        ),
        pw.Text(': ', style: const pw.TextStyle(fontSize: 7.8, color: _muted)),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 8.2,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
        ),
      ],
    ),
  );
}

pw.Widget _bankRow(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 62,
          child: pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 7.6, color: _muted),
          ),
        ),
        pw.Text(': ', style: const pw.TextStyle(fontSize: 7.6, color: _muted)),
        pw.Expanded(
          child: pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 7.8, color: _muted),
          ),
        ),
      ],
    ),
  );
}

pw.Widget _termLine(String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.Text(
      text,
      style: const pw.TextStyle(fontSize: 7.6, color: _muted),
    ),
  );
}

pw.Widget _sectionLabel(String text) {
  return pw.Text(
    text,
    style: pw.TextStyle(
      fontSize: 7.5,
      fontWeight: pw.FontWeight.bold,
      color: _blue,
      letterSpacing: 0.8,
    ),
  );
}

pw.Widget _footer(pw.Context context) {
  return pw.Column(
    mainAxisSize: pw.MainAxisSize.min,
    children: [
      pw.Row(
        children: [
          pw.Expanded(
            flex: 85,
            child: pw.Container(height: 3.5, color: _orange),
          ),
          pw.Expanded(
            flex: 15,
            child: pw.Container(height: 3.5, color: _footerBlue),
          ),
        ],
      ),
      pw.SizedBox(height: 5),
      pw.Center(
        child: pw.Text(
          '$_companyName  |  $_companyFooter',
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 6.96, color: _muted),
        ),
      ),
    ],
  );
}

String _amount(double? value) {
  return value == null ? '' : formatRupiahInput(value);
}

String _rupiah(double? value) {
  return value == null ? '-' : 'Rp${formatRupiahInput(value)}';
}

String _percentLabel(double part, double whole) {
  final percent = part / whole * 100;
  return '${percent % 1 == 0 ? percent.toStringAsFixed(0) : percent.toStringAsFixed(1)}%';
}

String _invoiceNumber(Offering offering) {
  final raw = offering.number.trim().isNotEmpty
      ? offering.number.trim()
      : offering.id;
  return raw.toUpperCase().startsWith('INV') ? raw : 'INV-$raw';
}

String _formatDate(DateTime date) {
  return '${date.day} ${_months[date.month - 1]} ${date.year}';
}
