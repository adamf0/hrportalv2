import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../state/app_state.dart';
import '../core/responsive_helper.dart';

class SalarySlipPage extends StatefulWidget {
  const SalarySlipPage({super.key});

  @override
  State<SalarySlipPage> createState() => _SalarySlipPageState();
}

class _SalarySlipPageState extends State<SalarySlipPage> {
  final List<String> _months = ["Jan", "Feb", "Mar", "Apr", "Mei", "Jun"];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).fetchPayrollDataFromApi();
    });
  }

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
    final appState = Provider.of<AppState>(context);
    final slip = appState.currentPayrollData;

    // Theme Colors
    const primaryColor = Color(0xFF003D9B);
    const background = Color(0xFFF8F9FB);
    const onSurface = Color(0xFF191C1E);
    const onSurfaceVariant = Color(0xFF434654);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Payroll',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: const Icon(Icons.notifications_none, color: onSurface, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Year Selector
              Flex(
                direction: context.isWatch ? Axis.vertical : Axis.horizontal,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: context.isWatch ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
                children: [
                  if (!context.isWatch) ...[
                    Text(
                      'Periode Tahun',
                      style: GoogleFonts.inter(
                        fontSize: context.sp(12),
                        fontWeight: FontWeight.w500,
                        color: onSurfaceVariant,
                      ),
                    ),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: appState.selectedPayrollYear,
                        icon: const Icon(Icons.expand_more, color: onSurfaceVariant, size: 18),
                        style: GoogleFonts.inter(
                          fontSize: context.sp(14),
                          fontWeight: FontWeight.bold,
                          color: onSurface,
                        ),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            appState.setSelectedPayrollYear(newValue);
                          }
                        },
                        items: <String>['2023', '2024', '2025', '2026', '2027']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Horizontal Scroll Months Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _months.map((m) {
                    final isSelected = appState.selectedPayrollMonth == m;
                    return GestureDetector(
                      onTap: () {
                        appState.setSelectedPayrollMonth(m);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryColor : const Color(0xFFEDEEF0),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: isSelected ? primaryColor : Colors.grey[300]!,
                            width: 1,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ] : null,
                        ),
                        child: Text(
                          m,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Loading indicator or the slip content
              appState.isLoadingPayroll
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 60.0),
                        child: CircularProgressIndicator(color: primaryColor),
                      ),
                    )
                  : slip == null
                      ? Container(
                          padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'Data Not Found',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Slip gaji untuk periode ini belum tersedia atau tidak ditemukan.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // RENDER SLIP EXACTLY AS PICTURE
                            _buildPrintableSlipWidget(slip),
                            const SizedBox(height: 24),

                            // Action Buttons Row (ONLY Unduh PDF, Cetak Slip deleted)
                            ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Unduh PDF slip gaji ${slip.bulan} ${slip.tahun} berhasil!'),
                                    backgroundColor: primaryColor,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.download, size: 20),
                              label: Text(
                                'Unduh PDF',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrintableSlipWidget(PayrollData slip) {
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
              // Header Table Box
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

              // No Urut Row
              _buildTextRow('No. Urut', ': ${slip.noMesin}', rightText: 'Hari'),
              // Nama Row
              _buildTextRow('Nama', ': ${slip.nama}'),

              const SizedBox(height: 6),

              // Gaji Pokok
              _buildMoneyRow('Gaji Pokok', slip.gajiPokok),
              // Suami/Istri
              _buildMoneyRow('Suami/istri', slip.tkeluarga),
              // Anak
              _buildMoneyRow('Anak', slip.tanak),
              // Pangan
              _buildMoneyRow('Pangan', slip.tpangan),
              // Struktural
              _buildMoneyRow('Struktural', slip.tstruktural),
              // Fungsional
              _buildMoneyRow('Fungsional', slip.tfungsional),

              // Dosen-specific Teaching lines
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

              // Transport
              _buildMoneyRow('Transpot', slip.transpot),
              // Khusus
              _buildMoneyRow('Khusus', slip.tkhusus),
              // Astek / DPLK
              _buildMoneyRow('Astek/DPLK', slip.astekY),
              // BPJS
              _buildMoneyRow('BPJS', slip.bpjs, bottomBorder: true),

              // Jumlah Pendapatan
              _buildSummaryRow('Jumlah Pendapatan', slip.gajikotor),

              const SizedBox(height: 8),

              // Deductions (Potongan)
              _buildMoneyRow('Astek/DPLK', astekDlpk),
              _buildMoneyRow('Koperasi', slip.pkoperasi),
              _buildMoneyRow('Yayasan', slip.pyayasan),
              _buildMoneyRow('Zakat 2.5%', slip.pzakat, bottomBorder: true),

              // Jumlah Potongan
              _buildSummaryRow('Jumlah Potongan', totalPotonganComputed),

              // Pendapatan Bersih
              _buildSummaryRow('Pendapatan Bersih', slip.gajibersih, isFinal: true),

              const SizedBox(height: 12),

              // Date Footer
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

              // Signatures
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

              // Names signature footer
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
