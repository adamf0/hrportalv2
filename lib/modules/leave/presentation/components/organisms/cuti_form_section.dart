import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrportalv2/common/presentation/components/atoms/form_section_header.dart';
import 'package:hrportalv2/common/presentation/components/molecules/responsive_date_range_row.dart';

class CutiFormSection extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final String? selectedCutiType;
  final VoidCallback onCutiTypeTap;
  final DateTime cutiStartDate;
  final DateTime cutiEndDate;
  final VoidCallback onSelectStartDate;
  final VoidCallback onSelectEndDate;
  final TextEditingController cutiDurationController;
  final TextEditingController cutiPurposeController;
  final Widget attachmentWidget;
  final Widget supervisorSelectorWidget;
  final bool isLoading;
  final VoidCallback onSubmit;

  const CutiFormSection({
    super.key,
    required this.formKey,
    required this.selectedCutiType,
    required this.onCutiTypeTap,
    required this.cutiStartDate,
    required this.cutiEndDate,
    required this.onSelectStartDate,
    required this.onSelectEndDate,
    required this.cutiDurationController,
    required this.cutiPurposeController,
    required this.attachmentWidget,
    required this.supervisorSelectorWidget,
    this.isLoading = false,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    String formatDate(DateTime date) {
      final months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }

    final startDateField = GestureDetector(
      onTap: onSelectStartDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              formatDate(cutiStartDate),
              style: GoogleFonts.inter(fontSize: 13, color: onSurface, fontWeight: FontWeight.w500),
            ),
            Icon(Icons.calendar_today, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );

    final endDateField = GestureDetector(
      onTap: onSelectEndDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              formatDate(cutiEndDate),
              style: GoogleFonts.inter(fontSize: 13, color: onSurface, fontWeight: FontWeight.w500),
            ),
            Icon(Icons.calendar_today, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FormSectionHeader(title: 'JENIS CUTI'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onCutiTypeTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      selectedCutiType ?? '-- Pilih Jenis Cuti --',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: selectedCutiType == null ? Colors.grey[400] : onSurface,
                        fontWeight: selectedCutiType == null ? FontWeight.normal : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          const FormSectionHeader(title: 'TANGGAL CUTI (RANGE)'),
          const SizedBox(height: 8),
          ResponsiveDateRangeRow(
            startWidget: startDateField,
            endWidget: endDateField,
          ),
          const SizedBox(height: 20),

          const FormSectionHeader(title: 'LAMA CUTI (HARI)'),
          const SizedBox(height: 8),
          TextFormField(
            controller: cutiDurationController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.inter(fontSize: 14, color: onSurface, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Lama cuti tidak boleh kosong';
              final val = int.tryParse(value);
              if (val == null || val <= 0) return 'Masukkan jumlah hari yang valid';
              return null;
            },
          ),
          const SizedBox(height: 20),

          const FormSectionHeader(title: 'TUJUAN / ALASAN PENGAJUAN'),
          const SizedBox(height: 8),
          TextFormField(
            controller: cutiPurposeController,
            maxLines: 4,
            style: GoogleFonts.inter(fontSize: 14, color: onSurface),
            decoration: InputDecoration(
              hintText: 'Tuliskan alasan lengkap pengajuan cuti Anda di sini...',
              hintStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: primaryColor, width: 1.5),
              ),
            ),
            validator: (value) => (value == null || value.trim().isEmpty) ? 'Alasan pengajuan harus diisi' : null,
          ),
          const SizedBox(height: 20),

          const FormSectionHeader(title: 'DOKUMEN PENDUKUNG'),
          const SizedBox(height: 8),
          attachmentWidget,
          const SizedBox(height: 20),

          const FormSectionHeader(title: 'VERIFIKASI ATASAN'),
          const SizedBox(height: 8),
          supervisorSelectorWidget,
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: isLoading ? null : onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: primaryColor.withOpacity(0.6),
              disabledForegroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Kirim Pengajuan Cuti',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.send, size: 18),
                    ],
                  ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
