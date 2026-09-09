import 'package:flutter/material.dart';

class VideoCallPage extends StatefulWidget {
  const VideoCallPage({super.key});

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  // Dummy call data
  final List<Map<String, dynamic>> _calls = [
    {
      'name': 'Dr. Sarah Smith',
      'time': 'Today, 10:30 AM',
      'type': 'incoming',
      'status': 'missed',
    },
    {
      'name': 'Nurse John Doe',
      'time': 'Yesterday, 8:45 PM',
      'type': 'outgoing',
      'status': 'connected',
    },
    {
      'name': 'ANM Mary Johnson',
      'time': 'Yesterday, 2:15 PM',
      'type': 'incoming',
      'status': 'connected',
    },
    {
      'name': 'Dr. Robert Brown',
      'time': 'Monday, 11:00 AM',
      'type': 'outgoing',
      'status': 'missed',
    },
  ];

  void _startCall(BuildContext context, String name, bool isVideoCall) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ActiveCallPage(contactName: name, isVideoCall: isVideoCall),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calls'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
        ],
      ),
      body: ListView.builder(
        itemCount: _calls.length,
        itemBuilder: (context, index) {
          final call = _calls[index];
          final bool isMissed = call['status'] == 'missed';
          final bool isOutgoing = call['type'] == 'outgoing';

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.teal.shade200,
              radius: 24,
              child: const Icon(Icons.person, color: Colors.white, size: 30),
            ),
            title: Text(
              call['name'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isMissed ? Colors.red : Colors.black87,
              ),
            ),
            subtitle: Row(
              children: [
                Icon(
                  isOutgoing ? Icons.call_made : Icons.call_received,
                  size: 16,
                  color: isMissed ? Colors.red : Colors.green,
                ),
                const SizedBox(width: 5),
                Text(
                  call['time'],
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.call, color: Colors.teal.shade700),
                  onPressed: () => _startCall(context, call['name'], false),
                ),
                IconButton(
                  icon: Icon(Icons.videocam, color: Colors.teal.shade700),
                  onPressed: () => _startCall(context, call['name'], true),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_call),
      ),
    );
  }
}

// =========================================================
// ACTIVE CALL SCREEN (WhatsApp Style)
// =========================================================

class ActiveCallPage extends StatefulWidget {
  final String contactName;
  final bool isVideoCall;

  const ActiveCallPage({
    super.key,
    required this.contactName,
    required this.isVideoCall,
  });

  @override
  State<ActiveCallPage> createState() => _ActiveCallPageState();
}

class _ActiveCallPageState extends State<ActiveCallPage> {
  bool isMuted = false;
  bool isSpeakerOn = false;
  bool isVideoEnabled = false;

  @override
  void initState() {
    super.initState();
    isVideoEnabled = widget.isVideoCall;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Column(
          children: [
            // Top Section
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.lock, color: Colors.grey, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        'End-to-end encrypted',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 48), // Spacer to balance row
                ],
              ),
            ),

            // Call Info
            const SizedBox(height: 20),
            Text(
              widget.contactName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ringing...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 16,
              ),
            ),

            const Spacer(),

            // Avatar or Video Placeholder
            if (isVideoEnabled)
              Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: const Center(
                  child: Icon(Icons.videocam, color: Colors.white54, size: 60),
                ),
              )
            else
              const CircleAvatar(
                radius: 70,
                backgroundColor: Colors.teal,
                child: Icon(Icons.person, size: 80, color: Colors.white),
              ),

            const Spacer(),

            // Bottom Controls Background
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    icon: isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                    label: 'Speaker',
                    isActive: isSpeakerOn,
                    onTap: () {
                      setState(() {
                        isSpeakerOn = !isSpeakerOn;
                      });
                    },
                  ),
                  _buildControlButton(
                    icon: isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                    label: 'Video',
                    isActive: isVideoEnabled,
                    onTap: () {
                      setState(() {
                        isVideoEnabled = !isVideoEnabled;
                      });
                    },
                  ),
                  _buildControlButton(
                    icon: isMuted ? Icons.mic_off : Icons.mic,
                    label: 'Mute',
                    isActive: isMuted,
                    onTap: () {
                      setState(() {
                        isMuted = !isMuted;
                      });
                    },
                  ),

                  // End Call Button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.call_end,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.white24,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.black : Colors.white,
              size: 26,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
