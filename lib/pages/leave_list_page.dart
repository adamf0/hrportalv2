import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../state/app_state.dart';
import '../core/responsive_helper.dart';
import 'leave_form_page.dart';

class LeaveListPage extends StatefulWidget {
  const LeaveListPage({super.key});

  @override
  State<LeaveListPage> createState() => _LeaveListPageState();
}

class _LeaveListPageState extends State<LeaveListPage> {
  String _selectedFilter = 'Semua';
  String _selectedStatusFilter = 'Semua Status';
  final _searchController = TextEditingController();

  final List<String> _filters = [
    'Semua',
    'Cuti',
    'Izin',
    'SPPD',
  ];

  final List<String> _statusFilters = [
    'Semua Status',
    'Pengajuan',
    'Di ACC Atasan',
    'ACC SDM',
    'Tolak Atasan',
    'Tolak SDM',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatIndonesianDate(DateTime date) {
    const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final dayName = days[date.weekday % 7];
    final monthName = months[date.month - 1];
    return "$dayName, ${date.day} $monthName ${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    // Theme Colors
    const primaryColor = Color(0xFF003D9B);
    const background = Color(0xFFF8F9FB);
    const onSurface = Color(0xFF191C1E);
    const onSurfaceVariant = Color(0xFF434654);

    // Combine active and history requests for unified filtering
    final List<LeaveRequest> allRequests = [
      ...appState.activeRequests,
      ...appState.historyRequests,
    ];

    // Filter by Tab: Semua, Cuti, Izin, SPPD
    List<LeaveRequest> filteredRequests = allRequests;
    if (_selectedFilter == 'Cuti') {
      filteredRequests = allRequests.where((req) => req.type.toLowerCase().contains('cuti')).toList();
    } else if (_selectedFilter == 'Izin') {
      filteredRequests = allRequests.where((req) => req.type.toLowerCase().contains('izin')).toList();
    } else if (_selectedFilter == 'SPPD') {
      filteredRequests = allRequests.where((req) => 
        req.type.toLowerCase().contains('sppd') || 
        req.type.toLowerCase().contains('dinas') ||
        req.type.toLowerCase().contains('perjalanan')
      ).toList();
    }

    // Filter by Status: Semua Status, Pengajuan, Di ACC Atasan, ACC SDM, Tolak Atasan, Tolak SDM
    if (_selectedStatusFilter != 'Semua Status') {
      filteredRequests = filteredRequests.where((req) => req.status.toLowerCase() == _selectedStatusFilter.toLowerCase()).toList();
    }

    // Filter by Search Query
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filteredRequests = filteredRequests.where((req) {
        final type = req.type.toLowerCase();
        final details = req.details.toLowerCase();
        final note = req.note.toLowerCase();
        return type.contains(query) || details.contains(query) || note.contains(query);
      }).toList();
    }

    // Sort requests by date (newest first)
    filteredRequests.sort((a, b) => b.startDate.compareTo(a.startDate));



    // Grouping by Date for "Semua" tab
    final Map<DateTime, List<LeaveRequest>> groupedRequests = {};
    final List<DateTime> sortedDates = [];
    if (_selectedFilter == 'Semua') {
      for (final req in filteredRequests) {
        final dateMidnight = DateTime(req.startDate.year, req.startDate.month, req.startDate.day);
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
                // Top Header Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'HR Connect',
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
                            child: const Icon(Icons.notifications_none, color: onSurface, size: 22),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Pusat Pengajuan',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kelola dan pantau status cuti, izin, dan SPPD Anda di satu tempat.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),



                // Search Bar Input
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _searchController,
                          style: GoogleFonts.inter(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Cari berdasarkan tipe, tujuan, atau atasan...',
                            hintStyle: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13),
                            prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
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
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[200]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[200]!),
                            ),
                          ),
                          onChanged: (text) {
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: _selectedStatusFilter != 'Semua Status' ? primaryColor : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedStatusFilter != 'Semua Status' ? primaryColor : Colors.grey[200]!,
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.filter_list,
                            color: _selectedStatusFilter != 'Semua Status' ? Colors.white : onSurface,
                            size: 20,
                          ),
                          onPressed: () => _showStatusFilterSelector(context),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tab Selector Row
                Container(
                  height: 40,
                  margin: const EdgeInsets.only(bottom: 8.0),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    itemCount: _filters.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final filterName = _filters[index];
                      final isSelected = _selectedFilter == filterName;
                      return ChoiceChip(
                        label: Text(
                          filterName,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : onSurfaceVariant,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: primaryColor,
                        checkmarkColor: Colors.white,
                        backgroundColor: Colors.white,
                        elevation: 0,
                        pressElevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? primaryColor : Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedFilter = filterName;
                            });
                          }
                        },
                      );
                    },
                  ),
                ),

                // Active Filter Indicator chip
                if (_selectedStatusFilter != 'Semua Status') ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Chip(
                        label: Text(
                          'Status: $_selectedStatusFilter',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        backgroundColor: const Color(0xFF535F73),
                        deleteIcon: const Icon(Icons.close, size: 12, color: Colors.white),
                        onDeleted: () {
                          setState(() {
                            _selectedStatusFilter = 'Semua Status';
                          });
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],

                // Requests List View
                Expanded(
                  child: filteredRequests.isEmpty
                      ? _buildEmptyState('Tidak ada pengajuan ditemukan')
                      : _selectedFilter == 'Semua'
                          ? ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 90.0),
                              itemCount: sortedDates.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final date = sortedDates[index];
                                final reqs = groupedRequests[date]!;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
                                      child: Text(
                                        _formatIndonesianDate(date),
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ),
                                    ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: reqs.length,
                                      separatorBuilder: (context, idx) => const SizedBox(height: 10),
                                      itemBuilder: (context, idx) {
                                        return _buildRequestCard(context, reqs[idx]);
                                      },
                                    ),
                                  ],
                                );
                              },
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 90.0),
                              itemCount: filteredRequests.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final req = filteredRequests[index];
                                return _buildRequestCard(context, req);
                              },
                            ),
                ),
              ],
            ),
            
            // FAB button to add new pengajuan
            Positioned(
              bottom: 24,
              right: 24,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LeaveFormPage()),
                  );
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildRequestCard(BuildContext context, LeaveRequest req) {
    const primaryColor = Color(0xFF003D9B);
    const onSurface = Color(0xFF191C1E);
    const onSurfaceVariant = Color(0xFF434654);

    IconData typeIcon = Icons.event;
    Color iconColor = primaryColor;
    Color bgColor = const Color(0xFFE6F0FD);

    final String typeLower = req.type.toLowerCase();
    if (typeLower.contains('dinas') || typeLower.contains('sppd') || typeLower.contains('perjalanan')) {
      typeIcon = Icons.flight_takeoff;
      iconColor = primaryColor;
      bgColor = const Color(0xFFE6F0FD);
    } else if (typeLower.contains('sakit')) {
      typeIcon = Icons.medical_services_outlined;
      iconColor = const Color(0xFF535F73);
      bgColor = const Color(0xFFEDEEF0);
    } else if (typeLower.contains('tahunan')) {
      typeIcon = Icons.calendar_today_outlined;
      iconColor = Colors.orange;
      bgColor = const Color(0xFFFFF3E0);
    } else if (typeLower.contains('lembur')) {
      typeIcon = Icons.work_history_outlined;
      iconColor = Colors.purple;
      bgColor = const Color(0xFFF3E5F5);
    } else if (typeLower.contains('melahirkan')) {
      typeIcon = Icons.child_friendly_outlined;
      iconColor = Colors.pink;
      bgColor = const Color(0xFFFCE4EC);
    } else {
      typeIcon = Icons.assignment_outlined;
      iconColor = Colors.teal;
      bgColor = const Color(0xFFE0F2F1);
    }

    return Container(
      padding: EdgeInsets.all(context.isWatch ? 8 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!context.isWatch) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(typeIcon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flex(
                  direction: context.isWatch ? Axis.vertical : Axis.horizontal,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: context.isWatch ? 0 : 1,
                      child: Text(
                        req.type,
                        style: GoogleFonts.inter(
                          fontSize: context.sp(14),
                          fontWeight: FontWeight.bold,
                          color: onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (context.isWatch) const SizedBox(height: 4),
                    _buildStatusTag(req.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  req.details,
                  style: GoogleFonts.inter(
                    fontSize: context.sp(12),
                    color: onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                if (context.isWatch) ...[
                  Row(
                    children: [
                      Icon(Icons.calendar_month, size: 10, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          req.dateRange,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Icon(Icons.calendar_month, size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        req.dateRange,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Expanded(
                        flex: 2,
                        child: Text(
                          req.note,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: onSurfaceVariant,
                            fontWeight: FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTag(String status) {
    Color tagBg = const Color(0xFFF3F4F6);
    Color tagText = const Color(0xFF434654);

    if (status == 'ACC SDM' || status == 'Disetujui') {
      tagBg = const Color(0xFFE6F4EA);
      tagText = const Color(0xFF137333);
    } else if (status == 'Di ACC Atasan') {
      tagBg = const Color(0xFFE8F0FE);
      tagText = const Color(0xFF1A73E8);
    } else if (status == 'Pengajuan' || status == 'Menunggu') {
      tagBg = const Color(0xFFFEF7E0);
      tagText = const Color(0xFFB06000);
    } else if (status == 'Tolak Atasan') {
      tagBg = const Color(0xFFFCE8E6);
      tagText = const Color(0xFFC5221F);
    } else if (status == 'Tolak SDM' || status == 'Ditolak') {
      tagBg = const Color(0xFFFFEBEE);
      tagText = const Color(0xFFB71C1C);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: tagBg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: tagText,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showStatusFilterSelector(BuildContext context) {
    const primaryColor = Color(0xFF003D9B);
    const onSurface = Color(0xFF191C1E);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Filter Status Pengajuan',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _statusFilters.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final statusName = _statusFilters[index];
                      final isSelected = _selectedStatusFilter == statusName;

                      return ListTile(
                        title: Text(
                          statusName,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? primaryColor : onSurface,
                          ),
                        ),
                        trailing: isSelected ? const Icon(Icons.check_circle, color: primaryColor) : null,
                        onTap: () {
                          setState(() {
                            _selectedStatusFilter = statusName;
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: Text(
        text,
        style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
      ),
    );
  }
}
