import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrportalv2/modules/auth/presentation/auth_bloc.dart';
import 'package:hrportalv2/modules/attendance/presentation/attendance_bloc.dart';
import 'package:hrportalv2/modules/auth/domain/auth.dart';
import 'package:hrportalv2/modules/leave/presentation/leave_bloc.dart';
import 'package:hrportalv2/modules/leave/domain/leave.dart';
import 'package:hrportalv2/modules/leave/domain/leave_status.dart';
import 'package:hrportalv2/modules/leave/domain/leave_category.dart';
import 'package:hrportalv2/core/api_client.dart';
import 'leave_form_page.dart';
import 'package:hrportalv2/modules/report/presentation/components/pages/sdm_report_page.dart';
import 'package:hrportalv2/modules/leave/presentation/components/organisms/request_card.dart';
import 'package:hrportalv2/modules/leave/presentation/components/organisms/status_filter_sheet.dart';

class LeaveListPage extends StatefulWidget {
  const LeaveListPage({super.key});

  @override
  State<LeaveListPage> createState() => _LeaveListPageState();
}

class _LeaveListPageState extends State<LeaveListPage> {
  int _activeTab = 0; // 0 = Pengajuan Saya, 1 = Verifikasi Saya
  String _selectedFilter = 'Semua';
  String _selectedStatusFilter = 'Semua Status';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filters = [
    'Semua',
    'Cuti',
    'Izin',
    'SPPD',
  ];

  final List<String> _statusFilters = [
    'Semua Status',
    'Pengajuan',
    'Terima Atasan',
    'Terima SDM',
    'Tolak Atasan',
    'Tolak SDM',
  ];

  int? _previousTabIndex;

  @override
  void initState() {
    super.initState();
    ApiClient.setActivePageScope('requests');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaveBloc>().fetchLeaves();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final attendanceBloc = Provider.of<AttendanceBloc>(context);
    final currentIndex = attendanceBloc.currentTabIndex;
    if (_previousTabIndex != null &&
        _previousTabIndex != 2 &&
        currentIndex == 2) {
      ApiClient.setActivePageScope('requests');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<LeaveBloc>().fetchLeaves();
      });
    }
    _previousTabIndex = currentIndex;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatIndonesianDate(DateTime date) {
    const days = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu'
    ];
    const months = [
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
      'Desember'
    ];
    final dayName = days[date.weekday % 7];
    final monthName = months[date.month - 1];
    return "$dayName, ${date.day} $monthName ${date.year}";
  }

  void _handleApprove(BuildContext context, LeaveBloc bloc,
      AuthSession? session, LeaveRequest req) {
    final isSdm = session?.isSdm ?? false;
    final targetStatus = isSdm ? 'terima sdm' : 'terima atasan';

    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Verifikasi (ACC)',
            style:
                GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Apakah Anda yakin ingin menyetujui pengajuan "${req.type}" ini?',
                style: GoogleFonts.inter(fontSize: 13)),
            const SizedBox(height: 12),
            TextFormField(
              controller: noteController,
              style: GoogleFonts.inter(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Catatan (opsional)...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await bloc.updateStatus(req.id, targetStatus,
                  note: noteController.text.trim());
              if (ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Pengajuan berhasil disetujui!')),
                );
              }
            },
            child: const Text('Setujui (ACC)'),
          ),
        ],
      ),
    );
  }

  void _handleReject(BuildContext context, LeaveBloc bloc, AuthSession? session,
      LeaveRequest req) {
    final isSdm = session?.isSdm ?? false;
    final targetStatus = isSdm ? 'tolak sdm' : 'tolak atasan';
    debugPrint("isSdm: $isSdm");

    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Tolak Pengajuan',
            style:
                GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Masukkan alasan penolakan pengajuan "${req.type}":',
                style: GoogleFonts.inter(fontSize: 13)),
            const SizedBox(height: 12),
            TextFormField(
              controller: noteController,
              style: GoogleFonts.inter(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Alasan penolakan...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white),
            onPressed: () async {
              if (noteController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Harap isi alasan penolakan.')),
                );
                return;
              }
              Navigator.pop(ctx);
              final ok = await bloc.updateStatus(req.id, targetStatus,
                  note: noteController.text.trim());
              if (ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pengajuan berhasil ditolak.')),
                );
              }
            },
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final leaveBloc = Provider.of<LeaveBloc>(context);
    final authBloc = Provider.of<AuthBloc>(context, listen: false);

    final primaryColor = Theme.of(context).colorScheme.primary;
    final background = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    final List<LeaveRequest> sourceRequests =
        _activeTab == 0 ? leaveBloc.leaves : leaveBloc.verificationLeaves;

    final selectedCategory = LeaveCategory.fromString(_selectedFilter);
    List<LeaveRequest> filteredRequests = sourceRequests
        .where((req) => selectedCategory.matches(req.type))
        .toList();

    if (_selectedStatusFilter != 'Semua Status') {
      final targetStatus = LeaveRequestStatus.fromString(_selectedStatusFilter);
      filteredRequests = filteredRequests
          .where((req) =>
              LeaveRequestStatus.fromString(req.status) == targetStatus)
          .toList();
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filteredRequests = filteredRequests.where((req) {
        final type = req.type.toLowerCase();
        final details = req.details.toLowerCase();
        final note = req.note.toLowerCase();
        return type.contains(query) ||
            details.contains(query) ||
            note.contains(query);
      }).toList();
    }

    filteredRequests.sort((a, b) => b.startDate.compareTo(a.startDate));

    final Map<DateTime, List<LeaveRequest>> groupedRequests = {};
    final List<DateTime> sortedDates = [];
    if (_selectedFilter == 'Semua') {
      for (final req in filteredRequests) {
        final dateMidnight = DateTime(
            req.startDate.year, req.startDate.month, req.startDate.day);
        if (!groupedRequests.containsKey(dateMidnight)) {
          groupedRequests[dateMidnight] = [];
          sortedDates.add(dateMidnight);
        }
        groupedRequests[dateMidnight]!.add(req);
      }
      sortedDates.sort((a, b) => b.compareTo(a));
    }

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'HR PORTAL',
                            style: GoogleFonts.inter(
                              fontSize: 18,
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
                            child: Icon(Icons.notifications_none,
                                color: onSurface, size: 22),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pusat Pengajuan',
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: onSurface,
                            ),
                          ),
                          if (authBloc.isSdmUser)
                            IconButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const SdmReportPage()),
                              ),
                              tooltip: 'Laporan Presensi SDM',
                              icon: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.analytics_outlined,
                                    color: primaryColor, size: 20),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kelola dan pantau status cuti, izin, dan SPPD Anda di satu tempat.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _activeTab = 0),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: _activeTab == 0
                                          ? primaryColor
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Pengajuan Saya',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: _activeTab == 0
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: _activeTab == 0
                                        ? primaryColor
                                        : onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _activeTab = 1);
                                leaveBloc.fetchVerificationLeaves();
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: _activeTab == 1
                                          ? primaryColor
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Verifikasi Saya',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: _activeTab == 1
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: _activeTab == 1
                                            ? primaryColor
                                            : onSurfaceVariant,
                                      ),
                                    ),
                                    if (leaveBloc
                                        .verificationLeaves.isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.red[600],
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '${leaveBloc.verificationLeaves.length}',
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 10.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _searchController,
                          style: GoogleFonts.inter(fontSize: 13),
                          decoration: InputDecoration(
                            hintText:
                                'Cari berdasarkan tipe, tujuan, atau atasan...',
                            hintStyle: GoogleFonts.inter(
                                color: Colors.grey[400], fontSize: 13),
                            prefixIcon: const Icon(Icons.search,
                                size: 18, color: Colors.grey),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                      });
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey[200]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  BorderSide(color: primaryColor, width: 1.5),
                            ),
                          ),
                          onChanged: (val) {
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            onPressed: () => _showStatusFilterSelector(context),
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  _selectedStatusFilter != 'Semua Status'
                                      ? primaryColor.withOpacity(0.08)
                                      : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: _selectedStatusFilter != 'Semua Status'
                                      ? primaryColor
                                      : Colors.grey[200]!,
                                  width: _selectedStatusFilter != 'Semua Status'
                                      ? 1.5
                                      : 1.0,
                                ),
                              ),
                              padding: const EdgeInsets.all(12),
                            ),
                            icon: Icon(Icons.tune, color: primaryColor),
                          ),
                          if (_selectedStatusFilter != 'Semua Status')
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.red[600],
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 6.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters.map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(
                              filter,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : onSurfaceVariant,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: primaryColor,
                            backgroundColor: Colors.white,
                            elevation: 0,
                            pressElevation: 0,
                            side: BorderSide(
                              color: isSelected
                                  ? Colors.transparent
                                  : Colors.grey[200]!,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedFilter = filter;
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await leaveBloc.fetchLeaves(isRefresh: true);
                    },
                    color: primaryColor,
                    child: leaveBloc.isLoading
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.6,
                                child: Center(
                                    child: CircularProgressIndicator(
                                        color: primaryColor)),
                              )
                            ],
                          )
                        : filteredRequests.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.6,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.assignment_late_outlined,
                                            size: 48, color: Colors.grey[300]),
                                        const SizedBox(height: 12),
                                        Text(
                                          _activeTab == 0
                                              ? 'Tidak ada data pengajuan'
                                              : 'Tidak ada pengajuan yang membutuhkan verifikasi Anda',
                                          style: GoogleFonts.inter(
                                              color: Colors.grey,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(20.0),
                                children: _selectedFilter == 'Semua'
                                    ? sortedDates.map((date) {
                                        final items =
                                            groupedRequests[date] ?? [];
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 12.0, top: 8.0),
                                              child: Text(
                                                _formatIndonesianDate(date),
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: onSurfaceVariant,
                                                ),
                                              ),
                                            ),
                                            ...items.map((req) => RequestCard(
                                                  req: req,
                                                  onApprove: _activeTab == 1
                                                      ? () => _handleApprove(
                                                          context,
                                                          leaveBloc,
                                                          authBloc.session,
                                                          req)
                                                      : null,
                                                  onReject: _activeTab == 1
                                                      ? () => _handleReject(
                                                          context,
                                                          leaveBloc,
                                                          authBloc.session,
                                                          req)
                                                      : null,
                                                )),
                                          ],
                                        );
                                      }).toList()
                                    : filteredRequests
                                        .map((req) => RequestCard(
                                              req: req,
                                              onApprove: _activeTab == 1
                                                  ? () => _handleApprove(
                                                      context,
                                                      leaveBloc,
                                                      authBloc.session,
                                                      req)
                                                  : null,
                                              onReject: _activeTab == 1
                                                  ? () => _handleReject(
                                                      context,
                                                      leaveBloc,
                                                      authBloc.session,
                                                      req)
                                                  : null,
                                            ))
                                        .toList(),
                              ),
                  ),
                ),
              ],
            ),
            if (_activeTab == 0)
              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LeaveFormPage()),
                    ).then((_) {
                      leaveBloc.fetchLeaves();
                    });
                  },
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  icon: const Icon(Icons.add, size: 20),
                  label: Text(
                    'Buat Pengajuan',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showStatusFilterSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatusFilterSheet(
          statusFilters: _statusFilters,
          selectedStatusFilter: _selectedStatusFilter,
          onStatusSelected: (statusName) {
            setState(() {
              _selectedStatusFilter = statusName;
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }
}
