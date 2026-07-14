import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../state/app_state.dart';
import '../core/location_wifi_helper.dart';
import '../core/responsive_helper.dart';

class LeaveFormPage extends StatefulWidget {
  final int initialTab;
  final String? initialType;
  const LeaveFormPage({super.key, this.initialTab = 0, this.initialType});

  @override
  State<LeaveFormPage> createState() => _LeaveFormPageState();
}

class _LeaveFormPageState extends State<LeaveFormPage> {
  final _cutiFormKey = GlobalKey<FormState>();
  final _izinFormKey = GlobalKey<FormState>();
  final _sppdFormKey = GlobalKey<FormState>();
  
  // Tab control: 0 for Cuti, 1 for Izin, 2 for SPPD
  late int _activeTab;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    if (_activeTab == 0) {
      _selectedCutiType = widget.initialType;
    } else if (_activeTab == 1) {
      _selectedIzinType = widget.initialType;
    } else if (_activeTab == 2) {
      _selectedSppdType = widget.initialType;
    }
  }

  // --- Cuti Fields ---
  String? _selectedCutiType;
  DateTime _cutiStartDate = DateTime.now();
  DateTime _cutiEndDate = DateTime.now();
  final _cutiDurationController = TextEditingController(text: '1');
  final _cutiPurposeController = TextEditingController();
  bool _cutiHasAttachment = false;
  String _cutiFileName = '';
  double _cutiFileSizeMb = 0.0;
  String? _selectedCutiSupervisorId;

  // --- Izin Fields ---
  DateTime _izinDate = DateTime.now();
  String? _selectedIzinType;
  final _izinPurposeController = TextEditingController();
  bool _izinHasAttachment = false;
  String _izinFileName = '';
  double _izinFileSizeMb = 0.0;
  String? _selectedIzinSupervisorId;

  // --- SPPD Fields ---
  String? _selectedSppdType;
  DateTime _sppdStartDate = DateTime.now();
  DateTime _sppdEndDate = DateTime.now();
  final _sppdDurationController = TextEditingController(text: '1');
  final _sppdPurposeController = TextEditingController();
  final _sppdCityController = TextEditingController();
  bool _sppdHasAttachment = false;
  String _sppdFileName = '';
  double _sppdFileSizeMb = 0.0;
  String? _selectedSppdSupervisorId;

  // List of Jenis Cuti
  final List<Map<String, String>> _cutiTypes = [
    {
      'value': '1',
      'name': 'Cuti Tahunan',
      'desc': 'Hak cuti tahunan pegawai setelah masa kerja tertentu.',
      'max': '12 Hari / Tahun'
    },
    {
      'value': '2',
      'name': 'Cuti Sakit',
      'desc': 'Cuti akibat sakit atau kondisi medis yang memerlukan perawatan.',
      'max': '30 Hari dengan Surat Dokter'
    },
    {
      'value': '3',
      'name': 'Cuti Melahirkan',
      'desc': 'Cuti bersalin bagi pegawai wanita yang melahirkan.',
      'max': '3 Bulan'
    },
    {
      'value': '4',
      'name': 'Cuti Menunaikan Ibadah Haji',
      'desc': 'Cuti khusus untuk pegawai yang menunaikan ibadah haji.',
      'max': '50 Hari (Sekali selama bekerja)'
    },
    {
      'value': '5',
      'name': 'Cuti Menunaikan Ibadah Umroh',
      'desc': 'Cuti khusus untuk pegawai yang menunaikan ibadah umroh.',
      'max': '15 Hari'
    },
    {
      'value': '6',
      'name': 'Cuti Diluar Tanggungan',
      'desc': 'Cuti di luar tanggungan negara karena alasan mendesak.',
      'max': 'Maksimal 3 Tahun'
    },
    {
      'value': '7',
      'name': 'Cuti Alasan Penting (Pernikahan)',
      'desc': 'Cuti untuk melangsungkan pernikahan pegawai.',
      'max': '3 Hari'
    },
    {
      'value': '8',
      'name': 'Cuti Alasan Penting (Keluarga Meninggal Dunia)',
      'desc': 'Cuti karena keluarga dekat meninggal dunia.',
      'max': '2 Hari'
    },
    {
      'value': '9',
      'name': 'Cuti Alasan Penting (Menikahkan Anak)',
      'desc': 'Cuti untuk menikahkan anak kandung pegawai.',
      'max': '2 Hari'
    },
    {
      'value': '10',
      'name': 'Cuti Alasan Penting (Mengkhitan Anak / Baptis Anak)',
      'desc': 'Cuti untuk pelaksanaan khitanan atau baptis anak pegawai.',
      'max': '2 Hari'
    },
    {
      'value': '11',
      'name': 'Cuti Alasan Penting (Istri Melahirkan)',
      'desc': 'Cuti bagi suami saat istri melahirkan.',
      'max': '2 Hari'
    },
  ];

  // List of Jenis Izin
  final List<Map<String, String>> _izinTypes = [
    {'value': '1', 'name': 'Sakit'},
    {'value': '5', 'name': 'Keperluan Keluarga'},
    {'value': '6', 'name': 'Dinas Luar Kantor'},
    {'value': '7', 'name': 'Tugas Penunjang Tri Darma'},
    {'value': '8', 'name': 'Tugas Belajar (Studi Lanjut)'},
  ];

  // List of Jenis SPPD
  final List<Map<String, String>> _sppdTypes = [
    {'value': '1', 'name': 'Perjalanan Dinas Dalam Negeri'},
    {'value': '2', 'name': 'Perjalanan Dinas Luar Negeri'},
    {'value': '3', 'name': 'Dinas Rapat / Koordinasi'},
    {'value': '4', 'name': 'Tugas Penunjang Tri Darma'},
  ];

  // List of Supervisors
  final List<Map<String, String>> _supervisors = [
    {'id': '1110221914', 'name': 'Sobar Sukmana, MH.', 'role': 'Kepala Bag. Ketatanegaraan dan Hukum Internasional Fak. Hukum'},
    {'id': '1240920104', 'name': 'Firdanianty, Dr., M.Pd', 'role': 'Kepala Pusat Unggulan Gender Perempuan dan Anak ISIB'},
    {'id': '1250920173', 'name': 'Yusi Febriani, SP., M. Si.', 'role': 'Plt. Kepala Lab. Prodi PWK Fak. Tek'},
    {'id': '1151021927', 'name': 'Ir.Agus Sasmita, MT.', 'role': 'Plt. kepala Lab. Prodi Teknik Sipil'},
    {'id': '10497020274', 'name': 'Yuyus Rustandi, Drs., M. Pd.', 'role': 'Wakil Dekan 2 FISIB'},
    {'id': '11087028109', 'name': 'Nina Agustina, SE., ME.', 'role': 'Kepala Unpak Press'},
    {'id': '11188025119', 'name': 'Suhermanto, SH., M.H.', 'role': 'Wakil Dekan 3 Fakultas Hukum'},
    {'id': '10294006197', 'name': 'Singgih Irianto, Dr., M.Si.', 'role': 'Wakil Rektor Bidang Kemahasiswaan'},
    {'id': '196506191990032001', 'name': 'Prof. Dr. Eri Sarimanah, M. Pd', 'role': 'Wakil Rektor Bidang Akademik'},
    {'id': '10994030211', 'name': 'Didik Notosudjono, Dr., Prof.', 'role': 'Rektor'},
    {'id': '10997044290', 'name': 'Asep Denih, P.Hd., M. Sc., S.Kom.', 'role': 'Dekan Fakultas MIPA'},
    {'id': '10997051309', 'name': 'Ir.Lilis Sri Mulyawati, M.Si.', 'role': 'Dekan Fakultas Teknik'},
    {'id': '10410014512', 'name': 'Eka Ardianto Iskandar, Dr., MH.', 'role': 'Dekan Fakultas Hukum'},
    {'id': '1121019891', 'name': 'Towaf Totok Irawan, ME., Ph.D', 'role': 'Dekan Fakultas Ekonomi'},
    {'id': '10909048513', 'name': 'Muslim, S.Sos., M.Si.', 'role': 'Dekan Fakultas ISIB'},
  ];

  @override
  void dispose() {
    _cutiDurationController.dispose();
    _cutiPurposeController.dispose();
    _izinPurposeController.dispose();
    _sppdDurationController.dispose();
    _sppdPurposeController.dispose();
    _sppdCityController.dispose();
    super.dispose();
  }

  // Helper to auto-calculate leave duration
  void _calculateCutiDuration() {
    final difference = _cutiEndDate.difference(_cutiStartDate).inDays + 1;
    _cutiDurationController.text = difference.toString();
  }

  // Helper to auto-calculate sppd duration
  void _calculateSppdDuration() {
    final difference = _sppdEndDate.difference(_sppdStartDate).inDays + 1;
    _sppdDurationController.text = difference.toString();
  }

  Future<void> _selectSingleDate(BuildContext context, bool isStart, int formType) async {
    DateTime initialDate;
    DateTime firstDate;
    
    if (formType == 0) {
      initialDate = isStart ? _cutiStartDate : _cutiEndDate;
      firstDate = isStart 
          ? DateTime.now().subtract(const Duration(days: 30)) 
          : _cutiStartDate;
    } else if (formType == 1) {
      initialDate = _izinDate;
      firstDate = DateTime.now().subtract(const Duration(days: 30));
    } else {
      initialDate = isStart ? _sppdStartDate : _sppdEndDate;
      firstDate = isStart 
          ? DateTime.now().subtract(const Duration(days: 30)) 
          : _sppdStartDate;
    }

    // Fallback: If initialDate is on a disabled day, advance it to avoid assertion error
    if (LocationWifiHelper.isIndonesianHoliday(initialDate)) {
      while (LocationWifiHelper.isIndonesianHoliday(initialDate)) {
        initialDate = initialDate.add(const Duration(days: 1));
      }
    }
    if (LocationWifiHelper.isIndonesianHoliday(firstDate)) {
      while (LocationWifiHelper.isIndonesianHoliday(firstDate)) {
        firstDate = firstDate.add(const Duration(days: 1));
      }
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      selectableDayPredicate: (date) {
        return !LocationWifiHelper.isIndonesianHoliday(date);
      },
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF003D9B),
              onPrimary: Colors.white,
              onSurface: Color(0xFF191C1E),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (formType == 0) {
          if (isStart) {
            _cutiStartDate = picked;
            if (_cutiEndDate.isBefore(_cutiStartDate)) {
              _cutiEndDate = _cutiStartDate;
            }
          } else {
            _cutiEndDate = picked;
          }
          _calculateCutiDuration();
        } else if (formType == 1) {
          _izinDate = picked;
        } else {
          if (isStart) {
            _sppdStartDate = picked;
            if (_sppdEndDate.isBefore(_sppdStartDate)) {
              _sppdEndDate = _sppdStartDate;
            }
          } else {
            _sppdEndDate = picked;
          }
          _calculateSppdDuration();
        }
      });
    }
  }

  // Attachment Simulation
  void _simulateAttachment(int formType) {
    setState(() {
      if (formType == 0) {
        _cutiHasAttachment = true;
        String typeLabel = _selectedCutiType ?? 'dokumen';
        _cutiFileName = 'bukti_cuti_${typeLabel.toLowerCase().replaceAll(' ', '_')}.pdf';
        _cutiFileSizeMb = 2.4;
      } else if (formType == 1) {
        _izinHasAttachment = true;
        String typeLabel = _selectedIzinType ?? 'dokumen';
        _izinFileName = 'bukti_izin_${typeLabel.toLowerCase().replaceAll(' ', '_')}.pdf';
        _izinFileSizeMb = 1.8;
      } else if (formType == 2) {
        _sppdHasAttachment = true;
        String typeLabel = _selectedSppdType ?? 'dokumen';
        _sppdFileName = 'bukti_sppd_${typeLabel.toLowerCase().replaceAll(' ', '_')}.pdf';
        _sppdFileSizeMb = 3.2;
      }
    });
  }

  void _showSupervisorSelector(BuildContext context, int formType) {
    const primaryColor = Color(0xFF003D9B);
    const onSurface = Color(0xFF191C1E);
    String searchVal = "";
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            String? currentSelectedId;
            if (formType == 0) {
              currentSelectedId = _selectedCutiSupervisorId;
            } else if (formType == 1) {
              currentSelectedId = _selectedIzinSupervisorId;
            } else {
              currentSelectedId = _selectedSppdSupervisorId;
            }

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
                            fillColor: const Color(0xFFF1F3F5),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (val) {
                            setModalState(() {
                              searchVal = val.trim().toLowerCase();
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final filteredSvs = _supervisors.where((sv) {
                              final name = sv['name']!.toLowerCase();
                              final role = sv['role']!.toLowerCase();
                              final id = sv['id']!.toLowerCase();
                              return name.contains(searchVal) || 
                                     role.contains(searchVal) || 
                                     id.contains(searchVal);
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
                                final isSelected = sv['id'] == currentSelectedId;
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(vertical: 6),
                                  title: Text(
                                    sv['name']!,
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
                                        sv['role']!,
                                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'NIP: ${sv['id']}',
                                        style: GoogleFonts.inter(fontSize: 11, color: primaryColor, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                  trailing: isSelected
                                      ? const Icon(Icons.check_circle, color: primaryColor)
                                      : const Icon(Icons.radio_button_off, color: Colors.grey),
                                  onTap: () {
                                    setState(() {
                                      if (formType == 0) {
                                        _selectedCutiSupervisorId = sv['id'];
                                      } else if (formType == 1) {
                                        _selectedIzinSupervisorId = sv['id'];
                                      } else {
                                        _selectedSppdSupervisorId = sv['id'];
                                      }
                                    });
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
          },
        );
      },
    );
  }

  void _showCutiTypeSelector(BuildContext context) {
    const primaryColor = Color(0xFF003D9B);
    const onSurface = Color(0xFF191C1E);
    const onSurfaceVariant = Color(0xFF434654);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
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
                    'Pilih Jenis Cuti',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: _cutiTypes.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final type = _cutiTypes[index];
                        final isSelected = _selectedCutiType == type['name'];

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCutiType = type['name'];
                            });
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFF0F4FF) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? primaryColor : const Color(0xFFE2E8F0),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        type['name']!,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        type['desc']!,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: onSurfaceVariant,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isSelected ? const Color(0xFFD3E3FD) : const Color(0xFFEDF2F7),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Maks: ${type['max']}',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected ? primaryColor : onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  child: Icon(
                                    isSelected ? Icons.check_circle : Icons.radio_button_off,
                                    color: isSelected ? primaryColor : Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _handleSubmit() {
    if (_activeTab == 0) {
      // Handle Cuti Submit
      if (_cutiFormKey.currentState!.validate()) {
        if (_selectedCutiType == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Silakan pilih jenis cuti.')),
          );
          return;
        }
        if (_selectedCutiSupervisorId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Silakan pilih atasan untuk verifikasi.')),
          );
          return;
        }
        
        final durationDays = int.tryParse(_cutiDurationController.text) ?? 1;
        final supervisor = _supervisors.firstWhere((element) => element['id'] == _selectedCutiSupervisorId);
        final appState = Provider.of<AppState>(context, listen: false);
        
        appState.addLeaveRequest(
          'Cuti - $_selectedCutiType',
          _cutiStartDate,
          _cutiEndDate,
          _cutiPurposeController.text.trim(),
          customNote: 'Verifikasi: ${supervisor['name']}',
          customDays: durationDays,
        );

        _showSuccessDialog();
      }
    } else if (_activeTab == 1) {
      // Handle Izin Submit
      if (_izinFormKey.currentState!.validate()) {
        if (_selectedIzinType == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Silakan pilih jenis izin.')),
          );
          return;
        }
        if (_selectedIzinSupervisorId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Silakan pilih atasan untuk verifikasi.')),
          );
          return;
        }

        final supervisor = _supervisors.firstWhere((element) => element['id'] == _selectedIzinSupervisorId);
        final appState = Provider.of<AppState>(context, listen: false);

        appState.addLeaveRequest(
          'Izin - $_selectedIzinType',
          _izinDate,
          _izinDate,
          _izinPurposeController.text.trim(),
          customNote: 'Verifikasi: ${supervisor['name']}',
          customDays: 1,
        );

        _showSuccessDialog();
      }
    } else if (_activeTab == 2) {
      // Handle SPPD Submit
      if (_sppdFormKey.currentState!.validate()) {
        if (_selectedSppdType == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Silakan pilih jenis dinas/SPPD.')),
          );
          return;
        }
        if (_selectedSppdSupervisorId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Silakan pilih atasan untuk verifikasi.')),
          );
          return;
        }

        final durationDays = int.tryParse(_sppdDurationController.text) ?? 1;
        final supervisor = _supervisors.firstWhere((element) => element['id'] == _selectedSppdSupervisorId);
        final appState = Provider.of<AppState>(context, listen: false);

        appState.addLeaveRequest(
          'SPPD - $_selectedSppdType',
          _sppdStartDate,
          _sppdEndDate,
          'Tujuan: ${_sppdPurposeController.text.trim()} | Kota: ${_sppdCityController.text.trim()}',
          customNote: 'Verifikasi: ${supervisor['name']}',
          customDays: durationDays,
        );

        _showSuccessDialog();
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFE6F4EA),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'Pengajuan Terkirim',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF191C1E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pengajuan Anda telah berhasil dikirim ke atasan untuk verifikasi.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF434654),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Pop Dialog
                Navigator.pop(context); // Pop Form Screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003D9B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                minimumSize: const Size(double.infinity, 44),
                elevation: 0,
              ),
              child: Text(
                'Kembali',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day} ${_getMonthName(date.month)} ${date.year}";
  }

  String _getMonthName(int month) {
    const list = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return list[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    // Theme Colors
    const primaryColor = Color(0xFF003D9B);
    const background = Color(0xFFF8F9FB);
    const onSurfaceVariant = Color(0xFF434654);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Form Pengajuan',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: primaryColor,
            fontSize: context.sp(16),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Custom Segmented Tab Selection Bar
            Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: context.isWatch ? 8.0 : 20.0,
                vertical: 12.0,
              ),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDEEF0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    // Cuti Tab button
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _activeTab = 0;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: _activeTab == 0 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: _activeTab == 0
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            context.isWatch ? 'Cuti' : 'Form Cuti',
                            style: GoogleFonts.inter(
                              fontSize: context.sp(12),
                              fontWeight: _activeTab == 0 ? FontWeight.bold : FontWeight.w500,
                              color: _activeTab == 0 ? primaryColor : onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Izin Tab button
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _activeTab = 1;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: _activeTab == 1 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: _activeTab == 1
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            context.isWatch ? 'Izin' : 'Form Izin',
                            style: GoogleFonts.inter(
                              fontSize: context.sp(12),
                              fontWeight: _activeTab == 1 ? FontWeight.bold : FontWeight.w500,
                              color: _activeTab == 1 ? primaryColor : onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // SPPD Tab button
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _activeTab = 2;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: _activeTab == 2 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: _activeTab == 2
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            context.isWatch ? 'SPPD' : 'Form SPPD',
                            style: GoogleFonts.inter(
                              fontSize: context.sp(12),
                              fontWeight: _activeTab == 2 ? FontWeight.bold : FontWeight.w500,
                              color: _activeTab == 2 ? primaryColor : onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Expanded scrollable form contents
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(context.isWatch ? 10.0 : 20.0),
                child: _activeTab == 0
                    ? _buildCutiForm(appState)
                    : (_activeTab == 1 ? _buildIzinForm() : _buildSppdForm()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildCutiForm(AppState appState) {
    const primaryColor = Color(0xFF003D9B);
    const onSurface = Color(0xFF191C1E);
    const onSurfaceVariant = Color(0xFF434654);

    return Form(
      key: _cutiFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sisa Cuti Info Banner Card
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F0FD),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFB4CBEA)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: primaryColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sisa Kuota Cuti Tahunan',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Anda memiliki ${appState.sisaCuti} hari sisa cuti tahunan yang dapat digunakan.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // JENIS CUTI SELECT
          Text(
            'JENIS CUTI',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: onSurface,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showCutiTypeSelector(context),
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
                      _selectedCutiType ?? '-- Pilih Jenis Cuti --',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: _selectedCutiType == null ? Colors.grey[400] : onSurface,
                        fontWeight: _selectedCutiType == null ? FontWeight.normal : FontWeight.w500,
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

          // TANGGAL CUTI (RANGE)
          Text(
            'TANGGAL CUTI (RANGE)',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: onSurface,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Flex(
            direction: context.isWatch ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: context.isWatch ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
            children: [
              context.isWatch
                  ? GestureDetector(
                      onTap: () => _selectSingleDate(context, true, 0),
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
                              _formatDate(_cutiStartDate),
                              style: GoogleFonts.inter(fontSize: 13, color: onSurface, fontWeight: FontWeight.w500),
                            ),
                            Icon(Icons.calendar_today, size: 16, color: Colors.grey[400]),
                          ],
                        ),
                      ),
                    )
                  : Expanded(
                      child: GestureDetector(
                        onTap: () => _selectSingleDate(context, true, 0),
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
                                _formatDate(_cutiStartDate),
                                style: GoogleFonts.inter(fontSize: 13, color: onSurface, fontWeight: FontWeight.w500),
                              ),
                              Icon(Icons.calendar_today, size: 16, color: Colors.grey[400]),
                            ],
                          ),
                        ),
                      ),
                    ),
              SizedBox(
                width: context.isWatch ? 0 : 8,
                height: context.isWatch ? 6 : 0,
              ),
              Text(
                's/d',
                style: GoogleFonts.inter(fontSize: 12, color: onSurfaceVariant, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                width: context.isWatch ? 0 : 8,
                height: context.isWatch ? 6 : 0,
              ),
              context.isWatch
                  ? GestureDetector(
                      onTap: () => _selectSingleDate(context, false, 0),
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
                              _formatDate(_cutiEndDate),
                              style: GoogleFonts.inter(fontSize: 13, color: onSurface, fontWeight: FontWeight.w500),
                            ),
                            Icon(Icons.calendar_today, size: 16, color: Colors.grey[400]),
                          ],
                        ),
                      ),
                    )
                  : Expanded(
                      child: GestureDetector(
                        onTap: () => _selectSingleDate(context, false, 0),
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
                                _formatDate(_cutiEndDate),
                                style: GoogleFonts.inter(fontSize: 13, color: onSurface, fontWeight: FontWeight.w500),
                              ),
                              Icon(Icons.calendar_today, size: 16, color: Colors.grey[400]),
                            ],
                          ),
                        ),
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 20),

          // LAMA CUTI (Auto-calculated, Editable)
          Text(
            'LAMA CUTI (HARI)',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: onSurface,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _cutiDurationController,
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

          // TUJUAN / ALASAN
          Text(
            'TUJUAN / ALASAN PENGAJUAN',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: onSurface,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _cutiPurposeController,
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
                borderSide: const BorderSide(color: primaryColor, width: 1.5),
              ),
            ),
            validator: (value) => (value == null || value.trim().isEmpty) ? 'Alasan pengajuan harus diisi' : null,
          ),
          const SizedBox(height: 20),

          // UPLOAD DOKUMEN
          Text(
            'DOKUMEN PENDUKUNG',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: onSurface,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          _buildAttachmentSection(0),
          const SizedBox(height: 20),

          // VERIFIKASI ATASAN
          Text(
            'VERIFIKASI ATASAN',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: onSurface,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showSupervisorSelector(context, 0),
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
                    child: Builder(
                      builder: (context) {
                        if (_selectedCutiSupervisorId == null) {
                          return Text(
                            '-- Pilih Nama Atasan --',
                            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400]),
                          );
                        }
                        final sv = _supervisors.firstWhere((element) => element['id'] == _selectedCutiSupervisorId);
                        return Text(
                          '${sv['name']} - ${sv['role']}',
                          style: GoogleFonts.inter(fontSize: 13, color: onSurface, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // SUBMIT BUTTON
          ElevatedButton(
            onPressed: _handleSubmit,
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

  Widget _buildIzinForm() {
    const primaryColor = Color(0xFF003D9B);
    const onSurface = Color(0xFF191C1E);
    const onSurfaceVariant = Color(0xFF434654);

    return Form(
      key: _izinFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // TANGGAL IZIN
          Text(
            'TANGGAL IZIN',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: onSurface,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _selectSingleDate(context, false, 1),
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
                    _formatDate(_izinDate),
                    style: GoogleFonts.inter(fontSize: 13, color: onSurface, fontWeight: FontWeight.w500),
                  ),
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // JENIS IZIN SELECT
          Text(
            'JENIS IZIN',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: onSurface,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedIzinType,
            isExpanded: true,
            hint: Text('-- Pilih Jenis Izin --', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400])),
            icon: const Icon(Icons.expand_more, color: onSurfaceVariant),
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
            items: _izinTypes.map((item) {
              return DropdownMenuItem<String>(
                value: item['name'],
                child: Text(item['name']!),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _selectedIzinType = newValue;
              });
            },
            validator: (value) => value == null ? 'Jenis izin harus dipilih' : null,
          ),
          const SizedBox(height: 20),

          // TUJUAN / ALASAN
          Text(
            'TUJUAN / ALASAN PENGAJUAN',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: onSurface,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _izinPurposeController,
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
                borderSide: const BorderSide(color: primaryColor, width: 1.5),
              ),
            ),
            validator: (value) => (value == null || value.trim().isEmpty) ? 'Alasan pengajuan harus diisi' : null,
          ),
          const SizedBox(height: 20),

          // UPLOAD DOKUMEN
          Text(
            'DOKUMEN PENDUKUNG',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: onSurface,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          _buildAttachmentSection(1),
          const SizedBox(height: 20),

          // VERIFIKASI ATASAN
          Text(
            'VERIFIKASI ATASAN',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: onSurface,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showSupervisorSelector(context, 1),
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
                    child: Builder(
                      builder: (context) {
                        if (_selectedIzinSupervisorId == null) {
                          return Text(
                            '-- Pilih Nama Atasan --',
                            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400]),
                          );
                        }
                        final sv = _supervisors.firstWhere((element) => element['id'] == _selectedIzinSupervisorId);
                        return Text(
                          '${sv['name']} - ${sv['role']}',
                          style: GoogleFonts.inter(fontSize: 13, color: onSurface, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // SUBMIT BUTTON
          ElevatedButton(
            onPressed: _handleSubmit,
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

  Widget _buildAttachmentSection(int formType) {
    const primaryColor = Color(0xFF003D9B);
    const onSurface = Color(0xFF191C1E);
    const onSurfaceVariant = Color(0xFF434654);

    bool hasAttachment = false;
    String fileName = '';
    double fileSize = 0.0;

    if (formType == 0) {
      hasAttachment = _cutiHasAttachment;
      fileName = _cutiFileName;
      fileSize = _cutiFileSizeMb;
    } else if (formType == 1) {
      hasAttachment = _izinHasAttachment;
      fileName = _izinFileName;
      fileSize = _izinFileSizeMb;
    } else if (formType == 2) {
      hasAttachment = _sppdHasAttachment;
      fileName = _sppdFileName;
      fileSize = _sppdFileSizeMb;
    }

    if (hasAttachment) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            const Icon(Icons.description, color: primaryColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${fileSize.toStringAsFixed(1)} MB • Berhasil Diunggah',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red, size: 18),
              onPressed: () {
                setState(() {
                  if (formType == 0) {
                    _cutiHasAttachment = false;
                  } else if (formType == 1) {
                    _izinHasAttachment = false;
                  } else if (formType == 2) {
                    _sppdHasAttachment = false;
                  }
                });
              },
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _simulateAttachment(formType),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: primaryColor.withOpacity(0.3),
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            const Icon(Icons.upload_file, color: primaryColor, size: 36),
            const SizedBox(height: 8),
            Text(
              'Ketuk untuk mengunggah dokumen bukti',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'PDF, JPG, JPEG, PNG, atau BMP (Maks. 10MB)',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSppdForm() {
    const primaryColor = Color(0xFF003D9B);
    const onSurface = Color(0xFF191C1E);
    const onSurfaceVariant = Color(0xFF434654);

    return Form(
      key: _sppdFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // JENIS DINAS / SPPD
          Text(
            'JENIS PERJALANAN DINAS (SPPD)',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: onSurface,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedSppdType,
            isExpanded: true,
            hint: Text('-- Pilih Jenis SPPD --', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400])),
            icon: const Icon(Icons.expand_more, color: onSurfaceVariant),
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
            items: _sppdTypes.map((item) {
              return DropdownMenuItem<String>(
                value: item['name'],
                child: Text(item['name']!),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _selectedSppdType = newValue;
              });
            },
            validator: (value) => value == null ? 'Jenis SPPD harus dipilih' : null,
          ),
          const SizedBox(height: 20),

          // KOTA TUJUAN
          Text(
            'KOTA TUJUAN',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: onSurface,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _sppdCityController,
            style: GoogleFonts.inter(fontSize: 14, color: onSurface, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'Tuliskan kota tujuan dinas Anda...',
              hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400]),
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
            validator: (value) => (value == null || value.trim().isEmpty) ? 'Kota tujuan harus diisi' : null,
          ),
          const SizedBox(height: 20),

          // TANGGAL DINAS (RANGE)
          Text(
            'TANGGAL DINAS (RANGE)',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: onSurface,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Flex(
            direction: context.isWatch ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: context.isWatch ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
            children: [
              context.isWatch
                  ? GestureDetector(
                      onTap: () => _selectSingleDate(context, true, 2),
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
                              _formatDate(_sppdStartDate),
                              style: GoogleFonts.inter(fontSize: 13, color: onSurface, fontWeight: FontWeight.w500),
                            ),
                            Icon(Icons.calendar_today, size: 16, color: Colors.grey[400]),
                          ],
                        ),
                      ),
                    )
                  : Expanded(
                      child: GestureDetector(
                        onTap: () => _selectSingleDate(context, true, 2),
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
                                _formatDate(_sppdStartDate),
                                style: GoogleFonts.inter(fontSize: 13, color: onSurface, fontWeight: FontWeight.w500),
                              ),
                              Icon(Icons.calendar_today, size: 16, color: Colors.grey[400]),
                            ],
                          ),
                        ),
                      ),
                    ),
              SizedBox(
                width: context.isWatch ? 0 : 8,
                height: context.isWatch ? 6 : 0,
              ),
              Text(
                's/d',
                style: GoogleFonts.inter(fontSize: 12, color: onSurfaceVariant, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                width: context.isWatch ? 0 : 8,
                height: context.isWatch ? 6 : 0,
              ),
              context.isWatch
                  ? GestureDetector(
                      onTap: () => _selectSingleDate(context, false, 2),
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
                              _formatDate(_sppdEndDate),
                              style: GoogleFonts.inter(fontSize: 13, color: onSurface, fontWeight: FontWeight.w500),
                            ),
                            Icon(Icons.calendar_today, size: 16, color: Colors.grey[400]),
                          ],
                        ),
                      ),
                    )
                  : Expanded(
                      child: GestureDetector(
                        onTap: () => _selectSingleDate(context, false, 2),
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
                                _formatDate(_sppdEndDate),
                                style: GoogleFonts.inter(fontSize: 13, color: onSurface, fontWeight: FontWeight.w500),
                              ),
                              Icon(Icons.calendar_today, size: 16, color: Colors.grey[400]),
                            ],
                          ),
                        ),
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 20),

          // LAMA DINAS (HARI)
          Text(
            'LAMA DINAS (HARI)',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: onSurface,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _sppdDurationController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.inter(fontSize: 14, color: onSurface, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF1F3F5),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            validator: (value) => (value == null || value.trim().isEmpty) ? 'Lama hari dinas harus diisi' : null,
          ),
          const SizedBox(height: 20),

          // MAKSUD PERJALANAN DINAS
          Text(
            'MAKSUD PERJALANAN DINAS',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: onSurface,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _sppdPurposeController,
            maxLines: 4,
            style: GoogleFonts.inter(fontSize: 14, color: onSurface, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'Tuliskan deskripsi lengkap tugas perjalanan dinas Anda...',
              hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400]),
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
            ),
            validator: (value) => (value == null || value.trim().isEmpty) ? 'Maksud perjalanan harus diisi' : null,
          ),
          const SizedBox(height: 20),

          // UPLOAD DOKUMEN
          Text(
            'SURAT TUGAS / DOKUMEN PENDUKUNG',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: onSurface,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          _buildAttachmentSection(2),
          const SizedBox(height: 20),

          // VERIFIKASI ATASAN
          Text(
            'VERIFIKASI ATASAN',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: onSurface,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showSupervisorSelector(context, 2),
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
                    child: Builder(
                      builder: (context) {
                        if (_selectedSppdSupervisorId == null) {
                          return Text(
                            '-- Pilih Nama Atasan --',
                            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400]),
                          );
                        }
                        final sv = _supervisors.firstWhere((element) => element['id'] == _selectedSppdSupervisorId);
                        return Text(
                          '${sv['name']} - ${sv['role']}',
                          style: GoogleFonts.inter(fontSize: 13, color: onSurface, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // SUBMIT BUTTON
          ElevatedButton(
            onPressed: _handleSubmit,
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
