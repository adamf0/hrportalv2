import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrportalv2/modules/leave/presentation/leave_bloc.dart';
import 'package:hrportalv2/modules/leave/domain/leave.dart';
import 'package:hrportalv2/modules/leave/domain/leave_status.dart';
import 'package:hrportalv2/modules/leave/domain/leave_category.dart';
import 'leave_form_page.dart';
import 'package:hrportalv2/modules/leave/presentation/components/organisms/request_card.dart';
import 'package:hrportalv2/modules/leave/presentation/components/organisms/status_filter_sheet.dart';

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaveBloc>().fetchLeaves();
    });
  }

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
    final leaveBloc = Provider.of<LeaveBloc>(context);
    
    final primaryColor = Theme.of(context).colorScheme.primary;
    final background = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    final List<LeaveRequest> allRequests = leaveBloc.leaves;

    final selectedCategory = LeaveCategory.fromString(_selectedFilter);
    List<LeaveRequest> filteredRequests = allRequests
        .where((req) => selectedCategory.matches(req.type))
        .toList();

    if (_selectedStatusFilter != 'Semua Status') {
      final targetStatus = LeaveRequestStatus.fromString(_selectedStatusFilter);
      filteredRequests = filteredRequests
          .where((req) => LeaveRequestStatus.fromString(req.status) == targetStatus)
          .toList();
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filteredRequests = filteredRequests.where((req) {
        final type = req.type.toLowerCase();
        final details = req.details.toLowerCase();
        final note = req.note.toLowerCase();
        return type.contains(query) || details.contains(query) || note.contains(query);
      }).toList();
    }

    filteredRequests.sort((a, b) => b.startDate.compareTo(a.startDate));

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
                            child: Icon(Icons.notifications_none, color: onSurface, size: 22),
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
                            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey[200]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: primaryColor, width: 1.5),
                            ),
                          ),
                          onChanged: (val) {
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: () => _showStatusFilterSelector(context),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: Colors.grey[200]!),
                          ),
                          padding: const EdgeInsets.all(12),
                        ),
                        icon: Icon(Icons.tune, color: primaryColor),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
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
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? Colors.white : onSurfaceVariant,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: primaryColor,
                            backgroundColor: Colors.white,
                            elevation: 0,
                            pressElevation: 0,
                            side: BorderSide(
                              color: isSelected ? Colors.transparent : Colors.grey[200]!,
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
                                height: MediaQuery.of(context).size.height * 0.6,
                                child: Center(child: CircularProgressIndicator(color: primaryColor)),
                              )
                            ],
                          )
                        : filteredRequests.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.6,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.assignment_late_outlined, size: 48, color: Colors.grey[300]),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Tidak ada data pengajuan',
                                          style: GoogleFonts.inter(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
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
                                        final items = groupedRequests[date] ?? [];
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
                                              child: Text(
                                                _formatIndonesianDate(date),
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: onSurfaceVariant,
                                                ),
                                              ),
                                            ),
                                            ...items.map((req) => RequestCard(req: req)),
                                          ],
                                        );
                                      }).toList()
                                    : filteredRequests.map((req) => RequestCard(req: req)).toList(),
                              ),
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LeaveFormPage()),
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
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
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
