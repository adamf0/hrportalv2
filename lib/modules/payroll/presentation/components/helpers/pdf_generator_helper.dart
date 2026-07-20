import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:hrportalv2/modules/payroll/domain/payroll.dart';

class PdfGeneratorHelper {
  static Future<File> generateSalarySlipPdf(PayrollData slip) async {
    final pdf = pw.Document();

    String formatRupiah(double val) {
      final parts = val.toInt().toString().split('');
      final List<String> formatted = [];
      int count = 0;
      for (int i = parts.length - 1; i >= 0; i--) {
        formatted.insert(0, parts[i]);
        count++;
        if (count == 3 && i > 0) {
          formatted.insert(0, '.');
          count = 0;
        }
      }
      return formatted.join('');
    }

    final double astekDlpk = slip.gajikotor > 0 ? (slip.gajikotor - slip.gajibersih) : 0.0;
    final totalPotonganComputed = astekDlpk + slip.pkoperasi + slip.pyayasan + slip.pzakat;
    final isDosen = slip.status.toUpperCase() == 'DOSEN';
    final hasProdi = slip.prodi.isNotEmpty;

    final font = pw.Font.courier();
    final fontBold = pw.Font.courierBold();

    pw.Widget buildTextRow(String left, String right, {String rightText = ''}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 80,
              child: pw.Text(
                left,
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 10.5,
                ),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                right,
                style: pw.TextStyle(
                  font: font,
                  fontSize: 10.5,
                ),
              ),
            ),
            if (rightText.isNotEmpty)
              pw.Text(
                rightText,
                style: pw.TextStyle(
                  font: font,
                  fontSize: 10.5,
                ),
              ),
          ],
        ),
      );
    }

    pw.Widget buildMoneyRow(String label, double val, {bool bottomBorder = false}) {
      return pw.Container(
        decoration: pw.BoxDecoration(
          border: bottomBorder
              ? const pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 1.0))
              : null,
        ),
        padding: const pw.EdgeInsets.symmetric(vertical: 2.0),
        child: pw.Row(
          children: [
            pw.SizedBox(
              width: 120,
              child: pw.Text(
                label,
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 10.5,
                ),
              ),
            ),
            pw.Text(
              'Rp.',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 10.5,
              ),
            ),
            pw.Spacer(),
            pw.Text(
              formatRupiah(val),
              style: pw.TextStyle(
                font: font,
                fontSize: 10.5,
              ),
            ),
            pw.SizedBox(width: 4),
          ],
        ),
      );
    }

    pw.Widget buildSummaryRow(String label, double val, {bool isFinal = false}) {
      return pw.Container(
        decoration: pw.BoxDecoration(
          border: isFinal
              ? pw.Border.all(color: PdfColors.black, width: 1.2)
              : null,
        ),
        padding: const pw.EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
        child: pw.Row(
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 11,
              ),
            ),
            pw.Spacer(),
            pw.Text(
              'Rp.',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 11,
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Text(
              formatRupiah(val),
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 11,
              ),
            ),
            pw.SizedBox(width: 4),
          ],
        ),
      );
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Container(
              width: 355,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 1.2),
              ),
              padding: const pw.EdgeInsets.all(10.0),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Container(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(color: PdfColors.black, width: 1.2),
                      ),
                    ),
                    padding: const pw.EdgeInsets.only(bottom: 8.0),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'UNIT KERJA/FAKULTAS ${hasProdi ? slip.prodi.toUpperCase() : "REKTORAT"}',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 12,
                          ),
                        ),
                        pw.Text(
                          'UNIVERSITAS PAKUAN',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 12,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'GAJI dan TUNJANGAN',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 13,
                            decoration: pw.TextDecoration.underline,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Bulan/Tahun : ${slip.bulan}/${slip.tahun}',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  buildTextRow('No. Urut', ': ${slip.noMesin}', rightText: 'Hari'),
                  buildTextRow('Nama', ': ${slip.nama}'),
                  pw.SizedBox(height: 6),
                  
                  buildMoneyRow('Gaji Pokok', slip.gajiPokok),
                  buildMoneyRow('Suami/istri', slip.tkeluarga),
                  buildMoneyRow('Anak', slip.tanak),
                  buildMoneyRow('Pangan', slip.tpangan),
                  buildMoneyRow('Struktural', slip.tstruktural),
                  buildMoneyRow('Fungsional', slip.tfungsional),
                  
                  if (isDosen) ...[
                    buildTextRow('Mengajar :', ''),
                    if (slip.mengajar > 0)
                      buildMoneyRow('  -S1', slip.mengajar),
                    if (slip.nonregular > 0)
                      buildMoneyRow('  -S1-NonReg', slip.nonregular),
                    if (slip.d3regular > 0)
                      buildMoneyRow('  -Vokasi', slip.d3regular),
                    if (slip.d3nonregular > 0)
                      buildMoneyRow('  -Vokasi-NonReg', slip.d3nonregular),
                    if (slip.pascasarjana > 0)
                      buildMoneyRow('  -Pasca', slip.pascasarjana),
                  ],
                  
                  buildMoneyRow('Transpot', slip.transpot),
                  buildMoneyRow('Khusus', slip.tkhusus),
                  buildMoneyRow('Astek/DPLK', slip.astekY),
                  buildMoneyRow('BPJS', slip.bpjs, bottomBorder: true),
                  
                  buildSummaryRow('Jumlah Pendapatan', slip.gajikotor),
                  pw.SizedBox(height: 8),
                  
                  buildMoneyRow('Astek/DPLK', astekDlpk),
                  buildMoneyRow('Koperasi', slip.pkoperasi),
                  buildMoneyRow('Yayasan', slip.pyayasan),
                  buildMoneyRow('Zakat 2.5%', slip.pzakat, bottomBorder: true),
                  
                  buildSummaryRow('Jumlah Potongan', totalPotonganComputed),
                  buildSummaryRow('Pendapatan Bersih', slip.gajibersih, isFinal: true),
                  pw.SizedBox(height: 12),
                  
                  pw.Text(
                    'Bogor, ${slip.bulan} ${slip.tahun}',
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 10,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          'Yang Menerima,',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          'Yang Menyerahkan,',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 40),
                  
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          '(${slip.nama})',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          '',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/slip_gaji_${slip.bulan}_${slip.tahun}.pdf");
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
