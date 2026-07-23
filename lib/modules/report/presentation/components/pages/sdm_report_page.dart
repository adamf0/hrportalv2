import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:hrportalv2/core/api_client.dart';
import 'package:hrportalv2/core/app_theme.dart';
import 'package:hrportalv2/core/sso_helper.dart';
import 'package:hrportalv2/modules/auth/presentation/auth_bloc.dart';
import 'package:hrportalv2/modules/auth/presentation/components/pages/login_page.dart';
import '../../report_bloc.dart';
import '../../../domain/report_domain.dart';

class SdmReportPage extends StatefulWidget {
  const SdmReportPage({super.key});

  @override
  State<SdmReportPage> createState() => _SdmReportPageState();
}

class _SdmReportPageState extends State<SdmReportPage> {
  final ScrollController _horizontalScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  bool _isExporting = false;
  int _exportProgress = 0;

  final List<String> _monthNames = [
    "Januari",
    "Februari",
    "Maret",
    "April",
    "Mei",
    "Juni",
    "Juli",
    "Agustus",
    "September",
    "Oktober",
    "November",
    "Desember"
  ];

  final List<int> _years = [2023, 2024, 2025, 2026, 2027];

  @override
  void initState() {
    super.initState();
    ApiClient.setActivePageScope('sdm_report');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportBloc>().fetchReportData();
    });
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _twoDigits(int n) => n >= 10 ? "$n" : "0$n";

  String _formatDateKey(DateTime dt) {
    return "${dt.year}-${_twoDigits(dt.month)}-${_twoDigits(dt.day)}";
  }

  /// Request Background Export Job (Hangfire Architecture with UUIDv4 Queue)
  Future<void> _triggerExportExcel(ReportPeriodFilter filter) async {
    final startStr = _formatDateKey(filter.startDate);
    final endStr = _formatDateKey(filter.endDate);

    setState(() {
      _isExporting = true;
      _exportProgress = 5;
    });

    try {
      final res = await ApiClient.get(
        Uri.parse(
            "${ApiClient.baseUrl}/api/laporan/export/request?tanggal_mulai=$startStr&tanggal_akhir=$endStr"),
      );

      if (res is Map<String, dynamic> && res['task_id'] != null) {
        final taskId = res['task_id'].toString();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.cloud_upload_outlined,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '[Laporan SDM] Task Export #${taskId.substring(0, 8)} dimasukkan ke antrean background.',
                    style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.blue[800],
            duration: const Duration(seconds: 4),
          ),
        );

        // Start background polling loop
        _pollExportStatus(taskId);
      } else {
        throw Exception("Gagal memulai task background export");
      }
    } catch (e) {
      setState(() {
        _isExporting = false;
      });
      ApiClient.showToast("Export Gagal: ${e.toString()}", scope: 'sdm_report');
    }
  }

  void _pollExportStatus(String taskId) {
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      try {
        final res = await ApiClient.get(
          Uri.parse("${ApiClient.baseUrl}/api/laporan/export/status/$taskId"),
        );

        if (res is Map<String, dynamic>) {
          final status = res['status']?.toString() ?? 'pending';
          final progress = (res['progress'] as num?)?.toInt() ?? 0;

          setState(() {
            _exportProgress = progress;
          });

          if (status == 'completed') {
            timer.cancel();
            setState(() {
              _isExporting = false;
            });

            final downloadUrl = "${ApiClient.baseUrl}${res['download_url']}";
            _downloadAndOpenFile(downloadUrl, taskId);
          } else if (status == 'failed') {
            timer.cancel();
            setState(() {
              _isExporting = false;
            });
            final err = res['error_message']?.toString() ??
                'Gagal memproses file export';
            ApiClient.showToast("Gagal memproses export: $err",
                scope: 'sdm_report');
          }
        }
      } catch (e) {
        timer.cancel();
        setState(() {
          _isExporting = false;
        });
      }
    });
  }

  Future<void> _downloadAndOpenFile(String downloadUrl, String taskId) async {
    try {
      final session = await SsoHelper.getSession();
      final headers = <String, String>{};
      if (session != null && session['token'] != null) {
        final token = session['token'].toString();
        if (token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
      }

      final response = await http.get(Uri.parse(downloadUrl), headers: headers);
      if (response.statusCode == 200) {
        Directory? dir;
        try {
          dir = await getTemporaryDirectory();
        } catch (_) {
          dir = await getApplicationDocumentsDirectory();
        }

        final shortId = taskId.length >= 8 ? taskId.substring(0, 8) : taskId;
        final filePath = '${dir.path}/Laporan_Presensi_$shortId.csv';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '[Laporan SDM] File Excel berhasil di-download!',
              style:
                  GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            backgroundColor: Colors.green[800],
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'BUKA FILE',
              textColor: Colors.white,
              onPressed: () {
                _openExportedFile(filePath);
              },
            ),
          ),
        );

        _openExportedFile(filePath);
      } else {
        throw Exception("Server status ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        ApiClient.showToast("Gagal men-download file export: $e",
            scope: 'sdm_report');
      }
    }
  }

  Future<void> _openExportedFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        if (mounted) {
          ApiClient.showToast("File export tidak ditemukan.", scope: 'sdm_report');
        }
        return;
      }

      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        debugPrint('[OpenFilex result]: ${result.type} - ${result.message}');
        if (mounted) {
          _showExportPreviewModal(filePath);
        }
      }
    } catch (e) {
      debugPrint('[OpenFilex Exception]: $e');
      if (mounted) {
        _showExportPreviewModal(filePath);
      }
    }
  }

  void _showExportPreviewModal(String filePath) {
    int activePreviewTab = 0; // 0: Tab 01-31, 1: Tab 15-15, 2: Presensi Upacara

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final reportBloc = Provider.of<ReportBloc>(context, listen: false);
        final employees = reportBloc.employees;
        final filter = reportBloc.filter;
        final primaryColor = Theme.of(context).colorScheme.primary;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.85,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.table_chart,
                              color: Colors.green, size: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Preview File Export (Excel)',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      Text(
                        'Tersimpan di: ${filePath.split('/').last}',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 12),
                      // 3 Preview Sheet Tabs
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setModalState(() => activePreviewTab = 0),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: activePreviewTab == 0
                                        ? primaryColor
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Tab 01 - 31',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: activePreviewTab == 0
                                          ? Colors.white
                                          : Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setModalState(() => activePreviewTab = 1),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: activePreviewTab == 1
                                        ? primaryColor
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Tab 15 - 15',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: activePreviewTab == 1
                                          ? Colors.white
                                          : Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setModalState(() => activePreviewTab = 2),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: activePreviewTab == 2
                                        ? primaryColor
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Presensi Upacara',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: activePreviewTab == 2
                                          ? Colors.white
                                          : Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _buildPreviewSheetTable(
                          scrollController,
                          activeTab: activePreviewTab,
                          filter: filter,
                          employees: employees,
                          matrix: reportBloc.matrix,
                          totalPresensi: reportBloc.totalPresensi,
                          holidays: reportBloc.holidays,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPreviewSheetTable(
    ScrollController scrollController, {
    required int activeTab,
    required ReportPeriodFilter filter,
    required List<PegawaiReportItem> employees,
    required Map<String, Map<String, ReportCellData>> matrix,
    required Map<String, int> totalPresensi,
    required Set<String> holidays,
  }) {
    List<String> headers = [];
    List<List<String>> rows = [];

    if (activeTab == 0) {
      // Tab 01-31 (Calendar)
      final calStart = DateTime(filter.year, filter.month, 1);
      final calEnd = DateTime(filter.year, filter.month + 1, 0);
      final dates = <DateTime>[];
      for (var d = calStart;
          !d.isAfter(calEnd);
          d = DateTime(d.year, d.month, d.day + 1)) {
        dates.add(d);
      }

      headers = [
        'No',
        'NIP',
        'NIDN',
        'Nama Pegawai',
        'Unit Kerja',
        'Total Presensi'
      ];
      for (var dt in dates) {
        headers.add("${_twoDigits(dt.day)}/${_twoDigits(dt.month)}");
      }

      for (int i = 0; i < employees.length && i < 50; i++) {
        final emp = employees[i];
        final empId = emp.primaryId;
        final tot = totalPresensi[empId] ?? 0;
        final row = [
          '${i + 1}',
          emp.nip.isNotEmpty ? emp.nip : '-',
          emp.nidn.isNotEmpty ? emp.nidn : '-',
          emp.nama,
          emp.unitKerja,
          '$tot',
        ];

        for (var dt in dates) {
          final dKey = _formatDateKey(dt);
          final cell = matrix[empId]?[dKey];
          row.add(cell?.text ??
              (dt.weekday == DateTime.sunday || holidays.contains(dKey)
                  ? 'Libur'
                  : 'Alpa'));
        }
        rows.add(row);
      }
    } else if (activeTab == 1) {
      // Tab 15-15 (Cutoff: 15th prev month to 15th curr month)
      final cutStart = DateTime(filter.year, filter.month - 1, 15);
      final cutEnd = DateTime(filter.year, filter.month, 15);
      final dates = <DateTime>[];
      for (var d = cutStart;
          !d.isAfter(cutEnd);
          d = DateTime(d.year, d.month, d.day + 1)) {
        dates.add(d);
      }

      headers = [
        'No',
        'NIP',
        'NIDN',
        'Nama Pegawai',
        'Unit Kerja',
        'Total Presensi'
      ];
      for (var dt in dates) {
        headers.add("${_twoDigits(dt.day)}/${_twoDigits(dt.month)}");
      }

      for (int i = 0; i < employees.length && i < 50; i++) {
        final emp = employees[i];
        final empId = emp.primaryId;
        final tot = totalPresensi[empId] ?? 0;
        final row = [
          '${i + 1}',
          emp.nip.isNotEmpty ? emp.nip : '-',
          emp.nidn.isNotEmpty ? emp.nidn : '-',
          emp.nama,
          emp.unitKerja,
          '$tot',
        ];

        for (var dt in dates) {
          final dKey = _formatDateKey(dt);
          final cell = matrix[empId]?[dKey];
          row.add(cell?.text ??
              (dt.weekday == DateTime.sunday || holidays.contains(dKey)
                  ? 'Libur'
                  : 'Alpa'));
        }
        rows.add(row);
      }
    } else {
      // Tab Presensi Upacara
      headers = [
        'No',
        'NIP',
        'NIDN',
        'Nama Pegawai',
        'Unit Kerja',
        'Total Upacara',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des'
      ];

      for (int i = 0; i < employees.length && i < 50; i++) {
        final emp = employees[i];
        final empId = emp.primaryId;

        int totalUpacara = 0;
        final monthVals = <String>[];

        for (int m = 1; m <= 12; m++) {
          final mKey = "${filter.year}-${_twoDigits(m)}-01";
          final cell = matrix[empId]?[mKey];
          final val = int.tryParse(cell?.text ?? '0') ?? 0;
          totalUpacara += val;
          monthVals.add('$val');
        }

        final row = [
          '${i + 1}',
          emp.nip.isNotEmpty ? emp.nip : '-',
          emp.nidn.isNotEmpty ? emp.nidn : '-',
          emp.nama,
          emp.unitKerja,
          '$totalUpacara',
          ...monthVals,
        ];
        rows.add(row);
      }
    }

    return SingleChildScrollView(
      controller: scrollController,
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.blue[50]),
          columns: headers
              .map((h) => DataColumn(
                    label: Text(
                      h,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ))
              .toList(),
          rows: rows
              .map((r) => DataRow(
                    cells: r
                        .map((c) => DataCell(
                              Text(c, style: GoogleFonts.inter(fontSize: 11)),
                            ))
                        .toList(),
                  ))
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authBloc = Provider.of<AuthBloc>(context);
    final reportBloc = Provider.of<ReportBloc>(context);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    if (!authBloc.isSdmUser) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Laporan',
              style:
                  GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 64, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  'Akses Terbatas',
                  style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: onSurface),
                ),
                const SizedBox(height: 8),
                Text(
                  'Halaman Laporan Presensi Matrix ini khusus diperuntukkan bagi pengguna dengan role/group SDM.',
                  style:
                      GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: Text('Kembali',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final filter = reportBloc.filter;
    final dateList = filter.dateList;
    final employees = reportBloc.employees;
    final matrix = reportBloc.matrix;
    final totalPresensi = reportBloc.totalPresensi;

    // Flexible Multiple Keyword Search (coma/space separated names, NIPs, NIDNs)
    final filteredEmployees = employees.where((emp) {
      if (_searchQuery.trim().isEmpty) return true;

      final tokens = _searchQuery
          .toLowerCase()
          .split(RegExp(r'[,;]|\s+'))
          .where((s) => s.isNotEmpty);
      for (var token in tokens) {
        final nameMatch = emp.nama.toLowerCase().contains(token);
        final nipMatch = emp.nip.toLowerCase().contains(token);
        final nidnMatch = emp.nidn.toLowerCase().contains(token);

        if (nameMatch || nipMatch || nidnMatch) {
          return true;
        }
      }
      return false;
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: Navigator.canPop(context),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[200]!, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Image.asset(
                  'asset_app/logo-transparent.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      'Halo, ${authBloc.session?.name ?? "User"}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (reportBloc.isStreaming) ...[
                    const SizedBox(width: 6),
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.amber),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, size: 24, color: primaryColor),
            tooltip: 'Refresh Data',
            onPressed: () => reportBloc.fetchReportData(),
          ),
          IconButton(
            icon: Icon(Icons.notifications_none_outlined,
                size: 24, color: primaryColor),
            tooltip: 'Notifikasi',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Tidak ada notifikasi baru',
                      style: GoogleFonts.inter()),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 24, color: Color(0xFFFF4D4F)),
            tooltip: 'Keluar',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('Konfirmasi Logout',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  content: Text('Apakah Anda yakin ingin keluar dari aplikasi?',
                      style: GoogleFonts.inter()),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white),
                      child: const Text('Keluar'),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                await authBloc.logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                }
              }
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Filter Card Header
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    // Month Selector
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: filter.periodType == ReportPeriodType.annual
                              ? Colors.grey[200]
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: filter.periodType == ReportPeriodType.annual
                                ? 0
                                : filter.month,
                            isExpanded: true,
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.black87,
                                fontWeight: FontWeight.bold),
                            items: filter.periodType == ReportPeriodType.annual
                                ? [
                                    DropdownMenuItem(
                                      value: 0,
                                      child: Text('Semua Bulan (Setahun)',
                                          style: GoogleFonts.inter(
                                              fontSize: 11,
                                              color: Colors.grey[700])),
                                    )
                                  ]
                                : List.generate(12, (index) {
                                    return DropdownMenuItem(
                                      value: index + 1,
                                      child: Text(_monthNames[index]),
                                    );
                                  }),
                            onChanged: filter.periodType ==
                                    ReportPeriodType.annual
                                ? null
                                : (val) {
                                    if (val != null) reportBloc.setMonth(val);
                                  },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Year Selector
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: filter.year,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.black87,
                              fontWeight: FontWeight.bold),
                          items: _years.map((y) {
                            return DropdownMenuItem(
                              value: y,
                              child: Text(y.toString()),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) reportBloc.setYear(val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Background Export Excel Button
                    ElevatedButton.icon(
                      onPressed: _isExporting
                          ? null
                          : () => _triggerExportExcel(filter),
                      icon: _isExporting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.file_download, size: 16),
                      label: Text(
                        _isExporting ? '$_exportProgress%' : 'Export Excel',
                        style: GoogleFonts.inter(
                            fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Multiple Search Input Field (Nama / NIP / NIDN)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    style:
                        GoogleFonts.inter(fontSize: 12, color: Colors.black87),
                    decoration: InputDecoration(
                      icon: const Icon(Icons.search,
                          size: 18, color: Colors.grey),
                      hintText: 'Cari Nama / NIP / NIDN (bisa dipisah koma)...',
                      hintStyle:
                          GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                              child: const Icon(Icons.clear,
                                  size: 16, color: Colors.grey),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Period Tabs (01-31 Kalender vs 15-15 Cutoff vs Tahunan Setahun)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => reportBloc
                              .setPeriodType(ReportPeriodType.calendar),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color:
                                  filter.periodType == ReportPeriodType.calendar
                                      ? primaryColor
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Tab 01 - 31',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: filter.periodType ==
                                        ReportPeriodType.calendar
                                    ? Colors.white
                                    : Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              reportBloc.setPeriodType(ReportPeriodType.cutoff),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color:
                                  filter.periodType == ReportPeriodType.cutoff
                                      ? primaryColor
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Tab 15 - 15',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color:
                                    filter.periodType == ReportPeriodType.cutoff
                                        ? Colors.white
                                        : Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              reportBloc.setPeriodType(ReportPeriodType.annual),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color:
                                  filter.periodType == ReportPeriodType.annual
                                      ? primaryColor
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Presensi Upacara',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color:
                                    filter.periodType == ReportPeriodType.annual
                                        ? Colors.white
                                        : Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Menampilkan ${filteredEmployees.length} dari ${employees.length} pegawai',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: primaryColor),
                        ),
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                          child: Text(
                            'Bersihkan Pencarian',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Legend Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            color: Colors.grey[50],
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildLegendItem('Absen', const Color(0xFFD1E7DD),
                      const Color(0xFF0F5132)),
                  const SizedBox(width: 8),
                  _buildLegendItem('Absen Anomali (G/V)',
                      const Color(0xFFD1E7DD), const Color(0xFF0F5132),
                      borderColor: const Color(0xFFDC3545)),
                  const SizedBox(width: 8),
                  _buildLegendItem(
                      'Izin', const Color(0xFFFFF3CD), const Color(0xFF664D03)),
                  const SizedBox(width: 8),
                  _buildLegendItem(
                      'Cuti', const Color(0xFFFFE5D0), const Color(0xFF994D00)),
                  const SizedBox(width: 8),
                  _buildLegendItem(
                      'SPPD', const Color(0xEFE2D9F3), const Color(0xFF4A148C)),
                  const SizedBox(width: 8),
                  _buildLegendItem('Alpa/Libur/Minggu', const Color(0xFFF8D7DA),
                      const Color(0xFF842029)),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Main Table Area
          Expanded(
            child: reportBloc.isLoading
                ? const Center(child: CircularProgressIndicator())
                : reportBloc.errorMessage.isNotEmpty
                    ? Center(
                        child: Text(
                          reportBloc.errorMessage,
                          style: GoogleFonts.inter(color: Colors.red),
                        ),
                      )
                    : filteredEmployees.isEmpty
                        ? Center(
                            child: Text(
                              _searchQuery.isNotEmpty
                                  ? 'Tidak ada pegawai yang cocok dengan pencarian "$_searchQuery".'
                                  : 'Tidak ada data presensi pada periode ini.',
                              style: GoogleFonts.inter(color: Colors.grey[600]),
                            ),
                          )
                        : _buildVirtualizedMatrixTable(
                            context,
                            dateList: dateList,
                            employees: filteredEmployees,
                            matrix: matrix,
                            totalPresensi: totalPresensi,
                            holidays: reportBloc.holidays,
                            isAnnual:
                                filter.periodType == ReportPeriodType.annual,
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color bgColor, Color textColor,
      {Color? borderColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
            color: borderColor ?? Colors.transparent,
            width: borderColor != null ? 1.5 : 0),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
            fontSize: 10, fontWeight: FontWeight.bold, color: textColor),
      ),
    );
  }

  Widget _buildVirtualizedMatrixTable(
    BuildContext context, {
    required List<DateTime> dateList,
    required List<PegawaiReportItem> employees,
    required Map<String, Map<String, ReportCellData>> matrix,
    required Map<String, int> totalPresensi,
    required Set<String> holidays,
    bool isAnnual = false,
  }) {
    const double colWidthNo = 40.0;
    const double colWidthNip = 110.0;
    const double colWidthNidn = 110.0;
    const double colWidthNama = 140.0;
    const double colWidthUnit = 110.0;
    const double colWidthTotal = 60.0;
    const double colWidthDate = 80.0;

    final double totalDateWidth = dateList.length * colWidthDate;
    final List<String> dateStrList = dateList.map(_formatDateKey).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _horizontalScrollController,
      child: SizedBox(
        width: colWidthNo +
            colWidthNip +
            colWidthNidn +
            colWidthNama +
            colWidthUnit +
            colWidthTotal +
            totalDateWidth,
        child: Column(
          children: [
            // Table Header Row
            Container(
              height: 40,
              color: AppTheme.primary,
              child: Row(
                children: [
                  _buildHeaderCell('No', colWidthNo),
                  _buildHeaderCell('NIP', colWidthNip),
                  _buildHeaderCell('NIDN', colWidthNidn),
                  _buildHeaderCell('Nama', colWidthNama),
                  _buildHeaderCell('Unit', colWidthUnit),
                  _buildHeaderCell(isAnnual ? 'Total' : 'Total', colWidthTotal),
                  ...dateList.asMap().entries.map((entry) {
                    final index = entry.key;
                    final dt = entry.value;
                    final dateStr = dateStrList[index];
                    final isSunday = dt.weekday == DateTime.sunday;
                    final isHoliday = holidays.contains(dateStr);
                    final isRed = !isAnnual && (isSunday || isHoliday);
                    final headerTitle = isAnnual
                        ? _monthNames[dt.month - 1].substring(0, 3)
                        : "${_twoDigits(dt.day)}/${_twoDigits(dt.month)}";

                    return Container(
                      width: colWidthDate,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isRed ? Colors.red[700] : AppTheme.primary,
                        border: Border(
                            right: BorderSide(
                                color: Colors.white.withOpacity(0.2))),
                      ),
                      child: Text(
                        headerTitle,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            // Virtualized Rows using ListView.builder to conserve memory
            Expanded(
              child: ListView.builder(
                itemCount: employees.length,
                itemExtent:
                    44, // Fixed height per row for maximum scroll rendering performance
                itemBuilder: (context, index) {
                  final emp = employees[index];
                  final empId = emp.primaryId;
                  final total = totalPresensi[empId] ?? 0;
                  final isEven = index % 2 == 0;
                  final nipVal = emp.nip.isNotEmpty ? emp.nip : '-';
                  final nidnVal = emp.nidn.isNotEmpty ? emp.nidn : '-';

                  return Container(
                    height: 44,
                    color: isEven ? Colors.white : Colors.grey[50],
                    child: Row(
                      children: [
                        _buildDataCell('${index + 1}', colWidthNo,
                            isCenter: true),
                        _buildDataCell(nipVal, colWidthNip),
                        _buildDataCell(nidnVal, colWidthNidn),
                        _buildDataCell(emp.nama, colWidthNama, isBold: true),
                        _buildDataCell(emp.unitKerja, colWidthUnit),
                        _buildDataCell('$total', colWidthTotal,
                            isCenter: true, isBold: true),
                        ...dateStrList.map((dateStr) {
                          final cellData = matrix[empId]?[dateStr];
                          return _buildMatrixDataCell(cellData, colWidthDate);
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String title, double width) {
    return Container(
      width: width,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: Colors.white.withOpacity(0.2))),
      ),
      child: Text(
        title,
        style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Widget _buildDataCell(String text, double width,
      {bool isCenter = false, bool isBold = false}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: isCenter ? Alignment.center : Alignment.centerLeft,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey[300]!),
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildMatrixDataCell(ReportCellData? data, double width) {
    if (data == null) {
      return Container(
        width: width,
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: Colors.grey[300]!),
            bottom: BorderSide(color: Colors.grey[200]!),
          ),
        ),
      );
    }

    Color bgColor = Colors.white;
    Color textColor = Colors.black;
    Color? borderColor;

    switch (data.status) {
      case ReportCellStatus.absen:
        bgColor = const Color(0xFFD1E7DD);
        textColor = const Color(0xFF0F5132);
        break;
      case ReportCellStatus.absenAnomaly:
        bgColor = const Color(0xFFD1E7DD);
        textColor = const Color(0xFF0F5132);
        borderColor = const Color(0xFFDC3545);
        break;
      case ReportCellStatus.izin:
        bgColor = const Color(0xFFFFF3CD);
        textColor = const Color(0xFF664D03);
        break;
      case ReportCellStatus.cuti:
        bgColor = const Color(0xFFFFE5D0);
        textColor = const Color(0xFF994D00);
        break;
      case ReportCellStatus.sppd:
        bgColor = const Color(0xEFE2D9F3);
        textColor = const Color(0xFF4A148C);
        break;
      case ReportCellStatus.tidakMasuk:
        bgColor = const Color(0xFFF8D7DA);
        textColor = const Color(0xFF842029);
        break;
      case ReportCellStatus.libur:
      case ReportCellStatus.minggu:
        bgColor = const Color(0xFFF8D7DA);
        textColor = const Color(0xFF842029);
        break;
    }

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(
          color: borderColor ?? Colors.grey[300]!,
          width: borderColor != null ? 1.5 : 0.5,
        ),
      ),
      child: Text(
        data.text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
