import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'api_client.dart';
import 'sso_helper.dart';
import 'location_wifi_helper.dart';

class NotificationModel {
  final String id;
  final String targetNip;
  final String title;
  final String body;
  final String type;
  final String status;
  final String createdAt;
  final Map<String, dynamic>? payload;

  NotificationModel({
    required this.id,
    required this.targetNip,
    required this.title,
    required this.body,
    required this.type,
    required this.status,
    required this.createdAt,
    this.payload,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? '',
      targetNip: json['target_nip'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: json['type'] as String? ?? '',
      status: json['status'] as String? ?? 'unread',
      createdAt: json['created_at'] as String? ?? '',
      payload: json['payload'] as Map<String, dynamic>?,
    );
  }
}

/// Client Service for Registering Device FCM Token & System Notification Drawer Integration
class FcmService {
  static const String firebaseProjectId = 'hrportal-71e0a';
  static const String vapidKey =
      'BFaK6w-3VQxC6gJsmW9i782akeR5tAuAIM068_-P0Ha6Luu5zKJd5DND3xpjegvYvdDJaaygsBlj4FEdXo2IFdk';

  static String? _currentFcmToken;
  static Timer? _foregroundPollTimer;
  static final Set<String> _shownNotificationIds = {};
  static String? _activeNip;

  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _isLocalNotifInitialized = false;

  /// Initializes system local notification drawer settings
  static Future<void> initLocalNotifications() async {
    if (_isLocalNotifInitialized) return;

    try {
      WidgetsFlutterBinding.ensureInitialized();
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        requestCriticalPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotificationsPlugin.initialize(initSettings);

      final androidPlugin =
          _localNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();

      final iosPlugin =
          _localNotificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
        critical: true,
      );

      const androidChannel = AndroidNotificationChannel(
        'hrportal_channel',
        'HR Portal Notifications',
        description: 'Notifications for attendance, leave, and approval status',
        importance: Importance.max,
        playSound: true,
      );
      await androidPlugin?.createNotificationChannel(androidChannel);

      const ongoingChannel = AndroidNotificationChannel(
        'hrportal_ongoing_channel',
        'HR Portal Presensi Latar Belakang',
        description:
            'Menampilkan status IP, GPS, dan area kampus secara terus-menerus',
        importance: Importance.low,
        playSound: false,
      );
      await androidPlugin?.createNotificationChannel(ongoingChannel);

      _isLocalNotifInitialized = true;
      debugPrint(
          '[FCM Service] Local notification drawer initialized successfully.');
    } catch (e) {
      debugPrint('[FCM Service Error] Local notification init failed: $e');
    }
  }

  /// Displays OS Native System Drawer Notification (Heads-Up Banner & Status Bar Icon)
  static Future<void> _showSystemDrawerNotification(
      NotificationModel notif) async {
    await initLocalNotifications();

    try {
      const androidDetails = AndroidNotificationDetails(
        'hrportal_channel',
        'HR Portal Notifications',
        channelDescription:
            'Notifications for attendance, leave, and approval status',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'HR Portal Notification',
        playSound: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentList: true,
        presentBadge: true,
        presentSound: true,
      );

      const platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final isAutoNotif = notif.title.contains('Presensi Otomatis') ||
          notif.type.contains('auto_attendance') ||
          notif.type.contains('attendance');
      final id = isAutoNotif ? 8888 : (notif.id.hashCode & 0x7FFFFFFF);

      await _localNotificationsPlugin.show(
        id,
        notif.title,
        notif.body,
        platformDetails,
      );
      debugPrint(
          '[FCM Service] System Notification Drawer pushed: ${notif.title}');
    } catch (e) {
      debugPrint(
          '[FCM Service Error] Failed pushing system notification drawer: $e');
    }
  }

  static final Set<String> _pushedCustomNotificationTitles = {};

  /// Pushes a custom local notification (e.g. background JWT refresh or auto-attendance result)
  static Future<void> showCustomNotification({
    required String title,
    required String body,
    bool force = false,
  }) async {
    final key = '$title|$body';
    if (!force && _pushedCustomNotificationTitles.contains(key)) {
      debugPrint(
          '[FCM Service] Custom notification "$title" already pushed in this session. Skipping duplicate.');
      return;
    }
    _pushedCustomNotificationTitles.add(key);

    await initLocalNotifications();
    try {
      const androidDetails = AndroidNotificationDetails(
        'hrportal_channel',
        'HR Portal Notifications',
        channelDescription:
            'Notifications for attendance, leave, and approval status',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'HR Portal Notification',
        playSound: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentList: true,
        presentBadge: true,
        presentSound: true,
      );

      const platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final isAuto =
          title.contains('Presensi Otomatis') || title.contains('Sesi');
      final id =
          isAuto ? 8888 : (DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF);

      await _localNotificationsPlugin.show(
        id,
        title,
        body,
        platformDetails,
      );
      debugPrint('[FCM Service] Custom Notification Pushed: $title');
    } catch (e) {
      debugPrint('[FCM Service Error] Failed pushing custom notification: $e');
    }
  }

  static const int ongoingNotifId = 9999;

  /// Pushes or updates a persistent/ongoing notification showing active IP & GPS info (cannot be swiped away/killed by user, like a VPN app)
  static Future<void> showOngoingStatusNotification({
    required String ip,
    required double lat,
    required double lon,
    required bool isInsideCampus,
    required bool isPakuanWifi,
    String? tokenTime,
  }) async {
    await initLocalNotifications();
    try {
      const androidDetails = AndroidNotificationDetails(
        'hrportal_ongoing_channel',
        'HR Portal Presensi Latar Belakang',
        channelDescription:
            'Menampilkan status IP, GPS, dan area kampus secara terus-menerus',
        importance: Importance.low,
        priority: Priority.high,
        ongoing: true,
        autoCancel: false,
        icon: '@mipmap/ic_launcher',
        showWhen: true,
        visibility: NotificationVisibility.public,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: false,
        presentBanner: true,
        presentList: true,
        presentBadge: true,
        presentSound: false,
      );

      const platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final wifiStatus =
          isPakuanWifi ? 'WiFi Pakuan (Kampus)' : 'Jaringan Luar';
      final campusStatus =
          isInsideCampus ? 'Dalam Area Kampus' : 'Luar Area Kampus';
      final latVal = lat != 0.0 ? lat : LocationWifiHelper.lastValidLat;
      final lonVal = lon != 0.0 ? lon : LocationWifiHelper.lastValidLon;
      final latStr = latVal.toStringAsFixed(5);
      final lonStr = lonVal.toStringAsFixed(5);
      final tokenInfo = tokenTime ?? SsoHelper.lastTokenRefreshTime;

      const title = 'HR Portal • Presensi Latar Belakang Active';
      final body =
          'IP: $ip ($wifiStatus)\nGPS: $latStr, $lonStr ($campusStatus)\nToken Status: Aktif (Update: $tokenInfo)';

      await _localNotificationsPlugin.show(
        ongoingNotifId,
        title,
        body,
        platformDetails,
      );
      debugPrint(
          '[FCM Service] Ongoing Status Notification Updated (IP: $ip, GPS: $latStr, $lonStr, Token: $tokenInfo)');
    } catch (e) {
      debugPrint(
          '[FCM Service Error] Failed updating ongoing status notification: $e');
    }
  }

  static Future<void> cancelOngoingNotification() async {
    try {
      await _localNotificationsPlugin.cancel(ongoingNotifId);
      debugPrint('[FCM Service] Ongoing Status Notification Cancelled.');
    } catch (_) {}
  }

  /// Returns or generates a mock/device FCM Token for testing & production
  static String get fcmToken {
    _currentFcmToken ??=
        'fcm_token_device_${DateTime.now().millisecondsSinceEpoch}_hrportal';
    return _currentFcmToken!;
  }

  static bool isSdmUser = false;
  static String? _lastRegisteredNip;

  /// Registers user NIP with backend FCM Token registry and starts Foreground Listener
  static Future<bool> registerFcmToken(String nip, {bool isSdm = false}) async {
    if (nip.isEmpty) return false;
    _activeNip = nip;
    isSdmUser = isSdm;
    if (_lastRegisteredNip == nip) {
      // Already registered in this app session, just ensure listener is running
      startForegroundNotificationListener(nip);
      return true;
    }
    try {
      final url = Uri.parse('${ApiClient.baseUrl}/api/account/fcm-token');
      debugPrint(
          '[FCM Service] Registering FCM token for NIP: $nip (isSdm: $isSdm)');
      final response = await http.post(
        url,
        body: {
          'nip': nip,
          'fcm_token': fcmToken,
          if (isSdm) 'is_sdm': 'true',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        _lastRegisteredNip = nip;
        debugPrint('[FCM Service] FCM Token registered on server for NIP $nip');
        startForegroundNotificationListener(nip);
        return true;
      }
    } catch (e) {
      debugPrint('[FCM Service Error] Register FCM token failed: $e');
    }
    startForegroundNotificationListener(nip);
    return false;
  }

  /// Starts listening to real-time notifications in foreground (when app is OPEN)
  static void startForegroundNotificationListener(String nip) {
    if (nip.isEmpty) return;
    _activeNip = nip;
    _foregroundPollTimer?.cancel();

    // Poll every 2 seconds for new foreground notifications from server
    _foregroundPollTimer =
        Timer.periodic(const Duration(seconds: 2), (timer) async {
      checkAndShowLatestNotifications();
    });

    // Run immediate check
    checkAndShowLatestNotifications();
  }

  /// Checks for unshown notifications targeted for the active user NIP and pushes System Drawer Notifications
  static Future<void> checkAndShowLatestNotifications() async {
    if (_activeNip == null || _activeNip!.isEmpty) return;
    final notifications = await fetchNotifications(_activeNip!);
    if (notifications.isEmpty) return;

    for (var notif in notifications) {
      if (!_shownNotificationIds.contains(notif.id)) {
        _shownNotificationIds.add(notif.id);
        _showSystemDrawerNotification(notif);
        markNotificationAsDone(notif.id);
      }
    }
  }

  /// Marks notification status as done on server
  static Future<void> markNotificationAsDone(String id) async {
    try {
      final url =
          Uri.parse('${ApiClient.baseUrl}/api/account/notifications/mark-done');
      await http
          .post(url, body: {'id': id}).timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  /// Fetches in-app notification history for a specific NIP
  static Future<List<NotificationModel>> fetchNotifications(String nip) async {
    if (nip.isEmpty) return [];
    try {
      final url = Uri.parse(
          '${ApiClient.baseUrl}/api/account/notifications?nip=$nip${isSdmUser ? "&is_sdm=true" : ""}');
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final List<dynamic> list = body['data'] as List<dynamic>? ?? [];
        final items = list
            .map((item) =>
                NotificationModel.fromJson(item as Map<String, dynamic>))
            .toList();

        // Client-side safeguard: Filter out verification request notifications
        // intended for supervisors (e.g. "Pegawai NIP X mengajukan... Mohon verifikasi")
        // if current active NIP is the applicant (X).
        return items.where((notif) {
          final isVerificationRequest =
              notif.title.toLowerCase().contains('pengajuan') ||
                  notif.body.toLowerCase().contains('mohon verifikasi');
          if (isVerificationRequest && notif.body.contains(nip)) {
            // Current user is the applicant, not the verifier -> do not notify applicant
            return false;
          }
          return true;
        }).toList();
      }
    } catch (e) {
      debugPrint('[FCM Service Error] Fetch notifications failed: $e');
    }
    return [];
  }

  static void stopListener() {
    _foregroundPollTimer?.cancel();
  }
}
