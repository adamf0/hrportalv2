import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrportalv2/modules/leave/domain/leave.dart';

class MemberSelectorSheet extends StatefulWidget {
  final List<Supervisor> people;
  final List<Supervisor> initialSelectedMembers;
  final ValueChanged<List<Supervisor>> onMembersSelected;

  const MemberSelectorSheet({
    super.key,
    required this.people,
    required this.initialSelectedMembers,
    required this.onMembersSelected,
  });

  @override
  State<MemberSelectorSheet> createState() => _MemberSelectorSheetState();
}

class _MemberSelectorSheetState extends State<MemberSelectorSheet> {
  String _searchVal = "";
  late List<Supervisor> _selectedList;

  @override
  void initState() {
    super.initState();
    _selectedList = List.from(widget.initialSelectedMembers);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
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
                'Pilih Anggota / Pengikut Dinas',
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
                    hintText: 'Cari nama, unit, atau NIP...',
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
                    final filteredPeople = widget.people.where((p) {
                      final name = p.name.toLowerCase();
                      final role = p.role.toLowerCase();
                      final id = p.id.toLowerCase();
                      return name.contains(_searchVal) ||
                          role.contains(_searchVal) ||
                          id.contains(_searchVal);
                    }).toList();

                    if (filteredPeople.isEmpty) {
                      return Center(
                        child: Text(
                          'Pegawai tidak ditemukan',
                          style: GoogleFonts.inter(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: filteredPeople.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final p = filteredPeople[index];
                        final isSelected =
                            _selectedList.any((element) => element.id == p.id);
                        return CheckboxListTile(
                          activeColor: primaryColor,
                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          value: isSelected,
                          title: Text(
                            p.name,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: onSurface,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (p.role.isNotEmpty)
                                Text(
                                  p.role,
                                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                                ),
                              Text(
                                'NIP: ${p.id}',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                if (!_selectedList.any((e) => e.id == p.id)) {
                                  _selectedList.add(p);
                                }
                              } else {
                                _selectedList.removeWhere((e) => e.id == p.id);
                              }
                            });
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onMembersSelected(_selectedList);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Simpan Anggota (${_selectedList.length})',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
