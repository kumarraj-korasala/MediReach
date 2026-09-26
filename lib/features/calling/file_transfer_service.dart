import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class SharedFileModel {
  final String id;
  final String fileName;
  final int fileSize;
  final String fileType; // 'image', 'document', 'audio', 'video', 'other'
  final String? base64Data;
  final String? localPath;
  final String senderId;
  final DateTime timestamp;

  SharedFileModel({
    required this.id,
    required this.fileName,
    required this.fileSize,
    required this.fileType,
    this.base64Data,
    this.localPath,
    required this.senderId,
    required this.timestamp,
  });

  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'fileSize': fileSize,
        'fileType': fileType,
        'base64Data': base64Data,
        'senderId': senderId,
        'timestamp': timestamp.toIso8601String(),
      };

  factory SharedFileModel.fromJson(Map<String, dynamic> json) => SharedFileModel(
        id: json['id'] ?? 'file_${DateTime.now().millisecondsSinceEpoch}',
        fileName: json['fileName'] ?? 'unknown_file',
        fileSize: json['fileSize'] ?? 0,
        fileType: json['fileType'] ?? 'other',
        base64Data: json['base64Data'],
        senderId: json['senderId'] ?? '',
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'])
            : DateTime.now(),
      );
}

class FileTransferService {
  static final FileTransferService _instance = FileTransferService._internal();
  factory FileTransferService() => _instance;
  FileTransferService._internal();

  /// Picks a file from device gallery/storage and returns file model payload
  Future<SharedFileModel?> pickAndPrepareFile({
    FileType type = FileType.any,
    required String senderId,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: type,
        withData: true, // Loads bytes for cross-platform support (Web & Mobile & Desktop)
      );

      if (result == null || result.files.isEmpty) return null;
      final file = result.files.first;

      Uint8List? bytes = file.bytes;
      if (bytes == null && file.path != null) {
        final f = File(file.path!);
        bytes = await f.readAsBytes();
      }

      if (bytes == null) return null;

      final base64String = base64Encode(bytes);
      final fileCategory = _detectFileType(file.name);

      return SharedFileModel(
        id: 'file_${DateTime.now().millisecondsSinceEpoch}',
        fileName: file.name,
        fileSize: bytes.length,
        fileType: fileCategory,
        base64Data: base64String,
        localPath: file.path,
        senderId: senderId,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error picking file: $e');
      return null;
    }
  }

  /// Saves a base64 encoded file payload to local storage and returns saved file path
  Future<String?> saveFileToDevice(SharedFileModel model) async {
    if (model.base64Data == null || model.base64Data!.isEmpty) return null;
    try {
      final bytes = base64Decode(model.base64Data!);
      Directory tempDir;
      if (kIsWeb) {
        return null; // On Web, base64 data URL is used directly
      } else {
        tempDir = await getTemporaryDirectory();
      }

      final file = File('${tempDir.path}/${model.fileName}');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      debugPrint('Error saving file to device: $e');
      return null;
    }
  }

  String _detectFileType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'].contains(ext)) {
      return 'image';
    } else if (['pdf', 'doc', 'docx', 'txt', 'ppt', 'pptx', 'xls', 'xlsx'].contains(ext)) {
      return 'document';
    } else if (['mp3', 'wav', 'aac', 'm4a', 'ogg'].contains(ext)) {
      return 'audio';
    } else if (['mp4', 'mkv', 'avi', 'mov'].contains(ext)) {
      return 'video';
    }
    return 'other';
  }
}
