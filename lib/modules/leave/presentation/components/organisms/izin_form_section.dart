import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrportalv2/common/presentation/components/atoms/form_section_header.dart';

class IzinFormSection extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final DateTime izinDate;
  final VoidCallback onSelectDate;
  final String? selectedIzinType;
  final ValueChanged<String?> onIzinTypeChanged;
  final List<Map<String, String>> izinTypes;
  final TextEditingController izinPurposeController;
  final Widget attachmentWidget;
  final Widget supervisorSelectorWidget;
  final bool isLoading;
  final VoidCallback onSubmit;

  const IzinFormSection({
    super.key,
    required this.formKey,
    required this.izinDate,
    required this.onSelectDate,
    required this.selectedIzinType,
    required this.onIzinTypeChanged,
    required this.izinTypes,
    required this.izinPurposeController,
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

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FormSectionHeader(title: 'TANGGAL IZIN'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onSelectDate,
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
                    formatDate(izinDate),
                    style: GoogleFonts.inter(fontSize: 13, color: onSurface, fontWeight: FontWeight.w500),
                  ),
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          const FormSectionHeader(title: 'JENIS IZIN'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedIzinType,
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
            hint: Text('-- Pilih Jenis Izin --', style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13)),
            items: izinTypes.map((type) {
              return DropdownMenuItem<String>(
                value: type['name'],
                child: Text(type['name']!),
              );
            }).toList(),
            onChanged: onIzinTypeChanged,
          ),
          const SizedBox(height: 20),

          const FormSectionHeader(title: 'ALASAN PENGAJUAN'),
          const SizedBox(height: 8),
          TextFormField(
            controller: izinPurposeController,
            maxLines: 4,
            style: GoogleFonts.inter(fontSize: 14, color: onSurface),
            decoration: InputDecoration(
              hintText: 'Tuliskan alasan lengkap pengajuan izin Anda di sini...',
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
                        'Kirim Pengajuan Izin',
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
