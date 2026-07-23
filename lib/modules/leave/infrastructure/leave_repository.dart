import 'package:flutter/foundation.dart';
import 'package:hrportalv2/core/api_client.dart';
import 'package:hrportalv2/core/sso_helper.dart';
import '../domain/leave.dart';
import '../domain/leave_errors.dart';
import '../domain/i_leave_repository.dart';

class LeaveRepository implements ILeaveRepository {
  @override
  Future<List<LeaveRequest>> getLeaves() async {
    try {
      final session = await SsoHelper.getSession();
      if (session == null) return [];

      final List<LeaveRequest> allRequests = [];

      final results = await Future.wait([
        ApiClient.get(Uri.parse("${ApiClient.baseUrl}/api/leave"))
            .catchError((e) {
          debugPrint('[LeaveRepository fetch Cuti error]: $e');
          return null;
        }),
        ApiClient.get(Uri.parse("${ApiClient.baseUrl}/api/izin"))
            .catchError((e) {
          debugPrint('[LeaveRepository fetch Izin error]: $e');
          return null;
        }),
        ApiClient.get(Uri.parse("${ApiClient.baseUrl}/api/sppd/history"))
            .catchError((e) {
          debugPrint('[LeaveRepository fetch SPPD error]: $e');
          return null;
        }),
      ]);

      final cutiData = results[0];
      final izinData = results[1];
      final sppdData = results[2];

      final sessionName = session['name'] as String?;
      final sessionNip = session['nip'] as String?;
      final sessionNidn = session['nidn'] as String?;

      // 1. Process Cuti
      if (cutiData is List) {
        for (var json in cutiData) {
          final startStr = json['tanggal_mulai'] as String? ?? '';
          final endStr = json['tanggal_selesai'] as String? ?? '';
          final startDate =
              DateTime.tryParse(startStr)?.toLocal() ?? DateTime.now();
          final endDate =
              DateTime.tryParse(endStr)?.toLocal() ?? DateTime.now();
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
            applicantName: sessionName,
            applicantNip: sessionNip,
            applicantNidn: sessionNidn,
          ));
        }
      }

      // 2. Process Izin
      if (izinData is List) {
        for (var json in izinData) {
          final dateStr = json['tanggal_pengajuan'] as String? ?? '';
          final date = DateTime.tryParse(dateStr)?.toLocal() ?? DateTime.now();
          final jenisIzinId = json['id_jenis_izin'] as int? ?? 1;
          String type = "Izin Sakit";
          if (jenisIzinId == 2) type = "Izin Sakit Tanpa Dokter";
          if (jenisIzinId == 3) type = "Izin Melahirkan";
          if (jenisIzinId == 4) type = "Izin Keperluan Mendesak";

          allRequests.add(LeaveRequest(
            id: "izin_${json['id']}",
            type: type,
            status: json['status'] ?? 'Pengajuan',
            dateRange: "${date.day} ${_getMonthName(date.month)} ${date.year}",
            details: json['tujuan'] ?? '',
            note: json['catatan'] ?? 'Verifikasi Atasan',
            startDate: date,
            endDate: date,
            applicantName: sessionName,
            applicantNip: sessionNip,
            applicantNidn: sessionNidn,
          ));
        }
      }

      // 3. Process SPPD
      List sppdItems = [];
      if (sppdData is List) {
        sppdItems = sppdData;
      } else if (sppdData is Map<String, dynamic> && sppdData['data'] != null) {
        sppdItems = sppdData['data'] as List;
      }

      for (var json in sppdItems) {
        final startStr = json['tanggal_berangkat'] as String? ?? '';
        final endStr = json['tanggal_kembali'] as String? ?? '';
        final startDate =
            DateTime.tryParse(startStr)?.toLocal() ?? DateTime.now();
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
          note: json['catatan'] ?? json['keterangan'] ?? 'Menunggu verifikasi',
          startDate: startDate,
          endDate: endDate,
          applicantName: sessionName,
          applicantNip: sessionNip,
          applicantNidn: sessionNidn,
        ));
      }

      allRequests.sort((a, b) => b.startDate.compareTo(a.startDate));
      return allRequests;
    } catch (e, stackTrace) {
      debugPrint('[LeaveRepository getLeaves error]: $e\n$stackTrace');
    }
    return [];
  }

  @override
  Future<List<LeaveRequest>> getVerificationLeaves() async {
    try {
      final List<LeaveRequest> verificationRequests = [];

      final List<String> queryUrls = [];
      queryUrls.add("/api/leave?verifikasi=haxor");
      queryUrls.add("/api/izin?verifikasi=haxor");
      queryUrls.add("/api/sppd/history?verifikasi=haxor");

      final List<Future<dynamic>> futures = queryUrls.map((path) {
        return ApiClient.get(Uri.parse("${ApiClient.baseUrl}$path"))
            .catchError((e) {
          debugPrint(
              '[LeaveRepository fetch verification error for $path]: $e');
          return null;
        });
      }).toList();

      final responses = await Future.wait(futures);

      for (var i = 0; i < queryUrls.length; i++) {
        final path = queryUrls[i];
        final res = responses[i];
        if (res == null) continue;

        List items = [];
        if (res is List) {
          items = res;
        } else if (res is Map<String, dynamic> && res['data'] != null) {
          items = res['data'] as List;
        }

        for (var json in items) {
          final idStr = path.contains("sppd")
              ? "sppd_${json['id']}"
              : (path.contains("izin")
                  ? "izin_${json['id']}"
                  : "cuti_${json['id']}");

          if (verificationRequests.any((req) => req.id == idStr)) continue;

          final startStr = json['tanggal_mulai'] ??
              json['tanggal_pengajuan'] ??
              json['tanggal_berangkat'] ??
              '';
          final endStr =
              json['tanggal_selesai'] ?? json['tanggal_kembali'] ?? startStr;
          final startDate =
              DateTime.tryParse(startStr)?.toLocal() ?? DateTime.now();
          final endDate =
              DateTime.tryParse(endStr)?.toLocal() ?? DateTime.now();

          String type = "Cuti";
          if (path.contains("sppd")) {
            type = json['jenis_sppd_id'] == 2
                ? "SPPD - Dinas Dalam Kota"
                : "SPPD - Dinas Luar";
          } else if (path.contains("izin")) {
            type = "Izin";
          } else {
            type = "Cuti";
          }

          final appName = json['nama'] as String? ??
              json['nama_pegawai'] as String? ??
              json['nama_pemohon'] as String? ??
              json['user_nama'] as String?;
          final appNip = json['nip'] as String? ?? json['nip_pemohon'] as String?;
          final appNidn = json['nidn'] as String? ?? json['nidn_pemohon'] as String?;

          verificationRequests.add(LeaveRequest(
            id: idStr,
            type: type,
            status: json['status'] ?? 'Pengajuan',
            dateRange:
                "${startDate.day} - ${endDate.day} ${_getMonthName(startDate.month)} ${startDate.year}",
            details: json['alasan'] ?? json['tujuan'] ?? '',
            note: json['catatan_atasan'] ??
                json['catatan'] ??
                'Menunggu verifikasi',
            startDate: startDate,
            endDate: endDate,
            applicantName: (appName != null && appName.isNotEmpty) ? appName : null,
            applicantNip: (appNip != null && appNip.isNotEmpty) ? appNip : null,
            applicantNidn: (appNidn != null && appNidn.isNotEmpty) ? appNidn : null,
          ));
        }
      }

      verificationRequests.sort((a, b) => b.startDate.compareTo(a.startDate));
      return verificationRequests;
    } catch (e, stackTrace) {
      debugPrint(
          '[LeaveRepository getVerificationLeaves error]: $e\n$stackTrace');
    }
    return [];
  }

  @override
  Future<bool> submitLeave(
      LeaveRequest request, String supervisorId, String? attachmentPath) async {
    if (request.endDate.isBefore(request.startDate)) {
      throw const InvalidLeavePeriodError();
    }

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

        debugPrint(
            '{nip: $nip, nidn: $nidn, id_jenis_izin: $jenisIzinId, verifikasi: $supervisorId}');

        final responseData = await ApiClient.post(
          Uri.parse("${ApiClient.baseUrl}/api/izin/"),
          body: {
            "nip": nip,
            "nidn": nidn,
            "id_jenis_izin": jenisIzinId.toString(),
            "tanggal_pengajuan":
                "${request.startDate.year}-${_twoDigits(request.startDate.month)}-${_twoDigits(request.startDate.day)}",
            "tujuan": request.details,
            "verifikasi": supervisorId,
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
            "verifikasi": supervisorId,
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
            "verifikasi": supervisorId,
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
  Future<bool> updateLeaveStatus(String id, String status, String? note) async {
    try {
      final parts = id.split('_');
      if (parts.length < 2) return false;
      final prefix = parts[0];
      final realId = parts[1];

      if (prefix == 'cuti') {
        final res = await ApiClient.put(
          Uri.parse("${ApiClient.baseUrl}/api/leave/$realId"),
          body: {
            "status": status,
            "catatan_atasan": note ?? '',
          },
        );
        return res != null;
      } else if (prefix == 'izin') {
        final res = await ApiClient.put(
          Uri.parse("${ApiClient.baseUrl}/api/izin/$realId"),
          body: {
            "status": status,
            "catatan": note ?? '',
          },
        );
        return res != null;
      } else if (prefix == 'sppd') {
        final res = await ApiClient.put(
          Uri.parse("${ApiClient.baseUrl}/api/sppd/$realId"),
          body: {
            "status": status,
            "catatan": note ?? '',
          },
        );
        return res != null;
      }
    } catch (e, stackTrace) {
      debugPrint('[LeaveRepository updateLeaveStatus error]: $e\n$stackTrace');
    }
    return false;
  }

  @override
  Future<List<Supervisor>> getSupervisors() async {
    try {
      final responseData = await ApiClient.get(
        Uri.parse("${ApiClient.baseUrl}/api/masterdata/verifikator?type=cuti"),
      );
      if (responseData is List && responseData.isNotEmpty) {
        final List<Supervisor> list = [];
        for (var item in responseData) {
          final nip = item['nip']?.toString() ?? '';
          final nama = item['nama']?.toString() ?? '';
          final struktural = item['struktural']?.toString() ?? '';
          if (nip.isNotEmpty && nama.isNotEmpty) {
            list.add(Supervisor(
              id: nip,
              name: nama,
              role: struktural,
            ));
          }
        }
        if (list.isNotEmpty) return list;
      }
    } catch (e) {
      debugPrint('[LeaveRepository getSupervisors API error]: $e');
    }
    return [];
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
