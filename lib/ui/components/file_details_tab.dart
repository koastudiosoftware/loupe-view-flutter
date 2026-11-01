// file_details_tab.dart
import 'dart:io';
import 'package:flutter/material.dart';

class FileDetailsTab extends StatelessWidget {
  final String folderPath;
  final String fileName;
  final String filePath;
  final int fileSize; // Stored as raw bytes
  final VoidCallback? onOpenLocation;

  const FileDetailsTab({
    super.key,
    required this.folderPath,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    this.onOpenLocation,
  });

  void _openAndHighlightFile() {
    onOpenLocation?.call();

    if (filePath.isNotEmpty && File(filePath).existsSync()) {
      if (Platform.isWindows) {
        Process.run('explorer.exe', ['/select,', filePath]);
      } else if (Platform.isMacOS) {
        Process.run('open', ['-R', filePath]);
      } else if (Platform.isLinux) {
        Process.run('xdg-open', [folderPath]);
      }
    } else if (Directory(folderPath).existsSync()) {
      if (Platform.isWindows) {
        Process.run('explorer.exe', [folderPath]);
      } else if (Platform.isMacOS) {
        Process.run('open', [folderPath]);
      } else if (Platform.isLinux) {
        Process.run('xdg-open', [folderPath]);
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes Bytes';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        letterSpacing: 0.5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      children: [
        const SizedBox(height: 16),
        // Folder Location Group
        _sectionHeader('FOLDER LOCATION'),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: InkWell(
            onTap: _openAndHighlightFile,
            mouseCursor: SystemMouseCursors.click,
            child: Text(
              folderPath,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.blueAccent,
                decoration: TextDecoration.underline,
                decorationColor: Colors.blueAccent,
                height: 1.3,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // File Name Group
        _sectionHeader('FILE NAME'),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: Text(
            fileName,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              height: 1.3,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Date and Time Group
        _sectionHeader('DATE AND TIME'),
        const SizedBox(height: 6),
        const Padding(
          padding: EdgeInsets.only(left: 10.0),
          child: Text(
            'October 30, 2026\n12:05',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white,
              height: 1.3,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Size Info Group (Formatted from Bytes)
        _sectionHeader('SIZE INFO'),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: Text(
            _formatFileSize(fileSize),
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
