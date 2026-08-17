import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:hrportalv2/core/app_theme.dart';
import 'package:hrportalv2/core/presentation/components/atoms/pulsing_skeleton.dart';
import 'package:hrportalv2/modules/attendance/presentation/attendance_bloc.dart';

class CeremonyAttendanceListPage extends StatefulWidget {
  const CeremonyAttendanceListPage({super.key});

  @override
  State<CeremonyAttendanceListPage> createState() => _CeremonyAttendanceListPageState();
}

class _CeremonyAttendanceListPageState extends State<CeremonyAttendanceListPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<AttendanceBloc>().fetchCeremonyAttendances();
      }
    });
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return "Senin";
      case 2: return "Selasa";
      case 3: return "Rabu";
      case 4: return "Kamis";
      case 5: return "Jumat";
      case 6: return "Sabtu";
      case 7: return "Minggu";
      default: return "";
    }
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1: return "Januari";
      case 2: return "Februari";
      case 3: return "Maret";
      case 4: return "April";
      case 5: return "Mei";
      case 6: return "Juni";
      case 7: return "Juli";
      case 8: return "Agustus";
      case 9: return "September";
      case 10: return "Oktober";
      case 11: return "November";
      case 12: return "Desember";
      default: return "";
    }
  }

  DateTime _parseDateOnly(String dateStr) {
    if (dateStr.isEmpty) return DateTime.now();
    final cleanStr = dateStr.split('T')[0].trim();
    final parts = cleanStr.split('-');
    if (parts.length == 3) {
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final day = int.tryParse(parts[2]);
      if (year != null && month != null && day != null) {
        return DateTime(year, month, day);
      }
    }
    return DateTime.tryParse(dateStr)?.toLocal() ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.secondary;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Daftar Absen Upacara',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: onSurface,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<AttendanceBloc>().fetchCeremonyAttendances();
        },
        child: Consumer<AttendanceBloc>(
          builder: (context, bloc, child) {
            if (bloc.isCeremonyLoading) {
              return Column(
                children: [
                  LinearProgressIndicator(
                    color: primaryColor,
                    backgroundColor: primaryColor.withOpacity(0.1),
                    minHeight: 3,
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: 4,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return const PulsingSkeleton(
                          width: double.infinity,
                          height: 74,
                          borderRadius: 16,
                        );
                      },
                    ),
                  ),
                ],
              );
            }

            final items = bloc.ceremonyAttendances;

            if (items.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.assistant_photo_outlined,
                            size: 64,
                            color: primaryColor.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum Ada Data Upacara',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Anda belum memiliki riwayat presensi upacara.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            // Sort by date descending
            final sortedItems = List.from(items)
              ..sort((a, b) {
                final dateA = _parseDateOnly(a.tanggal);
                final dateB = _parseDateOnly(b.tanggal);
                return dateB.compareTo(dateA);
              });

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              itemCount: sortedItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final upacara = sortedItems[index];
                final date = _parseDateOnly(upacara.tanggal);
                final dayName = _getDayName(date.weekday);
                final monthName = _getMonthName(date.month);
                final dateFormatted = "${date.day} $monthName ${date.year}";

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: AppTheme.successContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: AppTheme.success,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Presensi Upacara Berhasil',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$dayName, $dateFormatted',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Jam: 07:00 WIB',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: onSurfaceVariant.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.successContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'HADIR',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
