import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrportalv2/modules/leave/domain/leave_form_type.dart';
import 'package:hrportalv2/modules/leave/presentation/leave_bloc.dart';
import 'package:hrportalv2/modules/attendance/presentation/attendance_bloc.dart';
import 'package:hrportalv2/core/responsive_helper.dart';
import 'package:hrportalv2/modules/leave/presentation/components/atoms/attachment_tile.dart';
import 'package:hrportalv2/modules/leave/presentation/components/atoms/supervisor_selector_tile.dart';
import 'package:hrportalv2/modules/leave/presentation/components/molecules/leave_form_tab_bar.dart';
import 'package:hrportalv2/modules/leave/presentation/components/strategies/attachment_strategy.dart';

// Modular Organisms
import 'package:hrportalv2/modules/leave/presentation/leave_form_data.dart';
import 'package:hrportalv2/modules/leave/presentation/components/helpers/leave_date_picker_helper.dart';
import 'package:hrportalv2/modules/leave/presentation/components/organisms/cuti_form_section.dart';
import 'package:hrportalv2/modules/leave/presentation/components/organisms/izin_form_section.dart';
import 'package:hrportalv2/modules/leave/presentation/components/organisms/sppd_form_section.dart';
import 'package:hrportalv2/modules/leave/presentation/components/organisms/cuti_type_selector_sheet.dart';
import 'package:hrportalv2/modules/leave/presentation/components/organisms/supervisor_selector_sheet.dart';
import 'package:hrportalv2/modules/leave/presentation/components/organisms/leave_form_success_dialog.dart';

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

  late LeaveFormType _activeType;

  @override
  void initState() {
    super.initState();
    _activeType = widget.initialTab == 1
        ? LeaveFormType.izin
        : (widget.initialTab == 2 ? LeaveFormType.sppd : LeaveFormType.cuti);

    switch (_activeType) {
      case LeaveFormType.cuti:
        _selectedCutiType = widget.initialType;
        break;
      case LeaveFormType.izin:
        _selectedIzinType = widget.initialType;
        break;
      case LeaveFormType.sppd:
        _selectedSppdType = widget.initialType;
        break;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaveBloc>().fetchSupervisors();
    });
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

  void _calculateCutiDuration() {
    final difference = _cutiEndDate.difference(_cutiStartDate).inDays + 1;
    _cutiDurationController.text = difference.toString();
  }

  void _calculateSppdDuration() {
    final difference = _sppdEndDate.difference(_sppdStartDate).inDays + 1;
    _sppdDurationController.text = difference.toString();
  }

  Future<void> _selectSingleDate(BuildContext context, bool isStart, LeaveFormType formType) async {
    final picked = await LeaveDatePickerHelper.pickDate(
      context: context,
      isStart: isStart,
      formType: formType,
      cutiStartDate: _cutiStartDate,
      cutiEndDate: _cutiEndDate,
      izinDate: _izinDate,
      sppdStartDate: _sppdStartDate,
      sppdEndDate: _sppdEndDate,
    );

    if (picked != null) {
      setState(() {
        switch (formType) {
          case LeaveFormType.cuti:
            if (isStart) {
              _cutiStartDate = picked;
              if (_cutiEndDate.isBefore(_cutiStartDate)) {
                _cutiEndDate = _cutiStartDate;
              }
            } else {
              _cutiEndDate = picked;
            }
            _calculateCutiDuration();
            break;
          case LeaveFormType.izin:
            _izinDate = picked;
            break;
          case LeaveFormType.sppd:
            if (isStart) {
              _sppdStartDate = picked;
              if (_sppdEndDate.isBefore(_sppdStartDate)) {
                _sppdEndDate = _sppdStartDate;
              }
            } else {
              _sppdEndDate = picked;
            }
            _calculateSppdDuration();
            break;
        }
      });
    }
  }

  void _simulateAttachment(LeaveFormType formType) {
    setState(() {
      switch (formType) {
        case LeaveFormType.cuti:
          _cutiHasAttachment = true;
          String typeLabel = _selectedCutiType ?? 'dokumen';
          _cutiFileName = 'bukti_cuti_${typeLabel.toLowerCase().replaceAll(' ', '_')}.pdf';
          _cutiFileSizeMb = 2.4;
          break;
        case LeaveFormType.izin:
          _izinHasAttachment = true;
          String typeLabel = _selectedIzinType ?? 'dokumen';
          _izinFileName = 'bukti_izin_${typeLabel.toLowerCase().replaceAll(' ', '_')}.pdf';
          _izinFileSizeMb = 1.8;
          break;
        case LeaveFormType.sppd:
          _sppdHasAttachment = true;
          String typeLabel = _selectedSppdType ?? 'dokumen';
          _sppdFileName = 'bukti_sppd_${typeLabel.toLowerCase().replaceAll(' ', '_')}.pdf';
          _sppdFileSizeMb = 3.2;
          break;
      }
    });
  }

  void _showSupervisorSelector(BuildContext context, LeaveFormType formType) {
    final leaveBloc = context.read<LeaveBloc>();
    String? currentSelectedId;
    switch (formType) {
      case LeaveFormType.cuti:
        currentSelectedId = _selectedCutiSupervisorId;
        break;
      case LeaveFormType.izin:
        currentSelectedId = _selectedIzinSupervisorId;
        break;
      case LeaveFormType.sppd:
        currentSelectedId = _selectedSppdSupervisorId;
        break;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SupervisorSelectorSheet(
          supervisors: leaveBloc.supervisors,
          currentSelectedId: currentSelectedId,
          onSupervisorSelected: (sv) {
            setState(() {
              switch (formType) {
                case LeaveFormType.cuti:
                  _selectedCutiSupervisorId = sv.id;
                  break;
                case LeaveFormType.izin:
                  _selectedIzinSupervisorId = sv.id;
                  break;
                case LeaveFormType.sppd:
                  _selectedSppdSupervisorId = sv.id;
                  break;
              }
            });
          },
        );
      },
    );
  }

  void _showCutiTypeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CutiTypeSelectorSheet(
          cutiTypes: LeaveFormData.cutiTypes,
          selectedCutiType: _selectedCutiType,
          onCutiTypeSelected: (type) {
            setState(() {
              _selectedCutiType = type;
            });
          },
        );
      },
    );
  }

  void _handleSubmit() async {
    final leaveBloc = context.read<LeaveBloc>();
    final attendanceBloc = context.read<AttendanceBloc>();

    switch (_activeType) {
      case LeaveFormType.cuti:
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

          final supervisor = leaveBloc.supervisors
              .firstWhere((element) => element.id == _selectedCutiSupervisorId);

          final ok = await leaveBloc.submitLeaveForm(
            type: 'Cuti - $_selectedCutiType',
            startDate: _cutiStartDate,
            endDate: _cutiEndDate,
            reason: _cutiPurposeController.text.trim(),
            supervisorId: supervisor.id,
            supervisorName: supervisor.name,
            attachmentPath: _cutiHasAttachment ? _cutiFileName : null,
          );

          if (ok) {
            attendanceBloc.addActivity(
              "Pengajuan Cuti - $_selectedCutiType Berhasil",
              "Hari ini • Menunggu Persetujuan",
              false,
            );
            if (!mounted) return;
            _showSuccessDialog();
          }
        }
        break;
      case LeaveFormType.izin:
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

          final supervisor = leaveBloc.supervisors
              .firstWhere((element) => element.id == _selectedIzinSupervisorId);

          final ok = await leaveBloc.submitLeaveForm(
            type: 'Izin - $_selectedIzinType',
            startDate: _izinDate,
            endDate: _izinDate,
            reason: _izinPurposeController.text.trim(),
            supervisorId: supervisor.id,
            supervisorName: supervisor.name,
            attachmentPath: _izinHasAttachment ? _izinFileName : null,
          );

          if (ok) {
            attendanceBloc.addActivity(
              "Pengajuan Izin - $_selectedIzinType Berhasil",
              "Hari ini • Menunggu Persetujuan",
              false,
            );
            if (!mounted) return;
            _showSuccessDialog();
          }
        }
        break;
      case LeaveFormType.sppd:
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

          final supervisor = leaveBloc.supervisors
              .firstWhere((element) => element.id == _selectedSppdSupervisorId);

          final ok = await leaveBloc.submitLeaveForm(
            type: 'SPPD - $_selectedSppdType',
            startDate: _sppdStartDate,
            endDate: _sppdEndDate,
            reason: 'Tujuan: ${_sppdPurposeController.text.trim()} | Kota: ${_sppdCityController.text.trim()}',
            supervisorId: supervisor.id,
            supervisorName: supervisor.name,
            attachmentPath: _sppdHasAttachment ? _sppdFileName : null,
          );

          if (ok) {
            attendanceBloc.addActivity(
              "Pengajuan SPPD - $_selectedSppdType Berhasil",
              "Hari ini • Menunggu Persetujuan",
              false,
            );
            if (!mounted) return;
            _showSuccessDialog();
          }
        }
        break;
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LeaveFormSuccessDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final leaveBloc = Provider.of<LeaveBloc>(context);

    final primaryColor = Theme.of(context).colorScheme.primary;
    final background = Theme.of(context).colorScheme.surface;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
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
            LeaveFormTabBar(
              activeType: _activeType,
              onTypeChanged: (type) {
                setState(() {
                  _activeType = type;
                });
              },
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(context.isWatch ? 10.0 : 20.0),
                child: _buildActiveFormSection(leaveBloc),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFormSection(LeaveBloc leaveBloc) {
    switch (_activeType) {
      case LeaveFormType.cuti:
        return _buildCutiForm(leaveBloc);
      case LeaveFormType.izin:
        return _buildIzinForm(leaveBloc);
      case LeaveFormType.sppd:
        return _buildSppdForm(leaveBloc);
    }
  }

  Widget _buildCutiForm(LeaveBloc leaveBloc) {
    return CutiFormSection(
      formKey: _cutiFormKey,
      selectedCutiType: _selectedCutiType,
      onCutiTypeTap: () => _showCutiTypeSelector(context),
      cutiStartDate: _cutiStartDate,
      cutiEndDate: _cutiEndDate,
      onSelectStartDate: () => _selectSingleDate(context, true, LeaveFormType.cuti),
      onSelectEndDate: () => _selectSingleDate(context, false, LeaveFormType.cuti),
      cutiDurationController: _cutiDurationController,
      cutiPurposeController: _cutiPurposeController,
      attachmentWidget: _buildAttachmentSection(LeaveFormType.cuti),
      supervisorSelectorWidget: Builder(
        builder: (context) {
          final sv = _selectedCutiSupervisorId == null
              ? null
              : leaveBloc.supervisors.firstWhere(
                  (element) => element.id == _selectedCutiSupervisorId);
          return SupervisorSelectorTile(
            selectedSupervisor: sv,
            onTap: () => _showSupervisorSelector(context, LeaveFormType.cuti),
          );
        },
      ),
      onSubmit: _handleSubmit,
    );
  }

  Widget _buildIzinForm(LeaveBloc leaveBloc) {
    return IzinFormSection(
      formKey: _izinFormKey,
      izinDate: _izinDate,
      onSelectDate: () => _selectSingleDate(context, false, LeaveFormType.izin),
      selectedIzinType: _selectedIzinType,
      onIzinTypeChanged: (value) {
        setState(() {
          _selectedIzinType = value;
        });
      },
      izinTypes: LeaveFormData.izinTypes,
      izinPurposeController: _izinPurposeController,
      attachmentWidget: _buildAttachmentSection(LeaveFormType.izin),
      supervisorSelectorWidget: Builder(
        builder: (context) {
          final sv = _selectedIzinSupervisorId == null
              ? null
              : leaveBloc.supervisors.firstWhere(
                  (element) => element.id == _selectedIzinSupervisorId);
          return SupervisorSelectorTile(
            selectedSupervisor: sv,
            onTap: () => _showSupervisorSelector(context, LeaveFormType.izin),
          );
        },
      ),
      onSubmit: _handleSubmit,
    );
  }

  Widget _buildSppdForm(LeaveBloc leaveBloc) {
    return SppdFormSection(
      formKey: _sppdFormKey,
      selectedSppdType: _selectedSppdType,
      onSppdTypeChanged: (value) {
        setState(() {
          _selectedSppdType = value;
        });
      },
      sppdTypes: LeaveFormData.sppdTypes,
      sppdCityController: _sppdCityController,
      sppdStartDate: _sppdStartDate,
      sppdEndDate: _sppdEndDate,
      onSelectStartDate: () => _selectSingleDate(context, true, LeaveFormType.sppd),
      onSelectEndDate: () => _selectSingleDate(context, false, LeaveFormType.sppd),
      sppdDurationController: _sppdDurationController,
      sppdPurposeController: _sppdPurposeController,
      attachmentWidget: _buildAttachmentSection(LeaveFormType.sppd),
      supervisorSelectorWidget: Builder(
        builder: (context) {
          final sv = _selectedSppdSupervisorId == null
              ? null
              : leaveBloc.supervisors.firstWhere(
                  (element) => element.id == _selectedSppdSupervisorId);
          return SupervisorSelectorTile(
            selectedSupervisor: sv,
            onTap: () => _showSupervisorSelector(context, LeaveFormType.sppd),
          );
        },
      ),
      onSubmit: _handleSubmit,
    );
  }

  Widget _buildAttachmentSection(LeaveFormType formType) {
    bool hasAttachment;
    String fileName;
    double fileSizeMb;

    switch (formType) {
      case LeaveFormType.cuti:
        hasAttachment = _cutiHasAttachment;
        fileName = _cutiFileName;
        fileSizeMb = _cutiFileSizeMb;
        break;
      case LeaveFormType.izin:
        hasAttachment = _izinHasAttachment;
        fileName = _izinFileName;
        fileSizeMb = _izinFileSizeMb;
        break;
      case LeaveFormType.sppd:
        hasAttachment = _sppdHasAttachment;
        fileName = _sppdFileName;
        fileSizeMb = _sppdFileSizeMb;
        break;
    }

    final strategy = AttachmentStrategyFactory.create(
      type: formType,
      hasAttachment: hasAttachment,
      fileName: fileName,
      fileSizeMb: fileSizeMb,
      onUpload: () => _simulateAttachment(formType),
      onDelete: () {
        setState(() {
          switch (formType) {
            case LeaveFormType.cuti:
              _cutiHasAttachment = false;
              break;
            case LeaveFormType.izin:
              _izinHasAttachment = false;
              break;
            case LeaveFormType.sppd:
              _sppdHasAttachment = false;
              break;
          }
        });
      },
    );

    return AttachmentTile(
      hasAttachment: strategy.hasAttachment,
      fileName: strategy.fileName,
      fileSizeMb: strategy.fileSizeMb,
      onUpload: strategy.onUpload,
      onDelete: strategy.onDelete,
    );
  }
}
