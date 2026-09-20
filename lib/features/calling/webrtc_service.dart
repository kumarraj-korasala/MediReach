import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

enum NetworkMode {
  auto5G, // 5G High Speed: 720p/1080p, 30fps, 2.5Mbps max bitrate
  mode4G, // 4G Standard: 480p, 24fps, 800kbps max bitrate
  mode3G, // 3G Data Saver: 240p/360p, 15fps, 250kbps max bitrate
  audioOnly, // Voice Only: turns off video streams to preserve clear voice on edge networks
}

class WebRTCService {
  // Configurable TURN credentials (Metered.ca uses .metered.live app endpoints)
  static const String turnDomain = 'medicare.metered.live';
  static const String turnUsername = '98f4479d97ffae99d5c70f39';
  static const String turnCredential = 'SNkkmgO5VTjKCofI';

  RTCPeerConnection? peerConnection;
  MediaStream? localStream;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  bool isVideoCall = false;
  NetworkMode currentNetworkMode = NetworkMode.auto5G;

  // Queue candidates if they arrive before setRemoteDescription()
  final List<RTCIceCandidate> _pendingIceCandidates = [];
  bool _hasRemoteDescription = false;

  Future<void> initialize() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  Future<void> createConnection({
    required bool video,
    required void Function(RTCIceCandidate candidate) onIceCandidate,
    required void Function(RTCPeerConnectionState state) onConnectionState,
  }) async {
    isVideoCall = video;

    final iceServers = <Map<String, dynamic>>[
      {
        'urls': [
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
          'stun:stun3.l.google.com:19302',
          'stun:stun4.l.google.com:19302',
          'stun:stun.services.mozilla.com',
        ],
      },
    ];

    if (turnDomain.isNotEmpty &&
        turnUsername.isNotEmpty &&
        turnCredential.isNotEmpty) {
      iceServers.add({
        'urls': [
          'stun:$turnDomain:80',
          'stun:$turnDomain:443',
          'turn:$turnDomain:80',
          'turn:$turnDomain:443',
          'turn:$turnDomain:443?transport=tcp',
          'turns:$turnDomain:443',
          'turns:$turnDomain:443?transport=tcp',
        ],
        'username': turnUsername,
        'credential': turnCredential,
      });
    } else {
      iceServers.add({
        'urls': [
          'turn:relay.metered.ca:80',
          'turn:relay.metered.ca:443',
          'turn:relay.metered.ca:443?transport=tcp',
        ],
        'username': 'openrelay',
        'credential': 'openrelay',
      });
    }

    final configuration = {
      'iceServers': iceServers,
      'sdpSemantics': 'unified-plan',
      'iceTransportPolicy': 'all',
    };

    peerConnection = await createPeerConnection(configuration);

    peerConnection!.onIceCandidate = onIceCandidate;
    peerConnection!.onConnectionState = onConnectionState;

    peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams[0];
      }
    };

    peerConnection!.onIceConnectionState = (state) {
      debugPrint('ICE connection state: $state');
    };

    peerConnection!.onSignalingState = (state) {
      debugPrint('Signaling state: $state');
    };
  }

  Future<void> openLocalMedia() async {
    // Request permissions
    await Permission.microphone.request();
    if (isVideoCall) {
      await Permission.camera.request();
    }

    final constraints = {
      'audio': true,
      'video': isVideoCall
          ? {
              'facingMode': 'user',
              'width': {'ideal': 640},
              'height': {'ideal': 480},
              'frameRate': {'ideal': 24, 'max': 30},
            }
          : false,
    };

    localStream = await navigator.mediaDevices.getUserMedia(constraints);
    localRenderer.srcObject = localStream;

    for (final track in localStream!.getTracks()) {
      track.enabled = true;
      if (peerConnection != null) {
        await peerConnection!.addTrack(track, localStream!);
      }
    }
  }

  Future<RTCSessionDescription> createOffer() async {
    final offer = await peerConnection!.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': isVideoCall,
    });

    await peerConnection!.setLocalDescription(offer);
    return offer;
  }

  Future<RTCSessionDescription> createAnswer() async {
    final answer = await peerConnection!.createAnswer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': isVideoCall,
    });

    await peerConnection!.setLocalDescription(answer);
    return answer;
  }

  Future<void> setRemoteDescription(RTCSessionDescription description) async {
    await peerConnection!.setRemoteDescription(description);
    _hasRemoteDescription = true;

    for (final candidate in _pendingIceCandidates) {
      await peerConnection!.addCandidate(candidate);
    }
    _pendingIceCandidates.clear();
  }

  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    if (_hasRemoteDescription && peerConnection != null) {
      await peerConnection!.addCandidate(candidate);
    } else {
      _pendingIceCandidates.add(candidate);
    }
  }

  Future<void> muteMicrophone(bool muted) async {
    final stream = localStream;
    if (stream == null) return;

    for (final track in stream.getAudioTracks()) {
      track.enabled = !muted;
    }
  }

  Future<void> enableVideo(bool enabled) async {
    final stream = localStream;
    if (stream == null) return;

    for (final track in stream.getVideoTracks()) {
      track.enabled = enabled;
    }
  }

  Future<void> switchCamera() async {
    final stream = localStream;
    if (stream == null) return;

    final tracks = stream.getVideoTracks();
    if (tracks.isEmpty) return;

    await Helper.switchCamera(tracks.first);
  }

  Future<void> setSpeaker(bool enabled) async {
    await Helper.setSpeakerphoneOn(enabled);
  }

  Future<void> restartIce() async {
    await peerConnection?.restartIce();
  }

  /// Adapt video quality and bitrate dynamic controls for 3G, 4G, 5G, or Audio-Only
  Future<void> setNetworkProfile(NetworkMode mode) async {
    currentNetworkMode = mode;
    final pc = peerConnection;
    if (pc == null) return;

    if (mode == NetworkMode.audioOnly) {
      await enableVideo(false);
      return;
    } else if (isVideoCall) {
      await enableVideo(true);
    }

    int maxBitrate;
    int maxFramerate;
    double scaleResolutionDownBy;

    switch (mode) {
      case NetworkMode.auto5G:
        maxBitrate = 2500000; // 2.5 Mbps
        maxFramerate = 30;
        scaleResolutionDownBy = 1.0;
        break;
      case NetworkMode.mode4G:
        maxBitrate = 800000; // 800 kbps
        maxFramerate = 24;
        scaleResolutionDownBy = 1.25;
        break;
      case NetworkMode.mode3G:
        maxBitrate = 250000; // 250 kbps
        maxFramerate = 15;
        scaleResolutionDownBy = 2.0;
        break;
      case NetworkMode.audioOnly:
        return;
    }

    await setVideoQuality(
      maxBitrate: maxBitrate,
      maxFramerate: maxFramerate,
      scaleResolutionDownBy: scaleResolutionDownBy,
    );
  }

  Future<void> setVideoQuality({
    required int maxBitrate,
    required int maxFramerate,
    required double scaleResolutionDownBy,
  }) async {
    final pc = peerConnection;
    if (pc == null) return;

    final senders = await pc.getSenders();
    for (final sender in senders) {
      if (sender.track?.kind != 'video') {
        continue;
      }

      final parameters = sender.parameters;
      if (parameters.encodings == null || parameters.encodings!.isEmpty) {
        continue;
      }

      final encoding = parameters.encodings!.first;
      encoding.maxBitrate = maxBitrate;
      encoding.maxFramerate = maxFramerate;
      encoding.scaleResolutionDownBy = scaleResolutionDownBy;

      await sender.setParameters(parameters);
    }
  }

  Future<void> dispose() async {
    try {
      _pendingIceCandidates.clear();
      _hasRemoteDescription = false;

      for (final track in localStream?.getTracks() ?? []) {
        track.stop();
      }

      await localStream?.dispose();
      await peerConnection?.close();
      await localRenderer.dispose();
      await remoteRenderer.dispose();
    } catch (_) {}

    localStream = null;
    peerConnection = null;
  }
}
