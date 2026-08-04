import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_client.dart';

class AttendanceRealtimeService {
  static final AttendanceRealtimeService _instance = AttendanceRealtimeService._internal();
  factory AttendanceRealtimeService() => _instance;
  AttendanceRealtimeService._internal();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get stream => _controller.stream;
  String _activeKey = '';
  String _activeNip = '';
  String _activeNidn = '';

  void forceReconnect(String nip, String nidn) {
    _activeKey = '';
    connect(nip, nidn);
  }

  void connect(String nip, String nidn) {
    if (nip.isEmpty && nidn.isEmpty) return;
    final key = '$nip:$nidn';
    if (_activeKey == key && _channel != null) return;

    _activeKey = key;
    _activeNip = nip;
    _activeNidn = nidn;
    disconnect();

    try {
      final baseUri = Uri.parse(ApiClient.baseUrl);
      final wsScheme = baseUri.scheme == 'https' ? 'wss' : 'ws';
      final wsUrl = Uri.parse('$wsScheme://${baseUri.authority}/ws/attendance?nip=$nip&nidn=$nidn');

      debugPrint('[AttendanceRealtimeService]: Connecting to $wsUrl');
      _channel = WebSocketChannel.connect(wsUrl);

      _subscription = _channel!.stream.listen(
        (data) {
          try {
            if (data is String) {
              final jsonMap = jsonDecode(data) as Map<String, dynamic>;
              _controller.add(jsonMap);
            }
          } catch (e) {
            debugPrint('[AttendanceRealtimeService parse error]: $e');
          }
        },
        onError: (error) {
          debugPrint('[AttendanceRealtimeService error]: $error');
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('[AttendanceRealtimeService]: WebSocket connection closed.');
        },
      );
    } catch (e) {
      debugPrint('[AttendanceRealtimeService connect exception]: $e');
    }
  }

  void _scheduleReconnect() {
    final nip = _activeNip;
    final nidn = _activeNidn;
    if (nip.isEmpty && nidn.isEmpty) return;
    Future.delayed(const Duration(seconds: 5), () {
      if (_activeNip == nip && _activeNidn == nidn) {
        connect(nip, nidn);
      }
    });
  }

  void disconnect() {
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
    _activeKey = '';
  }
}
