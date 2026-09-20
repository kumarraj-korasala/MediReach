import 'dart:math';

import 'package:flutter/material.dart';

import '../../features/calling/active_call_page.dart';
import '../../features/calling/chat_page.dart';
import '../../features/calling/signaling_service.dart';

class VideoCallPage extends StatefulWidget {
  const VideoCallPage({super.key});

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  final SignalingService _signaling = SignalingService();

  final TextEditingController _myIdController = TextEditingController();
  final TextEditingController _targetIdController = TextEditingController();
  final TextEditingController _serverIpController = TextEditingController(
    text: '10.55.11.194:8000',
  );

  bool _isConnected = false;
  String? _activeIncomingCallId;

  final List<String> _recentContacts = [
    'doctor_rahul',
    'emergency_desk',
    'lab_assistant',
  ];

  @override
  void initState() {
    super.initState();
    _myIdController.text = 'user_${Random().nextInt(8999) + 1000}';

    _signaling.messages.listen((msg) {
      if (!mounted) return;
      final type = msg['type'];
      if (type == 'call_offer') {
        _activeIncomingCallId = msg['callId'];
        _showIncomingCallDialog(
          callerId: msg['from'],
          callId: msg['callId'],
          offerSdp: msg['sdp'],
          isVideoCall: msg['isVideo'] ?? true,
        );
      } else if ((type == 'call_end' || type == 'call_reject') &&
          msg['callId'] == _activeIncomingCallId) {
        _activeIncomingCallId = null;
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      } else if (type == 'chat_message' || type == 'file_message') {
        final sender = msg['from'] ?? 'Someone';
        final preview = type == 'chat_message'
            ? (msg['text'] ?? '')
            : 'Sent a file attachment';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New message from $sender: $preview'),
            backgroundColor: Colors.teal.shade800,
            action: SnackBarAction(
              label: 'Open Chat',
              textColor: Colors.amberAccent,
              onPressed: () => _openChatWith(sender),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      } else if (type == 'error') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg['message'] ?? 'Target user is currently offline'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    });
  }

  void _connectToSignaling() {
    if (_myIdController.text.isEmpty || _serverIpController.text.isEmpty) {
      return;
    }

    _signaling.connect(
      token: _myIdController.text.trim(),
      domain: _serverIpController.text.trim(),
    );

    setState(() {
      _isConnected = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Connected to signaling as ${_myIdController.text}'),
        backgroundColor: Colors.teal.shade700,
      ),
    );
  }

  void _startCallWith(String targetId, bool isVideoCall) {
    if (!_isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please connect to server first')),
      );
      return;
    }

    final callId = 'call_${DateTime.now().millisecondsSinceEpoch}';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveCallPage(
          callId: callId,
          contactName: targetId,
          isVideoCall: isVideoCall,
          isReceiver: false,
        ),
      ),
    );
  }

  void _openChatWith(String targetId) {
    if (!_isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please connect to server first')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatPage(contactId: targetId)),
    );
  }

  void _showIncomingCallDialog({
    required String callerId,
    required String callId,
    required String offerSdp,
    required bool isVideoCall,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isVideoCall ? Icons.videocam : Icons.call,
              color: Colors.teal.shade700,
            ),
            const SizedBox(width: 8),
            Text('Incoming ${isVideoCall ? "Video" : "Voice"} Call'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: Colors.teal.shade100,
              child: Icon(Icons.person, size: 44, color: Colors.teal.shade800),
            ),
            const SizedBox(height: 12),
            Text(
              callerId,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'End-to-end encrypted call',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _activeIncomingCallId = null;
              Navigator.pop(context);
              _signaling.rejectCall(callId, receiverId: callerId);
            },
            child: const Text(
              'Decline',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.call),
            label: const Text('Answer'),
            onPressed: () {
              _activeIncomingCallId = null;
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ActiveCallPage(
                    callId: callId,
                    contactName: callerId,
                    isVideoCall: isVideoCall,
                    isReceiver: true,
                    offerSdp: offerSdp,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 20,
            floating: true,
            pinned: true,
            backgroundColor: isDark
                ? Colors.grey.shade900
                : Colors.teal.shade700,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Row(
                children: [
                  const Icon(Icons.forum, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'MEDI Connect',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _isConnected ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      _isConnected ? 'ONLINE' : 'OFFLINE',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SERVER CONNECTION CARD
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: _isConnected
                                    ? Colors.green.shade100
                                    : Colors.orange.shade100,
                                child: Icon(
                                  _isConnected
                                      ? Icons.cloud_done
                                      : Icons.cloud_off,
                                  color: _isConnected
                                      ? Colors.green.shade800
                                      : Colors.orange.shade800,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _isConnected
                                    ? 'Connected to Signaling Server'
                                    : 'Signaling Connection Setup',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _serverIpController,
                                  enabled: !_isConnected,
                                  decoration: const InputDecoration(
                                    labelText: 'Server IP:Port',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _myIdController,
                                  enabled: !_isConnected,
                                  decoration: const InputDecoration(
                                    labelText: 'My User ID',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isConnected
                                    ? Colors.grey
                                    : Colors.teal.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: Icon(
                                _isConnected ? Icons.check : Icons.login,
                              ),
                              label: Text(
                                _isConnected
                                    ? 'Connected'
                                    : 'Connect to Network',
                              ),
                              onPressed: _isConnected
                                  ? null
                                  : _connectToSignaling,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // START NEW DIRECT CONVERSATION CARD
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Start Conversation or Call',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _targetIdController,
                            decoration: InputDecoration(
                              labelText: 'Target Contact ID (e.g. user_102)',
                              prefixIcon: const Icon(Icons.person_search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _actionIconButton(
                                icon: Icons.chat,
                                label: 'Chat & Share',
                                color: Colors.blue.shade600,
                                onTap: () => _openChatWith(
                                  _targetIdController.text.trim(),
                                ),
                              ),
                              _actionIconButton(
                                icon: Icons.call,
                                label: 'Voice Call',
                                color: Colors.teal.shade600,
                                onTap: () => _startCallWith(
                                  _targetIdController.text.trim(),
                                  false,
                                ),
                              ),
                              _actionIconButton(
                                icon: Icons.videocam,
                                label: 'Video Call',
                                color: Colors.purple.shade600,
                                onTap: () => _startCallWith(
                                  _targetIdController.text.trim(),
                                  true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // QUICK RECENT CONTACTS
                  const Text(
                    'Quick Contacts & Speed Dial',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  ..._recentContacts.map(
                    (contact) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal.shade100,
                          child: Text(
                            contact[0].toUpperCase(),
                            style: TextStyle(
                              color: Colors.teal.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          contact,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text('Tap to start call or chat'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chat, color: Colors.blue),
                              onPressed: () => _openChatWith(contact),
                            ),
                            IconButton(
                              icon: const Icon(Icons.call, color: Colors.teal),
                              onPressed: () => _startCallWith(contact, false),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.videocam,
                                color: Colors.purple,
                              ),
                              onPressed: () => _startCallWith(contact, true),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionIconButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color,
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
