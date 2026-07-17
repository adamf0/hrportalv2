import 'package:flutter/foundation.dart';
import 'package:hrportalv2/core/api_client.dart';
import 'package:hrportalv2/core/sso_helper.dart';
import 'package:hrportalv2/core/location_wifi_helper.dart';
import '../domain/leave.dart';
import '../domain/leave_errors.dart';
import '../domain/i_leave_repository.dart';

class LeaveRepository implements ILeaveRepository {
  final List<Supervisor> _supervisors = [
    Supervisor(
        id: '1110221914',
        name: 'Sobar Sukmana, MH.',
        role: 'Kepala Bag. Ketatanegaraan dan Hukum Internasional Fak. Hukum'),
    Supervisor(
        id: '1240920104',
        name: 'Firdanianty, Dr., M.Pd',
        role: 'Kepala Pusat Unggulan Gender Perempuan dan Anak ISIB'),
    Supervisor(
        id: '1250920173',
        name: 'Yusi Febriani, SP., M. Si.',
        role: 'Plt. Kepala Lab. Prodi PWK Fak. Tek'),
    Supervisor(
        id: '1151021927',
        name: 'Ir.Agus Sasmita, MT.',
        role: 'Plt. kepala Lab. Prodi Teknik Sipil'),
    Supervisor(
        id: '10497020274',
        name: 'Yuyus Rustandi, Drs., M. Pd.',
        role: 'Wakil Dekan 2 FISIB'),
    Supervisor(
        id: '11087028109',
        name: 'Nina Agustina, SE., ME.',
        role: 'Kepala Unpak Press'),
    Supervisor(
        id: '11188025119',
        name: 'Suhermanto, SH., M.H.',
        role: 'Wakil Dekan 3 Fakultas Hukum'),
    Supervisor(
        id: '10294006197',
        name: 'Singgih Irianto, Dr., M.Si.',
        role: 'Wakil Rektor Bidang Kemahasiswaan'),
    Supervisor(
        id: '196506191990032001',
        name: 'Prof. Dr. Eri Sarimanah, M. Pd',
        role: 'Wakil Rektor Bidang Akademik'),
    Supervisor(
        id: '10994030211',
        name: 'Didik Notosudjono, Dr., Prof.',
        role: 'Rektor'),
    Supervisor(
        id: '10997044290',
        name: 'Asep Denih, P.Hd., M. Sc., S.Kom.',
        role: 'Dekan Fakultas MIPA'),
    Supervisor(
        id: '10997051309',
        name: 'Ir.Lilis Sri Mulyawati, M.Si.',
        role: 'Dekan Fakultas Teknik'),
    Supervisor(
        id: '10410014512',
        name: 'Eka Ardianto Iskandar, Dr., MH.',
        role: 'Dekan Fakultas Hukum'),
    Supervisor(
        id: '1121019891',
        name: 'Towaf Totok Irawan, ME., Ph.D',
        role: 'Dekan Fakultas Ekonomi'),
    Supervisor(
        id: '10909048513',
        name: 'Muslim, S.Sos., M.Si.',
        role: 'Dekan Fakultas ISIB'),
  ];

  @override
  Future<List<LeaveRequest>> getLeaves() async {
    try {
      final session = await SsoHelper.getSession();
      if (session == null) return [];
      final nip = session['nip'] ?? '';
      final role = session['role'] ?? '';
      final nidn = role == 'Dosen' ? nip : '';

      final List<LeaveRequest> allRequests = [];

      // 1. Fetch Cuti
      try {
        final cutiData = await ApiClient.get(
          Uri.parse("${ApiClient.baseUrl}/api/leave"),
        );
        if (cutiData is List) {
          for (var json in cutiData) {
            final startStr = json['tanggal_mulai'] as String? ?? '';
            final endStr = json['tanggal_selesai'] as String? ?? '';
            final startDate = DateTime.tryParse(startStr)?.toLocal() ?? DateTime.now();
            final endDate = DateTime.tryParse(endStr)?.toLocal() ?? DateTime.now();
            final jenisCutiId = json['jenis_cuti_id'] as int? ?? 1;
            String type = "Cuti Tahunan";
            if (jenisCutiId == 2) type = "Cuti Sakit";
            if (jenisCutiId == 3) type = "Cuti Melahirkan";
            if (jenisCutiId == 4) type = "Cuti Menunaikan Ibadah Haji";

            allRequests.add(LeaveRequest(
              id: "cuti_${json['id']}",
              type: type,
              status: json['status'] ?? 'Pengajuan',
              dateRange:
                  "${startDate.day} - ${endDate.day} ${_getMonthName(startDate.month)} ${startDate.year}",
              details: json['alasan'] ?? '',
              note: json['catatan_atasan'] ?? 'Menunggu verifikasi',
              startDate: startDate,
              endDate: endDate,
            ));
          }
        }
      } catch (e) {
        debugPrint('[LeaveRepository fetch Cuti error]: $e');
      }

      // 2. Fetch Izin
      try {
        final izinData = await ApiClient.get(
          Uri.parse("${ApiClient.baseUrl}/api/izin"),
        );
        if (izinData is List) {
          for (var json in izinData) {
            final dateStr = json['tanggal_pengajuan'] as String? ?? '';
            final date = DateTime.tryParse(dateStr)?.toLocal() ?? DateTime.now();
            final jenisIzinId = json['jenis_izin_id'] as int? ?? 1;
            String type = "Izin Sakit";
            if (jenisIzinId == 2) type = "Izin Sakit Tanpa Dokter";
            if (jenisIzinId == 3) type = "Izin Melahirkan";
            if (jenisIzinId == 4) type = "Izin Keperluan Mendesak";

            allRequests.add(LeaveRequest(
              id: "izin_${json['id']}",
              type: type,
              status: json['status'] ?? 'Pengajuan',
              dateRange:
                  "${date.day} ${_getMonthName(date.month)} ${date.year}",
              details: json['tujuan'] ?? '',
              note: 'Verifikasi Atasan',
              startDate: date,
              endDate: date,
            ));
          }
        }
      } catch (e) {
        debugPrint('[LeaveRepository fetch Izin error]: $e');
      }

      // 3. Fetch SPPD
      try {
        final sppdData = await ApiClient.get(
          Uri.parse("${ApiClient.baseUrl}/api/sppd/history"),
        );
        if (sppdData is Map<String, dynamic> && sppdData['data'] != null) {
          final items = sppdData['data'] as List;
          for (var json in items) {
            final startStr = json['tanggal_berangkat'] as String? ?? '';
            final endStr = json['tanggal_kembali'] as String? ?? '';
            final startDate = DateTime.tryParse(startStr)?.toLocal() ?? DateTime.now();
            final endDate = DateTime.tryParse(endStr)?.toLocal() ?? DateTime.now();
            final jenisSppdId = json['jenis_sppd_id'] as int? ?? 1;
            String type = "SPPD - Dinas Luar";
            if (jenisSppdId == 2) type = "SPPD - Dinas Dalam Kota";

            allRequests.add(LeaveRequest(
              id: "sppd_${json['id']}",
              type: type,
              status: json['status'] ?? 'Pengajuan',
              dateRange:
                  "${startDate.day} - ${endDate.day} ${_getMonthName(startDate.month)} ${startDate.year}",
              details: json['tujuan'] ?? '',
              note: json['keterangan'] ?? 'Menunggu verifikasi',
              startDate: startDate,
              endDate: endDate,
            ));
          }
        }
      } catch (e) {
        debugPrint('[LeaveRepository fetch SPPD error]: $e');
      }

      allRequests.sort((a, b) => b.startDate.compareTo(a.startDate));
      return allRequests;
    } catch (e, stackTrace) {
      debugPrint('[LeaveRepository getLeaves error]: $e\n$stackTrace');
    }
    return [];
  }

  @override
  Future<bool> submitLeave(
      LeaveRequest request, String supervisorId, String? attachmentPath) async {
    if (request.endDate.isBefore(request.startDate)) {
      throw const InvalidLeavePeriodError();
    }
    // if (LocationWifiHelper.isIndonesianHoliday(request.startDate) ||
    //     LocationWifiHelper.isIndonesianHoliday(request.endDate)) {
    //   throw const HolidaySelectedError();
    // }

    try {
      final session = await SsoHelper.getSession();
      if (session == null) return false;
      final nip = session['nip'] ?? '';
      final role = session['role'] ?? '';
      final nidn = role == 'Dosen' ? nip : '';

      final typeLower = request.type.toLowerCase();

      if (typeLower.startsWith("izin")) {
        int jenisIzinId = 1;
        if (typeLower.contains("tanpa dokter")) jenisIzinId = 2;
        if (typeLower.contains("melahirkan")) jenisIzinId = 3;
        if (typeLower.contains("mendesak")) jenisIzinId = 4;

        final responseData = await ApiClient.post(
          Uri.parse("${ApiClient.baseUrl}/api/izin/"),
          body: {
            "nip": nip,
            "nidn": nidn,
            "jenis_izin_id": jenisIzinId.toString(),
            "tanggal_pengajuan":
                "${request.startDate.year}-${_twoDigits(request.startDate.month)}-${_twoDigits(request.startDate.day)}",
            "tujuan": request.details,
          },
        );
        return responseData != null;
      } else if (typeLower.startsWith("sppd")) {
        int jenisSppdId = 1;
        if (typeLower.contains("dalam kota")) jenisSppdId = 2;

        final responseData = await ApiClient.post(
          Uri.parse("${ApiClient.baseUrl}/api/sppd/create"),
          body: {
            "nip": nip,
            "nidn": nidn,
            "jenis_sppd_id": jenisSppdId.toString(),
            "tanggal_berangkat":
                "${request.startDate.year}-${_twoDigits(request.startDate.month)}-${_twoDigits(request.startDate.day)}",
            "tanggal_kembali":
                "${request.endDate.year}-${_twoDigits(request.endDate.month)}-${_twoDigits(request.endDate.day)}",
            "tujuan": request.details,
            "keterangan": "Atasan: $supervisorId",
          },
        );
        return responseData != null;
      } else {
        int jenisCutiId = 1;
        if (typeLower.contains("sakit")) jenisCutiId = 2;
        if (typeLower.contains("melahirkan")) jenisCutiId = 3;
        if (typeLower.contains("dinas luar")) jenisCutiId = 4;

        final responseData = await ApiClient.postMultipart(
          Uri.parse("${ApiClient.baseUrl}/api/leave/submit"),
          fields: {
            "nip": nip,
            "nidn": nidn,
            "jenis_cuti_id": jenisCutiId.toString(),
            "tanggal_mulai":
                "${request.startDate.year}-${_twoDigits(request.startDate.month)}-${_twoDigits(request.startDate.day)}",
            "tanggal_selesai":
                "${request.endDate.year}-${_twoDigits(request.endDate.month)}-${_twoDigits(request.endDate.day)}",
            "jumlah_hari":
                (request.endDate.difference(request.startDate).inDays + 1)
                    .toString(),
            "alasan": request.details,
            "nip_atasan": supervisorId,
          },
          fileFieldName: "file_lampiran",
          filePath: attachmentPath,
        );
        return responseData != null;
      }
    } catch (e, stackTrace) {
      debugPrint('[LeaveRepository submitLeave error]: $e\n$stackTrace');
      return false;
    }
  }

  @override
  Future<List<Supervisor>> getSupervisors() async {
    return _supervisors;
  }

  String _getMonthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "Mei",
      "Jun",
      "Jul",
      "Agu",
      "Sep",
      "Okt",
      "Nov",
      "Des"
    ];
    if (month < 1 || month > 12) return "";
    return months[month - 1];
  }

  String _twoDigits(int n) => n >= 10 ? "$n" : "0$n";
}
