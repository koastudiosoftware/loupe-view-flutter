import 'dart:io';
import 'package:flutter/material.dart';

class ImageInfoPanel extends StatefulWidget {
  final String folderPath;
  final String fileName;
  final String filePath;
  final String fileSize;
  final String dimensions; // Expected format: "1920 x 1080" or "Unknown"
  final VoidCallback onClose;
  final VoidCallback? onResize;
  final VoidCallback? onCopyPath;
  final VoidCallback? onImageSpecs;
  final VoidCallback? onOpenLocation;

  const ImageInfoPanel({
    super.key,
    required this.folderPath,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.dimensions,
    required this.onClose,
    this.onResize,
    this.onCopyPath,
    this.onImageSpecs,
    this.onOpenLocation,
  });

  @override
  State<ImageInfoPanel> createState() => _ImageInfoPanelState();
}

class _ImageInfoPanelState extends State<ImageInfoPanel> {
  int _selectedTabIndex =
      0; // 0: File Details, 1: EXIF Details, 2: Image Details

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
        Text(value, style: const TextStyle(fontSize: 12, color: Colors.white)),
      ],
    );
  }

  void _openAndHighlightFile() {
    widget.onOpenLocation?.call();

    if (widget.filePath.isNotEmpty && File(widget.filePath).existsSync()) {
      if (Platform.isWindows) {
        Process.run('explorer.exe', ['/select,', widget.filePath]);
      } else if (Platform.isMacOS) {
        Process.run('open', ['-R', widget.filePath]);
      } else if (Platform.isLinux) {
        Process.run('xdg-open', [widget.folderPath]);
      }
    } else if (Directory(widget.folderPath).existsSync()) {
      if (Platform.isWindows) {
        Process.run('explorer.exe', [widget.folderPath]);
      } else if (Platform.isMacOS) {
        Process.run('open', [widget.folderPath]);
      } else if (Platform.isLinux) {
        Process.run('xdg-open', [widget.folderPath]);
      }
    }
  }

  String _getWidth() {
    if (widget.dimensions.contains('x')) {
      final parts = widget.dimensions.split('x');
      return '${parts[0].trim()} px';
    }
    return 'Unknown';
  }

  String _getHeight() {
    if (widget.dimensions.contains('x')) {
      final parts = widget.dimensions.split('x');
      return '${parts[1].trim()} px';
    }
    return 'Unknown';
  }

  String _getAspectRatio() {
    if (!widget.dimensions.contains('x')) return 'Unknown';
    try {
      final parts = widget.dimensions.split('x');
      final w = int.parse(parts[0].trim());
      final h = int.parse(parts[1].trim());
      if (h == 0) return 'Unknown';

      String label = '';
      if ((w / h - 16 / 9).abs() < 0.05) {
        label = '16:9';
      } else if ((w / h - 4 / 3).abs() < 0.05) {
        label = '4:3';
      } else if ((w / h - 1 / 1).abs() < 0.05) {
        label = '1:1 (Square)';
      }

      if (label.isNotEmpty) return label;
      return '${(w / h).toStringAsFixed(2)}:1';
    } catch (_) {
      return 'Unknown';
    }
  }

  String _getMegapixels() {
    if (!widget.dimensions.contains('x')) return 'Unknown';
    try {
      final parts = widget.dimensions.split('x');
      final w = int.parse(parts[0].trim());
      final h = int.parse(parts[1].trim());
      final mp = (w * h) / 1000000.0;
      return '${mp.toStringAsFixed(1)} MP';
    } catch (_) {
      return 'Unknown';
    }
  }

  String _getOrientation() {
    if (!widget.dimensions.contains('x')) return 'Unknown';
    try {
      final parts = widget.dimensions.split('x');
      final w = int.parse(parts[0].trim());
      final h = int.parse(parts[1].trim());
      if (w > h) return 'Landscape';
      if (h > w) return 'Portrait';
      return 'Square';
    } catch (_) {
      return 'Unknown';
    }
  }

  String _getMimeType() {
    final ext = widget.filePath.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return 'image/$ext';
    }
  }

  String _getFileTypeName() {
    final ext = widget.filePath.split('.').last.toUpperCase();
    switch (ext) {
      case 'JPG':
      case 'JPEG':
        return 'JPEG';
      case 'WEBP':
        return 'WebP';
      default:
        return ext;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF202020),
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Panel Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Info',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon:
                      const Icon(Icons.close, size: 16, color: Colors.white70),
                  onPressed: widget.onClose,
                  splashRadius: 16,
                ),
              ],
            ),
          ),

          // Streamlined 3-Tab Action Buttons Row
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _QuickTabButton(
                  icon: Icons.description_outlined,
                  label: 'File Details',
                  isSelected: _selectedTabIndex == 0,
                  onTap: () => setState(() => _selectedTabIndex = 0),
                ),
                _QuickTabButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'EXIF Details',
                  isSelected: _selectedTabIndex == 1,
                  onTap: () {
                    setState(() => _selectedTabIndex = 1);
                    widget.onCopyPath?.call();
                  },
                ),
                _QuickTabButton(
                  icon: Icons.image_outlined,
                  label: 'Image Specs',
                  isSelected: _selectedTabIndex == 2,
                  onTap: () {
                    setState(() => _selectedTabIndex = 2);
                    widget.onImageSpecs?.call();
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 16, color: Colors.white12),

          // Dynamic Content Area based on Selected Tab
          Expanded(
            child: _buildTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0: // File Details
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          children: [
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Folder location',
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 4),
                InkWell(
                  onTap: _openAndHighlightFile,
                  mouseCursor: SystemMouseCursors.click,
                  child: Text(
                    widget.folderPath,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.blueAccent,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.blueAccent,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _MetadataValueField(
              label: 'File name',
              value: widget.fileName,
            ),
            const SizedBox(height: 16),
            _MetadataValueField(
              label: 'Date and time',
              value: 'October 30, 2026\n12:05',
            ),
            const SizedBox(height: 16),
            _MetadataStaticField(
              label: 'Size info',
              value: widget.fileSize,
            ),
          ],
        );
      case 1: // EXIF Details
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('File Path',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 8),
              Text(widget.filePath,
                  style: const TextStyle(
                      fontSize: 13, color: Colors.white, height: 1.3)),
            ],
          ),
        );
      case 2: // Image Details & Specs (Grouped Dimensions)
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          children: [
            const SizedBox(height: 16),
            // Grouped Dimensions Heading
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dimensions',
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Column(
                    children: [
                      _infoRow('Width', _getWidth()),
                      const SizedBox(height: 6),
                      _infoRow('Height', _getHeight()),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _infoRow('Resolution (Megapixels)', _getMegapixels()),
            const SizedBox(height: 16),
            _infoRow('Aspect Ratio', _getAspectRatio()),
            const SizedBox(height: 16),
            _infoRow('Orientation', _getOrientation()),
            const SizedBox(height: 16),
            _infoRow('File Type Name', _getFileTypeName()),
            const SizedBox(height: 16),
            _infoRow('MIME Type', _getMimeType()),
            const SizedBox(height: 16),
            // TODO replace this hard-coded value with actual metadata if available
            _infoRow('Color Model', 'RGB'),
            const SizedBox(height: 16),
            // TODO replace this hard-coded value with actual metadata if available
            _infoRow('Bit Depth', '24-bit (True Color)'),
            const SizedBox(height: 16),
            // TODO replace this hard-coded value with actual metadata if available
            _infoRow('Compression', 'Lossless / Deflate (Standard)'),
            const SizedBox(height: 16),
            // TODO replace this hard-coded value with actual metadata if available
            _infoRow('Interlacing', 'Non-interlaced'),
            const SizedBox(height: 16),
            _infoRow('Rendering', 'Progressive Scan'),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _QuickTabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickTabButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: Colors.white.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.transparent,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : Colors.white70,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.white : Colors.white60,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetadataValueField extends StatelessWidget {
  final String label;
  final String value;

  const _MetadataValueField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style:
              const TextStyle(fontSize: 13, color: Colors.white, height: 1.3),
        ),
      ],
    );
  }
}

class _MetadataStaticField extends StatelessWidget {
  final String label;
  final String value;
  final bool isLink;

  const _MetadataStaticField({
    required this.label,
    required this.value,
    this.isLink = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: isLink ? Colors.blueAccent : Colors.white,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}
