import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'signaling_service.dart';
import 'webrtc_service.dart';

class ActiveCallPage extends StatefulWidget {
  final String callId;
  final String contactName;
  final bool isVideoCall;
  final bool isReceiver;
  final String? offerSdp;

  const ActiveCallPage({
    super.key,
    required this.callId,
    required this.contactName,
    required this.isVideoCall,
    this.isReceiver = false,
    this.offerSdp,
  });

  @override
  State<ActiveCallPage> createState() => _ActiveCallPageState();
}

class _ActiveCallPageState extends State<ActiveCallPage> {
  final WebRTCService _webrtc = WebRTCService();
  final SignalingService _signaling = SignalingService();
  StreamSubscription? _signalingSubscription;

  bool isMuted = false;
  bool isSpeakerOn = true;
  bool isVideoEnabled = true;

  String callStatus = 'Connecting...';
  NetworkMode activeNetworkMode = NetworkMode.auto5G;

  @override
  void initState() {
    super.initState();
    isVideoEnabled = widget.isVideoCall;
    _startCall();
  }

  Future<void> _startCall() async {
    try {
      _signalingSubscription = _signaling.messages.listen((message) async {
        final type = message['type'];
        final messageCallId = message['callId'];

        if (messageCallId != widget.callId) return;

        if (type == 'call_answer' && !widget.isReceiver) {
          debugPrint('Received Answer: Applying remote description...');
          await _webrtc.setRemoteDescription(
            RTCSessionDescription(message['sdp'], 'answer'),
          );
        } else if (type == 'ice_candidate') {
          debugPrint('Received ICE Candidate.');
          await _webrtc.addIceCandidate(
            RTCIceCandidate(
              message['candidate'],
              message['sdpMid'],
              message['sdpMLineIndex'],
            ),
          );
        } else if (type == 'call_end' || type == 'call_reject') {
          _endCall(remoteEnded: true);
        }
      });

      await _webrtc.initialize();

      await _webrtc.createConnection(
        video: widget.isVideoCall,
        onConnectionState: (state) {
          if (!mounted) return;
          setState(() {
            switch (state) {
              case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
                callStatus = 'Connected';
                _webrtc.setSpeaker(isSpeakerOn);
                break;
              case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
                callStatus = 'Connecting...';
                break;
              case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
                callStatus = 'Network poor - Reconnecting...';
                break;
              case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
                callStatus = 'Connection failed';
                break;
              case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
                callStatus = 'Call ended';
                break;
              default:
                callStatus = 'Connecting...';
            }
          });
        },
        onIceCandidate: (candidate) {
          if (candidate.candidate != null) {
            _signaling.sendIceCandidate(
              callId: widget.callId,
              receiverId: widget.contactName,
              candidate: candidate.candidate!,
              sdpMid: candidate.sdpMid,
              sdpMLineIndex: candidate.sdpMLineIndex,
            );
          }
        },
      );

      await _webrtc.openLocalMedia();

      if (widget.isReceiver && widget.offerSdp != null) {
        await _webrtc.setRemoteDescription(
          RTCSessionDescription(widget.offerSdp!, 'offer'),
        );
        final answer = await _webrtc.createAnswer();
        _signaling.sendAnswer(
          callId: widget.callId,
          receiverId: widget.contactName,
          sdp: answer.sdp!,
        );
      } else {
        final offer = await _webrtc.createOffer();
        _signaling.sendOffer(
          callId: widget.callId,
          receiverId: widget.contactName,
          sdp: offer.sdp!,
          isVideo: widget.isVideoCall,
        );
      }

      final buffered = _signaling.drainBufferedCandidates(widget.callId);
      for (final msg in buffered) {
        await _webrtc.addIceCandidate(
          RTCIceCandidate(
            msg['candidate'],
            msg['sdpMid'],
            msg['sdpMLineIndex'],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => callStatus = 'Failed to start call');
      debugPrint('Call error: $e');
    }
  }

  Future<void> _toggleMute() async {
    setState(() => isMuted = !isMuted);
    await _webrtc.muteMicrophone(isMuted);
  }

  Future<void> _toggleVideo() async {
    if (!widget.isVideoCall) return;
    setState(() => isVideoEnabled = !isVideoEnabled);
    await _webrtc.enableVideo(isVideoEnabled);
  }

  Future<void> _toggleSpeaker() async {
    setState(() => isSpeakerOn = !isSpeakerOn);
    await _webrtc.setSpeaker(isSpeakerOn);
  }

  Future<void> _switchCamera() async {
    if (!widget.isVideoCall) return;
    await _webrtc.switchCamera();
  }

  Future<void> _reconnectNetwork() async {
    setState(() => callStatus = 'Re-establishing ICE path...');
    await _webrtc.restartIce();
  }

  Future<void> _changeNetworkMode(NetworkMode mode) async {
    setState(() => activeNetworkMode = mode);
    await _webrtc.setNetworkProfile(mode);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Switched to ${_networkModeLabel(mode)} profile'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _networkModeLabel(NetworkMode mode) {
    switch (mode) {
      case NetworkMode.auto5G:
        return '5G Ultra HD';
      case NetworkMode.mode4G:
        return '4G Standard';
      case NetworkMode.mode3G:
        return '3G Data Saver';
      case NetworkMode.audioOnly:
        return 'Voice-Only Saver';
    }
  }

  void _showNetworkProfileSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Network Condition Optimization',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Select network profile to match your connection speed',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 16),
            _networkTile(
              NetworkMode.auto5G,
              '5G / Fiber HD (2.5 Mbps)',
              'Maximum video resolution & frame rate',
              Icons.speed,
              Colors.greenAccent,
            ),
            _networkTile(
              NetworkMode.mode4G,
              '4G / LTE Balanced (800 Kbps)',
              'Standard quality for general mobile data',
              Icons.four_g_mobiledata,
              Colors.lightBlueAccent,
            ),
            _networkTile(
              NetworkMode.mode3G,
              '3G / Low Bandwidth (250 Kbps)',
              'Reduced bitrate & frame rate to prevent lag',
              Icons.three_g_mobiledata,
              Colors.amberAccent,
            ),
            _networkTile(
              NetworkMode.audioOnly,
              'Voice-Only Saver (30 Kbps)',
              'Disables video to keep audio clear on poor networks',
              Icons.record_voice_over,
              Colors.orangeAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _networkTile(
    NetworkMode mode,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final isSelected = activeNetworkMode == mode;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.greenAccent) : null,
      onTap: () {
        Navigator.pop(context);
        _changeNetworkMode(mode);
      },
    );
  }

  Future<void> _endCall({bool remoteEnded = false}) async {
    if (!remoteEnded) {
      _signaling.endCall(widget.callId, receiverId: widget.contactName);
    }
    await _webrtc.dispose();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _signalingSubscription?.cancel();
    _webrtc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            if (widget.isVideoCall && activeNetworkMode != NetworkMode.audioOnly)
              Positioned.fill(
                child: RTCVideoView(
                  _webrtc.remoteRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              )
            else
              Positioned.fill(child: _voiceCallView()),

            if (widget.isVideoCall && activeNetworkMode != NetworkMode.audioOnly)
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  width: 110,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white30),
                    boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8)],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: RTCVideoView(
                    _webrtc.localRenderer,
                    mirror: true,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                ),
              ),

            Positioned(
              top: 20,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lock, color: Colors.greenAccent, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        widget.contactName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    callStatus,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _showNetworkProfileSelector,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.tealAccent),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.wifi_tethering, color: Colors.tealAccent, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            _networkModeLabel(activeNetworkMode),
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                          const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Positioned(left: 0, right: 0, bottom: 0, child: _controls()),
          ],
        ),
      ),
    );
  }

  Widget _voiceCallView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 65,
            backgroundColor: Colors.teal.shade700,
            child: Text(
              widget.contactName.isNotEmpty ? widget.contactName[0].toUpperCase() : 'U',
              style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.contactName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            callStatus,
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 12),
          Chip(
            avatar: const Icon(Icons.security, color: Colors.greenAccent, size: 16),
            label: Text(
              'Profile: ${_networkModeLabel(activeNetworkMode)}',
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
            backgroundColor: Colors.white10,
          ),
        ],
      ),
    );
  }

  Widget _controls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: const BoxDecoration(
        color: Color(0xEE1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _control(
            icon: isMuted ? Icons.mic_off : Icons.mic,
            label: isMuted ? 'Unmute' : 'Mute',
            active: isMuted,
            onTap: _toggleMute,
          ),

          if (widget.isVideoCall)
            _control(
              icon: isVideoEnabled ? Icons.videocam : Icons.videocam_off,
              label: 'Video',
              active: isVideoEnabled,
              onTap: _toggleVideo,
            ),

          if (widget.isVideoCall)
            _control(
              icon: Icons.cameraswitch,
              label: 'Flip',
              active: false,
              onTap: _switchCamera,
            ),

          _control(
            icon: isSpeakerOn ? Icons.volume_up : Icons.volume_down,
            label: 'Speaker',
            active: isSpeakerOn,
            onTap: _toggleSpeaker,
          ),

          _control(
            icon: Icons.refresh,
            label: 'ICE Fix',
            active: false,
            onTap: _reconnectNetwork,
          ),

          GestureDetector(
            onTap: () => _endCall(),
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.call_end, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _control({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: active ? Colors.tealAccent : Colors.white24,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: active ? Colors.black : Colors.white, size: 22),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }
}
