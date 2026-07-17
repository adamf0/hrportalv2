import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrportalv2/modules/leave/domain/leave.dart';

class SupervisorSelectorSheet extends StatefulWidget {
  final List<Supervisor> supervisors;
  final String? currentSelectedId;
  final ValueChanged<Supervisor> onSupervisorSelected;

  const SupervisorSelectorSheet({
    super.key,
    required this.supervisors,
    required this.currentSelectedId,
    required this.onSupervisorSelected,
  });

  @override
  State<SupervisorSelectorSheet> createState() => _SupervisorSelectorSheetState();
}

class _SupervisorSelectorSheetState extends State<SupervisorSelectorSheet> {
  String _searchVal = "";

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
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
                'Pilih Atasan Verifikator',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari nama, jabatan, atau NIP...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainer,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchVal = val.trim().toLowerCase();
                    });
                  },
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final filteredSvs = widget.supervisors.where((sv) {
                      final name = sv.name.toLowerCase();
                      final role = sv.role.toLowerCase();
                      final id = sv.id.toLowerCase();
                      return name.contains(_searchVal) ||
                          role.contains(_searchVal) ||
                          id.contains(_searchVal);
                    }).toList();

                    if (filteredSvs.isEmpty) {
                      return Center(
                        child: Text(
                          'Atasan tidak ditemukan',
                          style: GoogleFonts.inter(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: filteredSvs.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final sv = filteredSvs[index];
                        final isSelected = sv.id == widget.currentSelectedId;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 6),
                          title: Text(
                            sv.name,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: onSurface,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                sv.role,
                                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'NIP: ${sv.id}',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_circle, color: primaryColor)
                              : const Icon(Icons.radio_button_off, color: Colors.grey),
                          onTap: () {
                            widget.onSupervisorSelected(sv);
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
