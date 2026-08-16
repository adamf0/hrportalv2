import 'package:flutter/foundation.dart';
import 'package:hrportalv2/core/api_client.dart';

class LeaveFormData {
  static List<Map<String, String>> _cutiTypes = [];
  static List<Map<String, String>> _izinTypes = [];
  static List<Map<String, String>> _sppdTypes = [];

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
            final maxHari =
                (item['maks_hari'] ?? item['quota'] ?? item['max'] ?? '')
                    .toString();

            if (name.isNotEmpty) {
              loadedCuti.add({
                'value': val,
                'name': name,
                'desc': "",
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
      debugPrint(
          '[LeaveFormData] Error fetching jenis-cuti from $unpakBase: $e');
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
      debugPrint(
          '[LeaveFormData] Error fetching jenis-izin from $unpakBase: $e');
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
      debugPrint(
          '[LeaveFormData] Error fetching jenis-sppd from $unpakBase: $e');
    }

    _isLoading = false;
    _hasLoaded = true;
  }
}
