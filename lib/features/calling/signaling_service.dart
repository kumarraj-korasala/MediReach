import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class SignalingService {
  static final SignalingService _instance = SignalingService._internal();
  factory SignalingService() => _instance;
  SignalingService._internal();

  WebSocketChannel? _channel;
  Timer? _pingTimer;

  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  bool get isConnected => _channel != null;
  String? myId;

  final Map<String, List<Map<String, dynamic>>> _bufferedCandidates = {};

  void connect({required String token, required String domain}) {
    myId = token;

    String cleanDomain = domain.trim();
    // Strip trailing slashes
    while (cleanDomain.endsWith('/')) {
      cleanDomain = cleanDomain.substring(0, cleanDomain.length - 1);
    }

    String scheme;
    if (cleanDomain.startsWith('wss://')) {
      scheme = '';
    } else if (cleanDomain.startsWith('ws://')) {
      scheme = '';
    } else if (cleanDomain.contains('ngrok') ||
        cleanDomain.contains('onrender.com') ||
        cleanDomain.contains('railway') ||
        cleanDomain.contains('loca.lt') ||
        cleanDomain.contains('fly.dev')) {
      scheme = 'wss://';
    } else {
      scheme = 'ws://';
    }

    // Strip http:// or https:// prefix if user pasted full web URL
    if (cleanDomain.startsWith('https://')) {
      cleanDomain = cleanDomain.replaceFirst('https://', 'wss://');
      scheme = '';
    } else if (cleanDomain.startsWith('http://')) {
      cleanDomain = cleanDomain.replaceFirst('http://', 'ws://');
      scheme = '';
    }

    final fullUrl = '$scheme$cleanDomain/ws/calls?token=${Uri.encodeComponent(token)}';
    debugPrint('Connecting to Signaling WebSocket URL: $fullUrl');

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse(fullUrl),
      );

      _startPingTimer();

      _channel!.stream.listen(
        (event) {
          try {
            final message = jsonDecode(event as String) as Map<String, dynamic>;
            final type = message['type'];
            final callId = message['callId'];

            if (type == 'pong') {
              return;
            }

            if (type == 'ice_candidate' && callId != null) {
              _bufferedCandidates
                  .putIfAbsent(callId as String, () => [])
                  .add(message);
            }

            _messageController.add(message);
          } catch (e) {
            debugPrint('Malformed signaling payload: $e');
          }
        },
        onError: (error) {
          debugPrint('Signaling WebSocket error: $error');
          _stopPingTimer();
          _channel = null;
          _messageController.add({
            'type': 'signaling_error',
            'error': error.toString(),
          });
        },
        onDone: () {
          debugPrint('Signaling WebSocket closed.');
          _stopPingTimer();
          _channel = null;
          _messageController.add({'type': 'signaling_closed'});
        },
      );
    } catch (e) {
      debugPrint('Failed to open WebSocket connection: $e');
      _channel = null;
      _messageController.add({
        'type': 'signaling_error',
        'error': e.toString(),
      });
    }
  }

  void _startPingTimer() {
    _stopPingTimer();
    _pingTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (isConnected) {
        send({'type': 'ping'});
      }
    });
  }

  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void send(Map<String, dynamic> message) {
    final channel = _channel;
    if (channel == null) {
      debugPrint('Cannot send message: WebSocket channel is null.');
      return;
    }
    try {
      channel.sink.add(jsonEncode(message));
    } catch (e) {
      debugPrint('Error sending signaling message: $e');
    }
  }

  void sendChatMessage({required String receiverId, required String text}) {
    send({'type': 'chat_message', 'to': receiverId, 'text': text});
  }

  void sendFileMessage({
    required String receiverId,
    required Map<String, dynamic> fileData,
  }) {
    send({
      'type': 'file_message',
      'to': receiverId,
      'fileData': fileData,
    });
  }

  void sendOffer({
    required String callId,
    required String receiverId,
    required String sdp,
    required bool isVideo,
  }) {
    send({
      'type': 'call_offer',
      'callId': callId,
      'to': receiverId,
      'sdp': sdp,
      'isVideo': isVideo,
    });
  }

  void sendAnswer({
    required String callId,
    required String receiverId,
    required String sdp,
  }) {
    send({
      'type': 'call_answer',
      'callId': callId,
      'to': receiverId,
      'sdp': sdp,
    });
  }

  void sendIceCandidate({
    required String callId,
    required String receiverId,
    required String candidate,
    String? sdpMid,
    int? sdpMLineIndex,
  }) {
    send({
      'type': 'ice_candidate',
      'callId': callId,
      'to': receiverId,
      'candidate': candidate,
      'sdpMid': sdpMid,
      'sdpMLineIndex': sdpMLineIndex,
    });
  }

  List<Map<String, dynamic>> drainBufferedCandidates(String callId) {
    final candidates = _bufferedCandidates.remove(callId);
    return candidates ?? [];
  }

  void clearBufferedCandidates(String callId) {
    _bufferedCandidates.remove(callId);
  }

  void acceptCall(String callId, {String? receiverId}) {
    send({
      'type': 'call_accept',
      'callId': callId,
      if (receiverId != null) ...{'to': receiverId},
    });
  }

  void rejectCall(String callId, {String? receiverId}) {
    send({
      'type': 'call_reject',
      'callId': callId,
      if (receiverId != null) ...{'to': receiverId},
    });
  }

  void endCall(String callId, {String? receiverId}) {
    send({
      'type': 'call_end',
      'callId': callId,
      if (receiverId != null) ...{'to': receiverId},
    });
  }

  void sendReconnect(String callId) {
    send({'type': 'call_reconnect', 'callId': callId});
  }

  Future<void> dispose() async {
    _stopPingTimer();
    await _messageController.close();
    await _channel?.sink.close();
    _channel = null;
  }
}
