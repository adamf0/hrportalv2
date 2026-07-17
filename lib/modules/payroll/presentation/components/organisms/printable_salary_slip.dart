import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrportalv2/modules/payroll/domain/payroll.dart';

class PrintableSalarySlip extends StatelessWidget {
  final PayrollData slip;

  const PrintableSalarySlip({
    super.key,
    required this.slip,
  });

  String _formatRupiah(double val) {
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

  @override
  Widget build(BuildContext context) {
    final double astekDlpk = slip.gajikotor > 0 ? (slip.gajikotor - slip.gajibersih) : 0.0;
    final totalPotonganComputed = astekDlpk + slip.pkoperasi + slip.pyayasan + slip.pzakat;

    final isDosen = slip.status.toUpperCase() == 'DOSEN';
    final hasProdi = slip.prodi.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Center(
        child: Container(
          width: 355,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 1.2),
            color: Colors.white,
          ),
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.black, width: 1.2),
                  ),
                ),
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Column(
                  children: [
                    Text(
                      'UNIT KERJA/FAKULTAS ${hasProdi ? slip.prodi.toUpperCase() : "REKTORAT"}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.robotoMono(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'UNIVERSITAS PAKUAN',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.robotoMono(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'GAJI dan TUNJANGAN',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.robotoMono(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Bulan/Tahun : ${slip.bulan}/${slip.tahun}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.robotoMono(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              _buildTextRow('No. Urut', ': ${slip.noMesin}', rightText: 'Hari'),
              _buildTextRow('Nama', ': ${slip.nama}'),

              const SizedBox(height: 6),

              _buildMoneyRow('Gaji Pokok', slip.gajiPokok),
              _buildMoneyRow('Suami/istri', slip.tkeluarga),
              _buildMoneyRow('Anak', slip.tanak),
              _buildMoneyRow('Pangan', slip.tpangan),
              _buildMoneyRow('Struktural', slip.tstruktural),
              _buildMoneyRow('Fungsional', slip.tfungsional),

              if (isDosen) ...[
                _buildTextRow('Mengajar :', ''),
                if (slip.mengajar > 0)
                  _buildMoneyRow('  -S1', slip.mengajar),
                if (slip.nonregular > 0)
                  _buildMoneyRow('  -S1-NonReg', slip.nonregular),
                if (slip.d3regular > 0)
                  _buildMoneyRow('  -Vokasi', slip.d3regular),
                if (slip.d3nonregular > 0)
                  _buildMoneyRow('  -Vokasi-NonReg', slip.d3nonregular),
                if (slip.pascasarjana > 0)
                  _buildMoneyRow('  -Pasca', slip.pascasarjana),
              ],

              _buildMoneyRow('Transpot', slip.transpot),
              _buildMoneyRow('Khusus', slip.tkhusus),
              _buildMoneyRow('Astek/DPLK', slip.astekY),
              _buildMoneyRow('BPJS', slip.bpjs, bottomBorder: true),

              _buildSummaryRow('Jumlah Pendapatan', slip.gajikotor),

              const SizedBox(height: 8),

              _buildMoneyRow('Astek/DPLK', astekDlpk),
              _buildMoneyRow('Koperasi', slip.pkoperasi),
              _buildMoneyRow('Yayasan', slip.pyayasan),
              _buildMoneyRow('Zakat 2.5%', slip.pzakat, bottomBorder: true),

              _buildSummaryRow('Jumlah Potongan', totalPotonganComputed),
              _buildSummaryRow('Pendapatan Bersih', slip.gajibersih, isFinal: true),

              const SizedBox(height: 12),

              Text(
                'Bogor, ${slip.bulan} ${slip.tahun}',
                textAlign: TextAlign.right,
                style: GoogleFonts.robotoMono(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Yang Menerima,',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.robotoMono(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Yang Menyerahkan,',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.robotoMono(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '(${slip.nama})',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.robotoMono(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.robotoMono(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextRow(String left, String right, {String rightText = ''}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              left,
              style: GoogleFonts.robotoMono(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: Text(
              right,
              style: GoogleFonts.robotoMono(
                fontSize: 10.5,
                color: Colors.black,
              ),
            ),
          ),
          if (rightText.isNotEmpty)
            Text(
              rightText,
              style: GoogleFonts.robotoMono(
                fontSize: 10.5,
                color: Colors.black,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMoneyRow(String label, double val, {bool bottomBorder = false}) {
    return Container(
      decoration: BoxDecoration(
        border: bottomBorder
            ? const Border(bottom: BorderSide(color: Colors.black, width: 1.0))
            : null,
      ),
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.robotoMono(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Text(
            'Rp.',
            style: GoogleFonts.robotoMono(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          Text(
            _formatRupiah(val),
            style: GoogleFonts.robotoMono(
              fontSize: 10.5,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double val, {bool isFinal = false}) {
    return Container(
      decoration: BoxDecoration(
        border: isFinal
            ? Border.all(color: Colors.black, width: 1.0)
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.robotoMono(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          Text(
            'Rp.',
            style: GoogleFonts.robotoMono(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatRupiah(val),
            style: GoogleFonts.robotoMono(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
