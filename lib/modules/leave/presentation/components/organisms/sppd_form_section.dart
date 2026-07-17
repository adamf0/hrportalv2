import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrportalv2/common/presentation/components/atoms/form_section_header.dart';
import 'package:hrportalv2/common/presentation/components/molecules/responsive_date_range_row.dart';

class SppdFormSection extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final String? selectedSppdType;
  final ValueChanged<String?> onSppdTypeChanged;
  final List<Map<String, String>> sppdTypes;
  final TextEditingController sppdCityController;
  final DateTime sppdStartDate;
  final DateTime sppdEndDate;
  final VoidCallback onSelectStartDate;
  final VoidCallback onSelectEndDate;
  final TextEditingController sppdDurationController;
  final TextEditingController sppdPurposeController;
  final Widget attachmentWidget;
  final Widget supervisorSelectorWidget;
  final VoidCallback onSubmit;

  const SppdFormSection({
    super.key,
    required this.formKey,
    required this.selectedSppdType,
    required this.onSppdTypeChanged,
    required this.sppdTypes,
    required this.sppdCityController,
    required this.sppdStartDate,
    required this.sppdEndDate,
    required this.onSelectStartDate,
    required this.onSelectEndDate,
    required this.sppdDurationController,
    required this.sppdPurposeController,
    required this.attachmentWidget,
    required this.supervisorSelectorWidget,
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
              formatDate(sppdStartDate),
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
              formatDate(sppdEndDate),
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
          const FormSectionHeader(title: 'JENIS DINAS / SPPD'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedSppdType,
            style: GoogleFonts.inter(fontSize: 13, color: onSurface, fontWeight: FontWeight.w500),
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
            hint: Text('-- Pilih Jenis Dinas --', style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13)),
            items: sppdTypes.map((type) {
              return DropdownMenuItem<String>(
                value: type['name'],
                child: Text(type['name']!),
              );
            }).toList(),
            onChanged: onSppdTypeChanged,
          ),
          const SizedBox(height: 20),

          const FormSectionHeader(title: 'KOTA TUJUAN DINAS'),
          const SizedBox(height: 8),
          TextFormField(
            controller: sppdCityController,
            style: GoogleFonts.inter(fontSize: 14, color: onSurface, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'e.g. Jakarta, Yogyakarta, Singapore',
              hintStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13),
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
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: primaryColor, width: 1.5),
              ),
            ),
            validator: (value) => (value == null || value.trim().isEmpty) ? 'Kota tujuan dinas harus diisi' : null,
          ),
          const SizedBox(height: 20),

          const FormSectionHeader(title: 'TANGGAL DINAS (RANGE)'),
          const SizedBox(height: 8),
          ResponsiveDateRangeRow(
            startWidget: startDateField,
            endWidget: endDateField,
          ),
          const SizedBox(height: 20),

          const FormSectionHeader(title: 'LAMA DINAS (HARI)'),
          const SizedBox(height: 8),
          TextFormField(
            controller: sppdDurationController,
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
              if (value == null || value.trim().isEmpty) return 'Lama dinas tidak boleh kosong';
              final val = int.tryParse(value);
              if (val == null || val <= 0) return 'Masukkan jumlah hari yang valid';
              return null;
            },
          ),
          const SizedBox(height: 20),

          const FormSectionHeader(title: 'ALASAN PENGAJUAN'),
          const SizedBox(height: 8),
          TextFormField(
            controller: sppdPurposeController,
            maxLines: 4,
            style: GoogleFonts.inter(fontSize: 14, color: onSurface),
            decoration: InputDecoration(
              hintText: 'Tuliskan alasan lengkap perjalanan dinas Anda di sini...',
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
            validator: (value) => (value == null || value.trim().isEmpty) ? 'Alasan dinas harus diisi' : null,
          ),
          const SizedBox(height: 20),

          const FormSectionHeader(title: 'SURAT TUGAS / LAMPIRAN'),
          const SizedBox(height: 8),
          attachmentWidget,
          const SizedBox(height: 20),

          const FormSectionHeader(title: 'VERIFIKASI ATASAN'),
          const SizedBox(height: 8),
          supervisorSelectorWidget,
          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Kirim Pengajuan SPPD',
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
