import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/api_client.dart';
import '../../../core/sso_helper.dart';
import '../domain/i_report_repository.dart';
import '../domain/report_domain.dart';

class ReportRepository implements IReportRepository {
  String _twoDigits(int n) => n >= 10 ? "$n" : "0$n";

  String _formatDateKey(DateTime dt) {
    return "${dt.year}-${_twoDigits(dt.month)}-${_twoDigits(dt.day)}";
  }

  DateTime? _parseCleanDate(String? rawStr) {
    if (rawStr == null || rawStr.isEmpty) return null;
    final str = rawStr.trim();
    if (str.length >= 10) {
      final datePart = str.substring(0, 10);
      final parts = datePart.split('-');
      if (parts.length == 3) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final d = int.tryParse(parts[2]);
        if (y != null && m != null && d != null) {
          return DateTime(y, m, d);
        }
      }
    }
    final dt = DateTime.tryParse(str);
    return dt != null ? DateTime(dt.year, dt.month, dt.day) : null;
  }

  String _formatTimeStr(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';
    try {
      final dt = DateTime.tryParse(timeStr);
      if (dt != null) {
        return "${_twoDigits(dt.hour)}:${_twoDigits(dt.minute)}";
      }
      final parts = timeStr.split(' ');
      if (parts.length > 1) {
        final timePart = parts[1];
        final subParts = timePart.split(':');
        if (subParts.length >= 2) {
          return "${subParts[0]}:${subParts[1]}";
        }
      }
    } catch (_) {}
    return timeStr;
  }

  @override
  Future<Map<String, dynamic>> fetchLaporanMatrix(ReportPeriodFilter filter) async {
    final startStr = _formatDateKey(filter.startDate);
    final endStr = _formatDateKey(filter.endDate);

    try {
      final results = await Future.wait([
        ApiClient.get(
          Uri.parse("${ApiClient.baseUrl}/api/laporan/all?tanggal_mulai=$startStr&tanggal_akhir=$endStr"),
          timeout: const Duration(seconds: 45),
        ),
        ApiClient.get(
          Uri.parse("${ApiClient.baseUrl}/api/attendance/history?tanggal_mulai=$startStr&tanggal_akhir=$endStr&is_sdm=true"),
          timeout: const Duration(seconds: 45),
        ),
        ApiClient.get(
          Uri.parse("${ApiClient.baseUrl}/api/izin?tanggal_mulai=$startStr&tanggal_akhir=$endStr&role=sdm&is_sdm=true"),
          timeout: const Duration(seconds: 45),
        ),
        ApiClient.get(
          Uri.parse("${ApiClient.baseUrl}/api/leave?tanggal_mulai=$startStr&tanggal_akhir=$endStr&role=sdm&is_sdm=true"),
          timeout: const Duration(seconds: 45),
        ),
        ApiClient.get(
          Uri.parse("${ApiClient.baseUrl}/api/sppd/history?tanggal_mulai=$startStr&tanggal_akhir=$endStr&role=sdm&is_sdm=true"),
          timeout: const Duration(seconds: 45),
        ),
        ApiClient.get(
          Uri.parse("${ApiClient.baseUrl}/api/holiday"),
          timeout: const Duration(seconds: 45),
        ),
      ]);

      final laporanAllData = results[0];
      final attendanceData = results[1];
      final izinData = results[2];
      final cutiData = results[3];
      final sppdData = results[4];
      final holidayData = results[5];

      // Collect Holidays
      final Set<String> holidays = {};
      for (var item in _extractList(holidayData)) {
        if (item is Map<String, dynamic>) {
          final hDate = item['tanggal']?.toString() ?? '';
          if (hDate.isNotEmpty) holidays.add(hDate.length >= 10 ? hDate.substring(0, 10) : hDate);
        }
      }

      return _processParallelEndpointsResponse(
        laporanAllData: laporanAllData,
        attendanceData: attendanceData,
        izinData: izinData,
        cutiData: cutiData,
        sppdData: sppdData,
        filter: filter,
        holidays: holidays,
      );
    } catch (e) {
      debugPrint('[ReportRepository fetchLaporanMatrix error]: $e');
      rethrow;
    }
  }

  @override
  Stream<Map<String, dynamic>> streamLaporanMatrix(ReportPeriodFilter filter) async* {
    final startStr = _formatDateKey(filter.startDate);
    final endStr = _formatDateKey(filter.endDate);

    final Set<String> holidays = {};
    try {
      final hRes = await ApiClient.get(Uri.parse("${ApiClient.baseUrl}/api/holiday"));
      for (var item in _extractList(hRes)) {
        if (item is Map<String, dynamic>) {
          final hDate = item['tanggal']?.toString() ?? '';
          if (hDate.isNotEmpty) holidays.add(hDate.length >= 10 ? hDate.substring(0, 10) : hDate);
        }
      }
    } catch (_) {}

    final url = Uri.parse(
        "${ApiClient.baseUrl}/api/laporan/stream?tanggal_mulai=$startStr&tanggal_akhir=$endStr");

    final client = http.Client();
    final request = http.Request('GET', url);

    try {
      final session = await SsoHelper.getSession();
      if (session != null && session['token'] != null) {
        final token = session['token'] as String;
        if (token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      }
    } catch (_) {}

    try {
      final response = await client.send(request);
      final List<dynamic> accumulatedRecords = [];

      final stream = response.stream.transform(utf8.decoder).transform(const LineSplitter());

      DateTime lastYieldTime = DateTime.now();
      await for (final line in stream) {
        final trimmed = line.trim();
        if (trimmed.startsWith('data:')) {
          final jsonStr = trimmed.substring(5).trim();
          if (jsonStr.isNotEmpty) {
            try {
              final decoded = json.decode(jsonStr);
              if (decoded is List) {
                accumulatedRecords.addAll(decoded);
              } else if (decoded is Map<String, dynamic>) {
                accumulatedRecords.add(decoded);
              }
              final now = DateTime.now();
              if (now.difference(lastYieldTime).inMilliseconds >= 300) {
                lastYieldTime = now;
                yield _processLaporanAllStream(accumulatedRecords, filter, holidays);
              }
            } catch (_) {}
          }
        }
      }
      yield _processLaporanAllStream(accumulatedRecords, filter, holidays);
    } catch (e) {
      debugPrint('[ReportRepository stream error]: $e');
      final fallback = await fetchLaporanMatrix(filter);
      yield fallback;
    } finally {
      client.close();
    }
  }

  List _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      if (data['list_data'] is List) return data['list_data'] as List;
      if (data['records'] is List) return data['records'] as List;
      if (data['data'] is List) return data['data'] as List;
      if (data['versi_1_calendar'] is Map && data['versi_1_calendar']['list_data'] is List) {
        return data['versi_1_calendar']['list_data'] as List;
      }
    }
    return [];
  }

  Map<String, dynamic> _processParallelEndpointsResponse({
    required dynamic laporanAllData,
    required dynamic attendanceData,
    required dynamic izinData,
    required dynamic cutiData,
    required dynamic sppdData,
    required ReportPeriodFilter filter,
    required Set<String> holidays,
  }) {
    final List<PegawaiReportItem> employees = [];
    final Map<String, PegawaiReportItem> employeeMap = {};
    final Map<String, Map<String, ReportCellData>> cellMatrix = {};
    final Map<String, int> totalPresensiMap = {};

    final Map<String, String> nipToEmpId = {};
    final Map<String, String> nidnToEmpId = {};

    // Temporary event storage: Map<empId, Map<dateStr, List<Event>>>
    final Map<String, Map<String, List<Map<String, dynamic>>>> rawEventMap = {};

    void addRawEvent(String empId, String dateStr, Map<String, dynamic> event) {
      if (empId.isEmpty || dateStr.isEmpty) return;
      final cleanDate = dateStr.length >= 10 ? dateStr.substring(0, 10) : dateStr;
      rawEventMap.putIfAbsent(empId, () => {});
      rawEventMap[empId]!.putIfAbsent(cleanDate, () => []);
      rawEventMap[empId]![cleanDate]!.add(event);
    }

    void registerEmployee(Map<String, dynamic> empJson) {
      Map<String, dynamic> dataToParse = empJson;
      if (empJson['pengguna'] is Map<String, dynamic>) {
        dataToParse = empJson['pengguna'] as Map<String, dynamic>;
      }

      final pegawai = PegawaiReportItem.fromJson(dataToParse);
      final empId = pegawai.primaryId;
      if (empId.isNotEmpty) {
        if (!employeeMap.containsKey(empId)) {
          employeeMap[empId] = pegawai;
          employees.add(pegawai);
        }
        if (pegawai.nip.isNotEmpty) nipToEmpId[pegawai.nip] = empId;
        if (pegawai.nidn.isNotEmpty) nidnToEmpId[pegawai.nidn] = empId;
      }
    }

    String resolveEmpId(Map<String, dynamic> json) {
      final rawNip = json['nip']?.toString().trim() ?? '';
      final rawNidn = json['nidn']?.toString().trim() ?? '';
      final found = nipToEmpId[rawNip] ?? nidnToEmpId[rawNidn];
      if (found != null && found.isNotEmpty) return found;

      registerEmployee(json);
      return nipToEmpId[rawNip] ?? nidnToEmpId[rawNidn] ?? (rawNip.isNotEmpty ? rawNip : rawNidn);
    }

    // 1. Process Employee Master from laporanAllData
    for (var item in _extractList(laporanAllData)) {
      if (item is Map<String, dynamic>) {
        Map<String, dynamic>? empJson;
        if (item['pengguna'] is Map<String, dynamic>) {
          empJson = item['pengguna'] as Map<String, dynamic>;
        } else if (item['nama'] != null || item['nip'] != null || item['nidn'] != null) {
          empJson = item;
        }

        if (empJson != null) {
          registerEmployee(empJson);
          final empId = PegawaiReportItem.fromJson(empJson).primaryId;

          if (item['records'] is List) {
            final records = item['records'] as List;
            for (var rec in records) {
              if (rec is Map<String, dynamic>) {
                final dateStr = rec['tanggal']?.toString() ?? '';
                final recType = rec['type']?.toString() ?? '';
                final info = rec['info'] is Map<String, dynamic> ? rec['info'] as Map<String, dynamic> : <String, dynamic>{};
                final createdAt = rec['created_at'] != null || info['masuk'] != null
                    ? _parseCleanDate((rec['created_at'] ?? info['masuk'] ?? dateStr).toString())
                    : null;

                addRawEvent(empId, dateStr, {
                  'type': recType,
                  'info': info,
                  'timestamp': createdAt,
                });
              }
            }
          }
        }
      }
    }

    // 2. Process Attendance History Data
    for (var json in _extractList(attendanceData)) {
      if (json is! Map<String, dynamic>) continue;
      final empId = resolveEmpId(json);
      final dateStr = json['tanggal']?.toString() ?? '';
      final masukStr = json['absen_masuk']?.toString();
      final dt = masukStr != null ? _parseCleanDate(masukStr) : null;

      addRawEvent(empId, dateStr, {
        'type': 'absen',
        'info': {
          'masuk': json['absen_masuk'],
          'keluar': json['absen_keluar'],
          'catatan': json['note'] ?? json['catatan'],
        },
        'timestamp': dt,
      });
    }

    // 3. Process Izin Data
    for (var json in _extractList(izinData)) {
      if (json is! Map<String, dynamic>) continue;
      final empId = resolveEmpId(json);
      final dateStr = json['tanggal_pengajuan']?.toString() ?? json['tanggal']?.toString() ?? json['tanggal_mulai']?.toString() ?? '';
      final dt = json['created_at'] != null ? _parseCleanDate(json['created_at'].toString()) : null;

      addRawEvent(empId, dateStr, {
        'type': 'izin',
        'info': {
          'tujuan': json['tujuan'] ?? json['alasan'],
          'status': json['status'],
        },
        'timestamp': dt,
      });
    }

    // 4. Process Cuti (Leave) Data
    for (var json in _extractList(cutiData)) {
      if (json is! Map<String, dynamic>) continue;
      final empId = resolveEmpId(json);
      final startStr = json['tanggal_mulai']?.toString() ?? '';
      final endStr = (json['tanggal_selesai'] ?? json['tanggal_akhir'])?.toString() ?? startStr;

      final startDate = _parseCleanDate(startStr);
      final endDate = _parseCleanDate(endStr);
      final dt = json['created_at'] != null ? _parseCleanDate(json['created_at'].toString()) : null;

      if (startDate != null) {
        DateTime cur = startDate;
        final last = endDate ?? startDate;
        while (!cur.isAfter(last)) {
          final curStr = _formatDateKey(cur);
          addRawEvent(empId, curStr, {
            'type': 'cuti',
            'info': {
              'alasan': json['alasan'] ?? json['tujuan'],
              'status': json['status'],
            },
            'timestamp': dt,
          });
          cur = DateTime(cur.year, cur.month, cur.day + 1);
        }
      }
    }

    // 5. Process SPPD Data with Flattened 1D Anggota Array
    for (var json in _extractList(sppdData)) {
      if (json is! Map<String, dynamic>) continue;

      final mainEmpId = resolveEmpId(json);
      final sppdObj = json['sppd'] is Map<String, dynamic> ? json['sppd'] as Map<String, dynamic> : json;
      final startStr = (sppdObj['tanggal_berangkat'] ?? json['tanggal_berangkat'])?.toString() ?? '';
      final endStr = (sppdObj['tanggal_kembali'] ?? json['tanggal_kembali'])?.toString() ?? startStr;

      final startDate = _parseCleanDate(startStr);
      final endDate = _parseCleanDate(endStr);
      final dt = json['created_at'] != null ? _parseCleanDate(json['created_at'].toString()) : null;

      final List<String> memberEmpIds = [if (mainEmpId.isNotEmpty) mainEmpId];

      List anggotaList = [];
      if (json['anggota'] is List) {
        anggotaList = json['anggota'] as List;
      } else if (sppdObj['anggota'] is List) {
        anggotaList = sppdObj['anggota'] as List;
      }

      for (var memb in anggotaList) {
        if (memb is Map<String, dynamic>) {
          final mId = resolveEmpId(memb);
          if (mId.isNotEmpty && !memberEmpIds.contains(mId)) {
            memberEmpIds.add(mId);
          }
        }
      }

      for (var targetEmpId in memberEmpIds) {
        if (startDate != null) {
          DateTime cur = startDate;
          final last = endDate ?? startDate;
          while (!cur.isAfter(last)) {
            final curStr = _formatDateKey(cur);
            addRawEvent(targetEmpId, curStr, {
              'type': 'sppd',
              'info': {
                'tujuan': sppdObj['tujuan'],
                'maksud': sppdObj['maksud'] ?? sppdObj['keterangan'],
                'status': sppdObj['status'] ?? json['status'],
              },
              'timestamp': dt,
            });
            cur = DateTime(cur.year, cur.month, cur.day + 1);
          }
        }
      }
    }

    // Event Priority Helper
    int getEventPriority(Map<String, dynamic> event) {
      final typeLower = (event['type'] ?? '').toString().toLowerCase();
      final info = event['info'] is Map<String, dynamic> ? event['info'] as Map<String, dynamic> : <String, dynamic>{};
      final statusLower = (info['status'] ?? '').toString().toLowerCase();

      if (statusLower.contains('tolak')) return 0; // Rejected items ignored

      if (typeLower.contains('absen') || typeLower == 'masuk') {
        return 100; // Priority 1: Absen Umum
      } else if (typeLower.contains('izin')) {
        return 80;  // Priority 2: Izin (terima sdm)
      } else if (typeLower.contains('cuti')) {
        return 80;  // Priority 2: Cuti (terima sdm)
      } else if (typeLower.contains('sppd')) {
        return 80;  // Priority 2: SPPD (terima sdm)
      } else if (typeLower.contains('upacara')) {
        return 10;  // Upacara (low priority, does not override Izin/Cuti/SPPD/Absen)
      }
      return 1;
    }

    // 6. Build Final Matrix Grid & Calculate Presensi Totals
    final dateList = filter.dateList;

    if (filter.periodType == ReportPeriodType.annual) {
      for (var emp in employees) {
        final empId = emp.primaryId;
        cellMatrix[empId] = {};
        int annualTotal = 0;

        for (var dt in dateList) {
          final dateStr = _formatDateKey(dt);
          final monthPrefix = "${dt.year}-${dt.month < 10 ? '0${dt.month}' : '${dt.month}'}";
          int upacaraCount = 0;

          final empEvents = rawEventMap[empId] ?? {};
          empEvents.forEach((eventDateStr, events) {
            if (eventDateStr.startsWith(monthPrefix)) {
              for (var ev in events) {
                final typeLower = (ev['type'] ?? '').toString().toLowerCase();
                final info = ev['info'] is Map<String, dynamic> ? ev['info'] as Map<String, dynamic> : <String, dynamic>{};
                final noteLower = (info['catatan'] ?? info['note'] ?? info['kode'] ?? '').toString().toLowerCase();

                if (typeLower.contains('upacara') || noteLower.contains('upacara')) {
                  upacaraCount++;
                  break;
                }
              }
            }
          });

          annualTotal += upacaraCount;
          cellMatrix[empId]![dateStr] = ReportCellData(
            status: upacaraCount > 0 ? ReportCellStatus.absen : ReportCellStatus.tidakMasuk,
            text: upacaraCount > 0 ? "$upacaraCount" : "0",
          );
        }
        totalPresensiMap[empId] = annualTotal;
      }
    } else {
      for (var emp in employees) {
        final empId = emp.primaryId;
        cellMatrix[empId] = {};
        int presensiCount = 0;

        for (var dt in dateList) {
          final dateStr = _formatDateKey(dt);
          final isSunday = dt.weekday == DateTime.sunday;
          final isHoliday = holidays.contains(dateStr);

          final events = rawEventMap[empId]?[dateStr] ?? [];

          if (events.isEmpty) {
            if (isSunday || isHoliday) {
              cellMatrix[empId]![dateStr] = ReportCellData(
                status: ReportCellStatus.libur,
                text: isSunday ? 'Minggu' : 'Libur',
              );
            } else {
              cellMatrix[empId]![dateStr] = ReportCellData(
                status: ReportCellStatus.tidakMasuk,
                text: 'Alpa',
              );
            }
            continue;
          }

          // Sort events by priority score descending
          events.sort((a, b) {
            final pA = getEventPriority(a);
            final pB = getEventPriority(b);
            if (pA != pB) return pA.compareTo(pB);

            final tA = a['timestamp'] as DateTime? ?? DateTime(1970);
            final tB = b['timestamp'] as DateTime? ?? DateTime(1970);
            return tA.compareTo(tB);
          });

          final selectedEvent = events.last;
          final selectedPriority = getEventPriority(selectedEvent);

          if (selectedPriority <= 0) {
            cellMatrix[empId]![dateStr] = ReportCellData(
              status: isSunday || isHoliday ? ReportCellStatus.libur : ReportCellStatus.tidakMasuk,
              text: isSunday ? 'Minggu' : (isHoliday ? 'Libur' : 'Alpa'),
            );
            continue;
          }

          final typeLower = (selectedEvent['type'] ?? '').toString().toLowerCase();
          final info = selectedEvent['info'] is Map<String, dynamic>
              ? selectedEvent['info'] as Map<String, dynamic>
              : <String, dynamic>{};

          ReportCellStatus cellStatus = ReportCellStatus.absen;
          String cellText = '';
          String note = '';
          bool hasAnomaly = false;

          if (typeLower.contains('absen') || typeLower == 'masuk') {
            presensiCount++;
            final masuk = info['masuk'] != null
                ? _formatTimeStr(info['masuk'].toString())
                : '';
            final keluar = info['keluar'] != null
                ? _formatTimeStr(info['keluar'].toString())
                : '';

            cellText = masuk.isNotEmpty
                ? (keluar.isNotEmpty ? "$masuk - $keluar" : masuk)
                : "Absen";

            note = (info['catatan'] ?? info['note'] ?? info['kode'] ?? '').toString();
            if (note.contains('G') || note.contains('V') || note.contains('Verifikasi') || info['is_anomaly'] == true) {
              cellStatus = ReportCellStatus.absenAnomaly;
              hasAnomaly = true;
            } else {
              cellStatus = ReportCellStatus.absen;
            }
          } else if (typeLower.contains('izin')) {
            presensiCount++;
            cellStatus = ReportCellStatus.izin;
            cellText = 'Izin';
            note = (info['tujuan'] ?? info['alasan'] ?? '').toString();
          } else if (typeLower.contains('cuti')) {
            presensiCount++;
            cellStatus = ReportCellStatus.cuti;
            cellText = 'Cuti';
            note = (info['alasan'] ?? info['tujuan'] ?? '').toString();
          } else if (typeLower.contains('sppd')) {
            presensiCount++;
            cellStatus = ReportCellStatus.sppd;
            cellText = 'SPPD';
            note = (info['tujuan'] ?? info['maksud'] ?? '').toString();
          } else if (typeLower.contains('upacara')) {
            cellStatus = isSunday || isHoliday ? ReportCellStatus.libur : ReportCellStatus.tidakMasuk;
            cellText = isSunday ? 'Minggu' : (isHoliday ? 'Libur' : 'Alpa');
            note = 'Absen Upacara';
          } else {
            cellStatus = isSunday || isHoliday ? ReportCellStatus.libur : ReportCellStatus.tidakMasuk;
            cellText = isSunday ? 'Minggu' : (isHoliday ? 'Libur' : 'Alpa');
          }

          cellMatrix[empId]![dateStr] = ReportCellData(
            status: cellStatus,
            text: cellText,
            note: note,
            hasAnomaly: hasAnomaly,
            timestamp: selectedEvent['timestamp'] as DateTime?,
          );
        }

        totalPresensiMap[empId] = presensiCount;
      }
    }

    return {
      'employees': employees,
      'matrix': cellMatrix,
      'totalPresensi': totalPresensiMap,
      'holidays': holidays,
    };
  }

  Map<String, dynamic> _processLaporanAllStream(
    List<dynamic> accumulatedRecords,
    ReportPeriodFilter filter,
    Set<String> holidays,
  ) {
    return _processParallelEndpointsResponse(
      laporanAllData: accumulatedRecords,
      attendanceData: [],
      izinData: [],
      cutiData: [],
      sppdData: [],
      filter: filter,
      holidays: holidays,
    );
  }
}
