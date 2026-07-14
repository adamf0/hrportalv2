import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

abstract class LocationValidationStrategy {
  bool isWithinCampus(double latitude, double longitude);
  String get name;
}

class RadiusValidationStrategy implements LocationValidationStrategy {
  @override
  final String name = "Radius (<= 500 meter)";

  @override
  bool isWithinCampus(double latitude, double longitude) {
    final distance = LocationWifiHelper.calculateDistance(
      latitude,
      longitude,
      LocationWifiHelper.pakuanLatitude,
      LocationWifiHelper.pakuanLongitude,
    );
    return distance <= 500;
  }
}

class PolygonValidationStrategy implements LocationValidationStrategy {
  @override
  final String name = "Poligon Kampus (Poligon 1 & 2)";

  @override
  bool isWithinCampus(double latitude, double longitude) {
    // Check if coordinates are inside Polygon 1 or Polygon 2
    final inPoly1 = LocationWifiHelper.isPointInPolygon(latitude, longitude, LocationWifiHelper.polygon1);
    final inPoly2 = LocationWifiHelper.isPointInPolygon(latitude, longitude, LocationWifiHelper.polygon2);
    return inPoly1 || inPoly2;
  }
}

class LocationWifiHelper {
  // Universitas Pakuan coordinates
  static const double pakuanLatitude = -6.600109;
  static const double pakuanLongitude = 106.814324;

  // Polygons Coordinates (GeoJSON formatted: [longitude, latitude])
  static const List<List<double>> polygon1 = [
    [106.8089733, -6.5984852],
    [106.8089173, -6.5993229],
    [106.809273, -6.5993556],
    [106.8092961, -6.5994472],
    [106.809273, -6.5996828],
    [106.8092829, -6.5998628],
    [106.8096716, -6.5998824],
    [106.810136, -6.5998988],
    [106.8101756, -6.5986096],
    [106.8095497, -6.5985343],
    [106.8090523, -6.5984721],
    [106.8089733, -6.5984852]
  ];

  static const List<List<double>> polygon2 = [
    [106.8106493, -6.5989928],
    [106.810552, -6.5998848],
    [106.8108581, -6.6006916],
    [106.8114206, -6.6009082],
    [106.8121401, -6.6003234],
    [106.8130341, -6.599704],
    [106.8125457, -6.5990066],
    [106.8121738, -6.5988939],
    [106.8112655, -6.5987491],
    [106.8107011, -6.598686],
    [106.8106493, -6.5989928]
  ];

  static const List<List<double>> polygon3 = [
    [106.8116777, -6.599617],
    [106.8116367, -6.5999715],
    [106.8120327, -6.6003358],
    [106.8127173, -6.5998262],
    [106.8122277, -6.5991229],
    [106.811781, -6.5992275],
    [106.8116777, -6.599617]
  ];

  // Point in Polygon algorithm (Ray-Casting)
  static bool isPointInPolygon(double lat, double lon, List<List<double>> polygon) {
    bool inside = false;
    int j = polygon.length - 1;
    for (int i = 0; i < polygon.length; i++) {
      double xi = polygon[i][0]; // longitude
      double yi = polygon[i][1]; // latitude
      double xj = polygon[j][0]; // longitude
      double yj = polygon[j][1]; // latitude

      bool intersect = ((yi > lat) != (yj > lat)) &&
          (lon < (xj - xi) * (lat - yi) / (yj - yi) + xi);
      if (intersect) inside = !inside;
      j = i;
    }
    return inside;
  }

  // Indonesian National Holidays Checklist (Sundays & Mapped Holidays for 2025/2026/2027)
  static bool isIndonesianHoliday(DateTime date) {
    if (date.weekday == DateTime.sunday || date.weekday == DateTime.saturday) return true;

    final year = date.year;
    final month = date.month;
    final day = date.day;

    // Fixed-date holidays
    if (month == 1 && day == 1) return true; // Tahun Baru
    if (month == 5 && day == 1) return true; // Hari Buruh
    if (month == 6 && day == 1) return true; // Lahir Pancasila
    if (month == 8 && day == 17) return true; // Kemerdekaan RI
    if (month == 12 && day == 25) return true; // Natal

    final holidayKey = "$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
    const Set<String> holidays = {
      // 2025 Mapped Holidays
      "2025-01-29", "2025-01-27", "2025-03-29", "2025-03-31", "2025-04-01",
      "2025-04-18", "2025-05-12", "2025-05-29", "2025-06-06", "2025-06-27",
      "2025-09-05",
      
      // 2026 Mapped Holidays
      "2026-02-17", "2026-02-15", "2026-03-19", "2026-03-20", "2026-03-21",
      "2026-04-03", "2026-05-14", "2026-05-27", "2026-05-31", "2026-06-16",
      "2026-08-25",
      
      // 2027 Mapped Holidays
      "2027-02-06", "2027-02-04", "2027-03-09", "2027-03-10",
      "2027-03-26", "2027-05-06", "2027-05-16", "2027-05-20", "2027-06-06",
      "2027-08-15"
    };

    return holidays.contains(holidayKey);
  }

  // Checks if the IP address matches Pakuan campus network rules:
  // Matches "103.169" (IPv4) or "2001:df0:3140" (IPv6)
  static bool isPakuanIp(String ipAddress) {
    return ipAddress.contains('103.169') || ipAddress.contains('2001:df0:3140');
  }

  // Calculate distance in meters using Haversine formula
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double r = 6371000; // Earth radius in meters
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  static double _toRadians(double degree) {
    return degree * pi / 180;
  }

  static String _cachedPublicIp = "127.0.0.1";
  static bool _isFetchingPublicIp = false;

  // Helper to fetch local network interfaces immediately
  static Future<String> getLocalInterfaceIp() async {
    try {
      final interfaces = await NetworkInterface.list();
      for (var interface in interfaces) {
        final name = interface.name.toLowerCase();
        if (name.contains('wlan') || name.contains('en') || name.contains('wifi')) {
          for (var addr in interface.addresses) {
            if (!addr.isLoopback) {
              return addr.address;
            }
          }
        }
      }
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return "127.0.0.1";
  }

  // Asynchronously updates the public IP cache in the background
  static void _updatePublicIpCacheInBackground() {
    if (_isFetchingPublicIp) return;
    _isFetchingPublicIp = true;

    http.get(Uri.parse('https://api.ipify.org')).timeout(
      const Duration(seconds: 2),
    ).then((response) {
      _isFetchingPublicIp = false;
      if (response.statusCode == 200) {
        _cachedPublicIp = response.body.trim();
      }
    }).catchError((_) {
      _isFetchingPublicIp = false;
    });
  }

  // Awaits the public IP check with a short timeout
  static Future<String> getPublicIpWithTimeoutFallback() async {
    try {
      final response = await http.get(Uri.parse('https://api.ipify.org')).timeout(
        const Duration(milliseconds: 1500),
      );
      if (response.statusCode == 200) {
        final ip = response.body.trim();
        _cachedPublicIp = ip;
        return ip;
      }
    } catch (_) {}
    return await getLocalInterfaceIp();
  }

  // Get active device IP
  static Future<String> getActiveDeviceIp() async {
    _updatePublicIpCacheInBackground();
    if (_cachedPublicIp != "127.0.0.1") {
      return _cachedPublicIp;
    }
    return await getLocalInterfaceIp();
  }

  // Get active device GPS coordinates
  static Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          return null;
        }
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (_) {
      return null;
    }
  }
}
