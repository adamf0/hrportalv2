import 'package:flutter/foundation.dart';
import 'package:hrportalv2/core/api_client.dart';

class LeaveFormData {
  static List<Map<String, String>> _cutiTypes = defaultCutiTypes;
  static List<Map<String, String>> _izinTypes = defaultIzinTypes;
  static List<Map<String, String>> _sppdTypes = defaultSppdTypes;

  static List<Map<String, String>> get cutiTypes => _cutiTypes;
  static List<Map<String, String>> get izinTypes => _izinTypes;
  static List<Map<String, String>> get sppdTypes => _sppdTypes;

  static bool _hasLoaded = false;
  static bool _isLoading = false;

  static bool get hasLoaded => _hasLoaded;
  static bool get isLoading => _isLoading;

  /// Load masterdata dynamically from backendUnpak endpoints using baseUrlUnpak
  static Future<void> loadMasterData({bool forceRefresh = false}) async {
    if (_hasLoaded && !forceRefresh) return;

    _isLoading = true;
    final unpakBase = ApiClient.baseUrlUnpak;

    // 1. Fetch Jenis Cuti (/masterdata/jenis-cuti)
    try {
      final resCuti = await ApiClient.get(
        Uri.parse('$unpakBase/masterdata/jenis-cuti'),
        scope: 'global',
      );
      if (resCuti is List && resCuti.isNotEmpty) {
        final List<Map<String, String>> loadedCuti = [];
        for (var item in resCuti) {
          if (item is Map) {
            final val = (item['id'] ?? item['value'] ?? '').toString();
            final name = (item['nama'] ?? item['name'] ?? '').toString();
            final desc = (item['deskripsi'] ?? item['desc'] ?? '').toString();
            final maxHari =
                (item['maks_hari'] ?? item['quota'] ?? item['max'] ?? '')
                    .toString();

            if (name.isNotEmpty) {
              loadedCuti.add({
                'value': val,
                'name': name,
                'desc': desc.isNotEmpty
                    ? desc
                    : 'Hak cuti pegawai berdasarkan peraturan kampus.',
                'max': maxHari.isNotEmpty && maxHari != '0'
                    ? '$maxHari Hari'
                    : 'Maksimal Kuota',
              });
            }
          }
        }
        if (loadedCuti.isNotEmpty) {
          _cutiTypes = loadedCuti;
        }
      }
    } catch (e) {
      debugPrint('[LeaveFormData] Error fetching jenis-cuti from $unpakBase: $e');
    }

    // 2. Fetch Jenis Izin (/masterdata/jenis-izin)
    try {
      final resIzin = await ApiClient.get(
        Uri.parse('$unpakBase/masterdata/jenis-izin'),
        scope: 'global',
      );
      if (resIzin is List && resIzin.isNotEmpty) {
        final List<Map<String, String>> loadedIzin = [];
        for (var item in resIzin) {
          if (item is Map) {
            final val = (item['id'] ?? item['value'] ?? '').toString();
            final name = (item['nama'] ?? item['name'] ?? '').toString();
            if (name.isNotEmpty) {
              loadedIzin.add({'value': val, 'name': name});
            }
          }
        }
        if (loadedIzin.isNotEmpty) {
          _izinTypes = loadedIzin;
        }
      }
    } catch (e) {
      debugPrint('[LeaveFormData] Error fetching jenis-izin from $unpakBase: $e');
    }

    // 3. Fetch Jenis SPPD (/masterdata/jenis-sppd)
    try {
      final resSppd = await ApiClient.get(
        Uri.parse('$unpakBase/masterdata/jenis-sppd'),
        scope: 'global',
      );
      if (resSppd is List && resSppd.isNotEmpty) {
        final List<Map<String, String>> loadedSppd = [];
        for (var item in resSppd) {
          if (item is Map) {
            final val = (item['id'] ?? item['value'] ?? '').toString();
            final name = (item['nama'] ?? item['name'] ?? '').toString();
            if (name.isNotEmpty) {
              loadedSppd.add({'value': val, 'name': name});
            }
          }
        }
        if (loadedSppd.isNotEmpty) {
          _sppdTypes = loadedSppd;
        }
      }
    } catch (e) {
      debugPrint('[LeaveFormData] Error fetching jenis-sppd from $unpakBase: $e');
    }

    _isLoading = false;
    _hasLoaded = true;
  }

  static const List<Map<String, String>> defaultCutiTypes = [
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
      'desc': 'Cuti untuk menikahkan child kandung pegawai.',
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

  static const List<Map<String, String>> defaultIzinTypes = [
    {'value': '1', 'name': 'Izin Sakit'},
    {'value': '2', 'name': 'Izin Sakit Tanpa Dokter'},
    {'value': '3', 'name': 'Izin Melahirkan'},
    {'value': '4', 'name': 'Izin Keperluan Mendesak'},
    {'value': '5', 'name': 'Sakit'},
    {'value': '6', 'name': 'Keperluan Keluarga'},
    {'value': '7', 'name': 'Dinas Luar Kantor'},
    {'value': '8', 'name': 'Tugas Penunjang Tri Darma'},
    {'value': '9', 'name': 'Tugas Belajar (Studi Lanjut)'},
  ];

  static const List<Map<String, String>> defaultSppdTypes = [
    {'value': '1', 'name': 'SPPD - Dinas Luar'},
    {'value': '2', 'name': 'SPPD - Dinas Dalam Kota'},
    {'value': '3', 'name': 'Dinas Luar'},
    {'value': '4', 'name': 'Dinas Dalam Kota'},
    {'value': '5', 'name': 'Perjalanan Dinas Dalam Negeri'},
    {'value': '6', 'name': 'Perjalanan Dinas Luar Negeri'},
    {'value': '7', 'name': 'Dinas Rapat / Koordinasi'},
    {'value': '8', 'name': 'Tugas Penunjang Tri Darma'},
  ];
}
