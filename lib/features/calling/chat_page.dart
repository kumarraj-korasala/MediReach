import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'active_call_page.dart';
import 'file_transfer_service.dart';
import 'signaling_service.dart';

class ChatPage extends StatefulWidget {
  final String contactId;

  const ChatPage({super.key, required this.contactId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final SignalingService _signaling = SignalingService();
  final FileTransferService _fileService = FileTransferService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];

  bool _isSendingFile = false;

  @override
  void initState() {
    super.initState();
    _signaling.messages.listen((msg) {
      if (!mounted) return;
      final type = msg['type'];
      final from = msg['from'];

      if (from == widget.contactId) {
        if (type == 'chat_message') {
          setState(() {
            _messages.insert(0, {
              'id': 'msg_${DateTime.now().millisecondsSinceEpoch}',
              'type': 'text',
              'text': msg['text'],
              'isMe': false,
              'time': _formatTime(DateTime.now()),
            });
          });
        } else if (type == 'file_message' && msg['fileData'] != null) {
          final fileModel = SharedFileModel.fromJson(
            Map<String, dynamic>.from(msg['fileData']),
          );
          setState(() {
            _messages.insert(0, {
              'id': fileModel.id,
              'type': 'file',
              'fileModel': fileModel,
              'isMe': false,
              'time': _formatTime(fileModel.timestamp),
            });
          });
        }
      }
    });
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _sendTextMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _signaling.sendChatMessage(receiverId: widget.contactId, text: text);

    setState(() {
      _messages.insert(0, {
        'id': 'msg_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'text',
        'text': text,
        'isMe': true,
        'time': _formatTime(DateTime.now()),
      });
    });
    _textController.clear();
  }

  Future<void> _pickAndSendFile(FileType fileType) async {
    setState(() => _isSendingFile = true);
    try {
      final fileModel = await _fileService.pickAndPrepareFile(
        type: fileType,
        senderId: _signaling.myId ?? 'me',
      );

      if (fileModel != null) {
        _signaling.sendFileMessage(
          receiverId: widget.contactId,
          fileData: fileModel.toJson(),
        );

        setState(() {
          _messages.insert(0, {
            'id': fileModel.id,
            'type': 'file',
            'fileModel': fileModel,
            'isMe': true,
            'time': _formatTime(fileModel.timestamp),
          });
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick file: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingFile = false);
      }
    }
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _attachmentOption(
                  icon: Icons.image,
                  color: Colors.purple,
                  label: 'Photos',
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndSendFile(FileType.image);
                  },
                ),
                _attachmentOption(
                  icon: Icons.insert_drive_file,
                  color: Colors.blue,
                  label: 'Document',
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndSendFile(FileType.any);
                  },
                ),
                _attachmentOption(
                  icon: Icons.headset,
                  color: Colors.orange,
                  label: 'Audio',
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndSendFile(FileType.audio);
                  },
                ),
                _attachmentOption(
                  icon: Icons.videocam,
                  color: Colors.pink,
                  label: 'Video',
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndSendFile(FileType.video);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _attachmentOption({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _startCall(bool isVideoCall) {
    final callId = 'call_${DateTime.now().millisecondsSinceEpoch}';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveCallPage(
          callId: callId,
          contactName: widget.contactId,
          isVideoCall: isVideoCall,
          isReceiver: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.teal.shade700,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.teal.shade300,
              radius: 18,
              child: Text(
                widget.contactId.isNotEmpty
                    ? widget.contactId[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.contactId,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Row(
                  children: [
                    Icon(Icons.circle, color: Colors.greenAccent, size: 8),
                    SizedBox(width: 4),
                    Text(
                      'Online | End-to-end encrypted',
                      style: TextStyle(fontSize: 10, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            tooltip: 'Voice Call',
            onPressed: () => _startCall(false),
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            tooltip: 'Video Call',
            onPressed: () => _startCall(true),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          if (_isSendingFile)
            const LinearProgressIndicator(
              backgroundColor: Colors.teal,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
          Expanded(
            child: Container(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE5DDD5),
              child: ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isMe = msg['isMe'] as bool;
                  return _buildMessageBubble(msg, isMe, isDark);
                },
              ),
            ),
          ),
          _buildInputBar(isDark),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    Map<String, dynamic> msg,
    bool isMe,
    bool isDark,
  ) {
    final type = msg['type'] as String;

    final bubbleColor = isMe
        ? (isDark ? Colors.teal.shade800 : const Color(0xFFDCF8C6))
        : (isDark ? Colors.grey.shade800 : Colors.white);

    final textColor = isMe
        ? (isDark ? Colors.white : Colors.black87)
        : (isDark ? Colors.white : Colors.black87);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isMe ? 14 : 2),
            bottomRight: Radius.circular(isMe ? 2 : 14),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (type == 'text')
              Text(
                msg['text'],
                style: TextStyle(color: textColor, fontSize: 15),
              )
            else if (type == 'file')
              _buildFileCard(msg['fileModel'] as SharedFileModel, textColor),

            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  msg['time'] ?? '',
                  style: TextStyle(
                    fontSize: 10,
                    color: textColor.withValues(alpha: 0.6),
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.done_all,
                    size: 14,
                    color: isDark ? Colors.tealAccent : Colors.blue,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileCard(SharedFileModel file, Color textColor) {
    if (file.fileType == 'image' && file.base64Data != null) {
      try {
        final bytes = base64Decode(file.base64Data!);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                bytes,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              file.fileName,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      } catch (_) {}
    }

    IconData icon;
    Color iconColor;

    switch (file.fileType) {
      case 'image':
        icon = Icons.image;
        iconColor = Colors.purple;
        break;
      case 'document':
        icon = Icons.picture_as_pdf;
        iconColor = Colors.redAccent;
        break;
      case 'audio':
        icon = Icons.audiotrack;
        iconColor = Colors.orange;
        break;
      case 'video':
        icon = Icons.video_collection;
        iconColor = Colors.pink;
        break;
      default:
        icon = Icons.insert_drive_file;
        iconColor = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: iconColor.withValues(alpha: 0.2),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.fileName,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  file.formattedSize,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.download, size: 20),
            onPressed: () async {
              final path = await _fileService.saveFileToDevice(file);
              if (mounted && path != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('File saved to: $path')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: isDark ? Colors.grey.shade900 : Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.teal),
              onPressed: _showAttachmentMenu,
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _sendTextMessage(),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.teal.shade700,
              radius: 22,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 18),
                onPressed: _sendTextMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
