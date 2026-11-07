import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../domain/models/offering.dart';
import '../../../domain/models/rental_tool.dart';
import './invoice_pdf.dart' show terbilangRupiah;

/// Dedicated invoice renderer for **Rent Tool** offerings.
///
/// The layout mirrors `lib/assets/invoice_mockup_rent_tool_only.pdf` and is
/// driven entirely by the offering's [Offering.rentalItems] — nothing here is
/// hard-coded to sample data. Other service types keep using
/// [buildOfferingInvoicePdf] from `invoice_pdf.dart`; this file never affects
/// them.
///
/// Measured geometry (A4 = 595.5 x 842 pt, from the reference PDF):
///   content left ≈ 48.8, content right ≈ 550.8 (width ≈ 502)
///   table columns: No 41.8 | Uraian 176.5 | Kuantitas 50.6 | Satuan 49.2 |
///                  Harga 87.8 | Jumlah 93.9
///   table header row 32.9 high, data rows ≈ 24.3 high
///   header fill #f5821f, grid/stroke #9fb4cc, info panels #eaedf8

// Palette (sampled from the reference).
const PdfColor _orange = PdfColor.fromInt(0xFFF5821F);
const PdfColor _cyan = PdfColor.fromInt(0xFF00AEEE);
const PdfColor _ink = PdfColor.fromInt(0xFF243038);
const PdfColor _muted = PdfColor.fromInt(0xFF6B7080);
const PdfColor _panel = PdfColor.fromInt(0xFFEAEDF8);
const PdfColor _panelBorder = PdfColor.fromInt(0xFFD2DEEA);
const PdfColor _grid = PdfColor.fromInt(0xFF9FB4CC);
const PdfColor _recapFill = PdfColor.fromInt(0xFFF1F4F6);
const PdfColor _blueFooter = PdfColor.fromInt(0xFF5B7AAE);
const PdfColor _black = PdfColor.fromInt(0xFF000000);
const PdfColor _address = PdfColor.fromInt(0xFF2F3B4F);

const double _left = 48.8;
const double _right = 550.8;
const double _contentWidth = _right - _left; // ≈ 502

const String _companyName = 'PT. GEOTERRA INDONESIA';
const String _companyAddress =
    'Alamat : Permai Jaya RT 08, Desa Mekar Jaya Sungai Gelam Muara Jambi, '
    'Provinsi Jambi Telp : +62 853-7867-6656, Website : '
    'www.geoterraindonesia.co.id';

// Full-width banner dimensions matching index.html (A4 width x 24 mm high).
// Kept at the original PDF banner footprint; aspect ratio matches BANNER.PNG.
const double _bannerWidth = 238.70;
const double _bannerHeight = 62.04;

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

/// Builds the Rent Tool invoice PDF for [offering].
///
/// [clientName] is the billing name shown under "Kepada Yth."; it falls back to
/// [Offering.owner]. [invoiceNumber], [bankName], [bankAccountNumber], and
/// [bankAccountName] are supplied by the caller (see `ClientDirectory`), so no
/// billing values are baked into the template.
Future<Uint8List> buildRentalInvoicePdf({
  required Offering offering,
  String? clientName,
  String invoiceNumber = '',
  DateTime? issuedAt,
  String bankName = '',
  String bankAccountNumber = '',
  String bankAccountName = '',
  String location = 'Jambi',
  bool showSignature = true,
  String directorName = 'SARIS',
}) async {
  final document = pw.Document();
  final date = issuedAt ?? DateTime.now();
  final recipient = (clientName ?? offering.owner).trim();
  final items = offering.rentalItems;

  final subtotal = items.fold<double>(0, (sum, item) => sum + item.total);
  final ppn = subtotal * 0.11;
  const pph = 0.0;
  final total = subtotal + ppn - pph;
  final period = _periodLabel(items, offering.rentalUntil);
  final totalDays = _totalDays(items);
  final terbilang = 'Terbilang: ${_terbilangSentence(total)}';

  document.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (context) => pw.Stack(
        children: [
          pw.Positioned(
            left: _left,
            top: 82.7,
            child: pw.SizedBox(
              width: _contentWidth,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _headerRow(recipient, location, date),
                  pw.SizedBox(height: 26),
                  _titleBlock(),
                  pw.SizedBox(height: 9),
                  _infoPanels(invoiceNumber, period, totalDays),
                  pw.SizedBox(height: 7.4),
                  _rentalTable(items),
                  _recap(subtotal, ppn, pph, terbilang),
                  pw.SizedBox(height: 37),
                  _paymentInfo(bankName, bankAccountNumber, bankAccountName),
                  pw.SizedBox(height: 22),
                  if (showSignature)
                    pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: _signatureBlock(directorName),
                    ),
                ],
              ),
            ),
          ),
          // Full-width geometric banner matching the SVG used by index.html.
          pw.Positioned(left: 0, top: 0, child: _topBannerGraphic()),
          pw.Positioned(left: _left, top: 761, child: _footerBanner()),
        ],
      ),
    ),
  );

  return document.save();
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

/// Company block (left) and recipient block (right) of the letterhead.
pw.Widget _headerRow(String recipient, String location, DateTime date) {
  final recipientLines = recipient
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _companyWordmark(fontSize: 11.5),
            pw.SizedBox(height: 3),
            pw.Text(
              'Jasa Survei dan Pemetaan',
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: _ink,
              ),
            ),
            pw.SizedBox(height: 1),
            pw.Text(
              'Topografi | Batimetri | Drone | LiDAR',
              style: const pw.TextStyle(fontSize: 8, color: _muted),
            ),
          ],
        ),
      ),
      pw.SizedBox(width: 20),
      pw.SizedBox(
        width: 210,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              '$location, ${_formatDate(date)}',
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                fontSize: 9.5,
                fontWeight: pw.FontWeight.bold,
                color: _ink,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              'Kepada Yth.',
              textAlign: pw.TextAlign.right,
              style: const pw.TextStyle(fontSize: 8.5, color: _muted),
            ),
            for (final line in recipientLines)
              pw.Text(
                line,
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _ink,
                ),
              ),
          ],
        ),
      ),
    ],
  );
}

/// "PT. GEO TERRA INDONESIA" wordmark with the mockup's per-word colours.
pw.Widget _companyWordmark({required double fontSize}) {
  pw.TextSpan span(String text, PdfColor color) => pw.TextSpan(
    text: text,
    style: pw.TextStyle(
      fontSize: fontSize,
      fontWeight: pw.FontWeight.bold,
      color: color,
    ),
  );
  return pw.RichText(
    text: pw.TextSpan(
      children: [
        span('PT. GEO', _orange),
        span('TERRA', _cyan),
        span(' INDONESIA', _black),
      ],
    ),
  );
}

pw.Widget _titleBlock() {
  return pw.Column(
    children: [
      pw.Center(
        child: pw.Text(
          'INVOICE',
          style: pw.TextStyle(
            fontSize: 22,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
        ),
      ),
      pw.SizedBox(height: 3),
      pw.Center(
        child: pw.Text(
          'Tagihan Sewa Alat',
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: _orange,
          ),
        ),
      ),
    ],
  );
}

/// Two stacked info panels: invoice number / period / issuer / duration.
pw.Widget _infoPanels(String invoiceNumber, String period, int totalDays) {
  return pw.Column(
    children: [
      pw.Row(
        children: [
          pw.Expanded(
            child: _infoCell(
              'Nomor Invoice',
              invoiceNumber.isEmpty ? '-' : invoiceNumber,
            ),
          ),
          pw.SizedBox(width: 4),
          pw.Expanded(child: _infoCell('Periode Sewa', period)),
        ],
      ),
      pw.SizedBox(height: 4),
      pw.Row(
        children: [
          pw.Expanded(
            child: _infoCell('Penerbit Invoice', 'PT. Geoterra Indonesia'),
          ),
          pw.SizedBox(width: 4),
          pw.Expanded(
            child: _infoCell(
              'Terhitung',
              totalDays > 0 ? '$totalDays Hari' : '-',
            ),
          ),
        ],
      ),
    ],
  );
}

pw.Widget _infoCell(String label, String value) {
  return pw.Container(
    height: 30.8,
    padding: const pw.EdgeInsets.fromLTRB(6.5, 3.5, 6.5, 3),
    decoration: pw.BoxDecoration(
      color: _panel,
      border: pw.Border.all(color: _panelBorder, width: 0.7),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 9.5, color: _muted)),
        pw.SizedBox(height: 1),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 9.8,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Table
// ---------------------------------------------------------------------------

pw.Widget _rentalTable(List<RentalOfferingItem> items) {
  return pw.Container(
    decoration: const pw.BoxDecoration(
      boxShadow: [
        pw.BoxShadow(
          color: PdfColor.fromInt(0x33000000),
          offset: PdfPoint(1.5, 1.5),
          blurRadius: 2,
        ),
      ],
    ),
    child: pw.Table(
      border: const pw.TableBorder(
        top: pw.BorderSide(color: _grid, width: 0.5),
        bottom: pw.BorderSide(color: _grid, width: 0.5),
        left: pw.BorderSide(color: _grid, width: 0.5),
        right: pw.BorderSide(color: _grid, width: 0.5),
        horizontalInside: pw.BorderSide(color: _grid, width: 0.5),
        verticalInside: pw.BorderSide(color: _grid, width: 0.5),
      ),
      columnWidths: const {
        0: pw.FixedColumnWidth(41.8),
        1: pw.FlexColumnWidth(176.5),
        2: pw.FixedColumnWidth(50.6),
        3: pw.FixedColumnWidth(49.2),
        4: pw.FixedColumnWidth(87.8),
        5: pw.FixedColumnWidth(93.9),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _orange),
          children: [
            _header('No.', pw.Alignment.center),
            _header('Uraian Sewa', pw.Alignment.center),
            _header('Kuantitas', pw.Alignment.center),
            _header('Satuan', pw.Alignment.center),
            _header('Harga Perbulan', pw.Alignment.center),
            _header('Jumlah', pw.Alignment.center),
          ],
        ),
        for (var i = 0; i < items.length; i++)
          pw.TableRow(children: _rowCells(i, items[i])),
      ],
    ),
  );
}

pw.Widget _header(String text, pw.Alignment alignment) {
  return pw.Container(
    height: 32.9,
    alignment: alignment,
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 9.3,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
    ),
  );
}

List<pw.Widget> _rowCells(int index, RentalOfferingItem item) {
  // Rows without a billed rate (accessories bundled into another line) show a
  // dash, matching the mockup's Prisma/Tripod/Stick rows.
  final priced = item.rate > 0;
  final priceText = priced ? _commaRupiah(item.rate) : '-';
  final amountText = priced ? _commaRupiah(item.total) : '-';
  return [
    _cell('${index + 1}', pw.Alignment.center),
    _cell(item.tool.name, pw.Alignment.centerLeft),
    _cell('${item.quantity}', pw.Alignment.center),
    _cell(item.tool.unit, pw.Alignment.center),
    _cell(priceText, pw.Alignment.center),
    _cell(amountText, pw.Alignment.center, bold: priced),
  ];
}

pw.Widget _cell(String text, pw.Alignment alignment, {bool bold = false}) {
  return pw.Container(
    constraints: const pw.BoxConstraints(minHeight: 24.3),
    alignment: alignment,
    child: pw.Text(
      text,
      textAlign: _textAlign(alignment),
      style: pw.TextStyle(
        fontSize: 9.3,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: _black,
      ),
    ),
  );
}

pw.TextAlign _textAlign(pw.Alignment a) {
  if (a == pw.Alignment.centerLeft) return pw.TextAlign.left;
  return pw.TextAlign.center;
}

// ---------------------------------------------------------------------------
// Recap
// ---------------------------------------------------------------------------

pw.Widget _recap(double subtotal, double ppn, double pph, String terbilang) {
  // Width spans from x≈150 to the content right edge so the block hugs the
  // right side like the reference (recap rows sit at x 367..549).
  return pw.Align(
    alignment: pw.Alignment.centerRight,
    child: pw.SizedBox(
      width: 402.4,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.SizedBox(height: 6),
          _recapRow('Subtotal', _dotRupiah(subtotal)),
          _recapRow('PPN 11%', '-'),
          _recapRow('PPh 2% (dipotong)', '-'),
          pw.SizedBox(height: 8),
          pw.Text(
            terbilang,
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              fontStyle: pw.FontStyle.italic,
              color: _ink,
            ),
          ),
        ],
      ),
    ),
  );
}

pw.Widget _recapRow(String label, String value) {
  return pw.Container(
    width: 182.4,
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
    color: _recapFill,
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 9.3, color: _ink)),
        pw.Text(value, style: const pw.TextStyle(fontSize: 9.3, color: _ink)),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Payment info + signature
// ---------------------------------------------------------------------------

pw.Widget _paymentInfo(
  String bankName,
  String bankAccountNumber,
  String bankAccountName,
) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        'INFORMASI PEMBAYARAN',
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: _ink,
        ),
      ),
      pw.SizedBox(height: 3),
      pw.Text(
        'Pembayaran dapat dilakukan melalui transfer bank ke rekening berikut:',
        style: const pw.TextStyle(fontSize: 10, color: _ink),
      ),
      pw.SizedBox(height: 2),
      pw.Text(
        bankName.isEmpty ? 'Bank BRI' : bankName,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: _ink,
        ),
      ),
      pw.SizedBox(height: 1.5),
      _bankLine(
        'Nomor Rekening',
        bankAccountNumber.isEmpty ? '-' : bankAccountNumber,
      ),
      _bankLine('Atas Nama', bankAccountName.isEmpty ? '-' : bankAccountName),
    ],
  );
}

pw.Widget _bankLine(String label, String value) {
  return pw.Row(
    children: [
      pw.SizedBox(
        width: 108,
        child: pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: _ink),
        ),
      ),
      pw.Text(': $value', style: const pw.TextStyle(fontSize: 10, color: _ink)),
    ],
  );
}

pw.Widget _signatureBlock(String directorName) {
  final name = directorName.trim().isEmpty ? 'SARIS' : directorName.trim();
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    mainAxisSize: pw.MainAxisSize.min,
    children: [
      pw.Text(
        _companyName,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: _ink,
        ),
      ),
      pw.SizedBox(height: 48),
      pw.Container(
        width: 110,
        padding: const pw.EdgeInsets.only(bottom: 2),
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _ink, width: 0.7)),
        ),
        child: pw.Text(
          name,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
        ),
      ),
      pw.SizedBox(height: 2),
      pw.Text(
        'Direktur',
        textAlign: pw.TextAlign.center,
        style: const pw.TextStyle(fontSize: 9.5, color: _ink),
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Footer / decorative logos
// ---------------------------------------------------------------------------

/// Full-width top banner copied from the geometric SVG in index.html.
///
/// Uses the same viewBox, polygon coordinates, and colors as the HTML:
/// orange #ff8218, blue #5279bd, dark #343b45, and grey #9aa0a8.
pw.Widget _topBannerGraphic() {
  // Exact final user SVG. Only the viewBox is cropped from y=0..95 to
  // y=3..95 to remove the narrow white strip at the top. All SVG paths,
  // coordinates, colors and strokes are otherwise unchanged.
  const svg = r'''
<svg xmlns="http://www.w3.org/2000/svg"
     width="354" height="95" viewBox="0 3 354 92">
  <rect width="354" height="95" fill="#ffffff"/>

  <!-- Main orange left ribbon. -->
  <path d="M 1,3
           L 188,3
           L 109,87
           L 1,41
           Z"
        fill="#F88021"/>

  <!-- Narrow dark bevel separating the orange and blue facets. -->
  <path d="M 188,3
           L 195,3
           L 141,55
           L 109,87
           Z"
        fill="#44526A"/>

  <!-- Blue upper-right tapered facet. -->
  <path d="M 195,3
           L 320,3
           L 188,39
           L 141,55
           Z"
        fill="#4470C4"/>

  <!-- Grey lower fold / triangular facet. -->
  <path d="M 109,87
           L 141,55
           L 188,39
           Z"
        fill="#A3A3A3"/>

  <!-- Fine triangular dark crease along the upper edge of the grey fold, reversed. -->
  <path d="M 141,55 L 188,39 L 144,51 Z"
        fill="#44526A"/>
</svg>
''';

  return pw.SizedBox(
    width: _bannerWidth,
    height: _bannerHeight,
    child: pw.SvgImage(svg: svg, fit: pw.BoxFit.fill),
  );
}

pw.Widget _footerBanner() {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Row(
        children: [
          pw.Container(width: 424.8, height: 3.8, color: _orange),
          pw.Container(width: 77.1, height: 3.8, color: _blueFooter),
        ],
      ),
      pw.SizedBox(height: 3),
      _companyWordmark(fontSize: 9.89),
      pw.SizedBox(height: 1),
      pw.SizedBox(
        width: _contentWidth,
        child: pw.RichText(
          text: pw.TextSpan(
            style: const pw.TextStyle(fontSize: 7.5, color: _address),
            children: [
              pw.TextSpan(
                text: _companyAddress.replaceFirst(
                  'www.geoterraindonesia.co.id',
                  '',
                ),
              ),
              const pw.TextSpan(
                text: 'www.geoterraindonesia.co.id',
                style: pw.TextStyle(color: _cyan),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Period label, e.g. `19 September 2026 s/d 19 Oktober 2026`.
///
/// The reference renders the end as `start + duration` days (30 days from
/// 19 September ends 19 October), so we add [RentalOfferingItem.duration]
/// rather than the model's inclusive `endsAt` (which is the last rented day).
String _periodLabel(List<RentalOfferingItem> items, DateTime? fallbackEnd) {
  if (items.isEmpty) {
    return fallbackEnd == null ? '-' : _formatDate(fallbackEnd);
  }
  var start = items.first.startsAt;
  var end = items.first.startsAt.add(Duration(days: items.first.duration));
  for (final item in items.skip(1)) {
    if (item.startsAt.isBefore(start)) start = item.startsAt;
    final itemEnd = item.startsAt.add(Duration(days: item.duration));
    if (itemEnd.isAfter(end)) end = itemEnd;
  }
  if (fallbackEnd != null && fallbackEnd.isAfter(end)) end = fallbackEnd;
  return '${_formatDate(start)} s/d ${_formatDate(end)}';
}

int _totalDays(List<RentalOfferingItem> items) {
  if (items.isEmpty) return 0;
  final longest = items
      .map((item) => item.duration)
      .reduce((a, b) => a > b ? a : b);
  return longest;
}

String _terbilangSentence(double total) {
  final words = terbilangRupiah(total);
  return words.endsWith('.') ? words : '$words.';
}

String _commaRupiah(double value) {
  final digits = value.round().abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return 'Rp. $buffer';
}

String _dotRupiah(double value) {
  final digits = value.round().abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return 'Rp $buffer';
}

String _formatDate(DateTime date) {
  return '${date.day} ${_months[date.month - 1]} ${date.year}';
}
