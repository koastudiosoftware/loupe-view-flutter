// image_specs_tab.dart
import 'package:flutter/material.dart';

class ImageSpecsTab extends StatelessWidget {
  final String dimensions;
  final String filePath;

  const ImageSpecsTab({
    super.key,
    required this.dimensions,
    required this.filePath,
  });

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: const TextStyle(fontSize: 12, color: Colors.white),
          textAlign: TextAlign.end,
        ),
      ],
    );
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

  String _getWidth() {
    if (dimensions.contains('x')) {
      final parts = dimensions.split('x');
      return '${parts[0].trim()} px';
    }
    return 'Unknown';
  }

  String _getHeight() {
    if (dimensions.contains('x')) {
      final parts = dimensions.split('x');
      return '${parts[1].trim()} px';
    }
    return 'Unknown';
  }

  String _getAspectRatio() {
    if (!dimensions.contains('x')) return 'Unknown';
    try {
      final parts = dimensions.split('x');
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
    if (!dimensions.contains('x')) return 'Unknown';
    try {
      final parts = dimensions.split('x');
      final w = int.parse(parts[0].trim());
      final h = int.parse(parts[1].trim());
      final mp = (w * h) / 1000000.0;
      return '${mp.toStringAsFixed(1)} MP';
    } catch (_) {
      return 'Unknown';
    }
  }

  String _getOrientation() {
    if (!dimensions.contains('x')) return 'Unknown';
    try {
      final parts = dimensions.split('x');
      final w = int.parse(parts[0].trim());
      final h = int.parse(parts[1].trim());
      if (w > h) return 'Landscape';
      if (h > w) return 'Portrait';
      return 'Square';
    } catch (_) {
      return 'Square';
    }
  }

  String _getMimeType() {
    final ext = filePath.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return 'image/$ext';
    }
  }

  String _getFileTypeName() {
    final ext = filePath.split('.').last.toUpperCase();
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
    final dimensionRows = [
      MapEntry('Width', _getWidth()),
      MapEntry('Height', _getHeight()),
    ];

    final specs = [
      MapEntry('Resolution (Megapixels)', _getMegapixels()),
      MapEntry('Aspect Ratio', _getAspectRatio()),
      MapEntry('Orientation', _getOrientation()),
      MapEntry('File Type Name', _getFileTypeName()),
      MapEntry('MIME Type', _getMimeType()),
      MapEntry('Color Model', 'RGB'),
      MapEntry('Bit Depth', '24-bit (True Color)'),
      MapEntry('Compression', 'Lossless / Deflate (Standard)'),
      MapEntry('Interlacing', 'Non-interlaced'),
      MapEntry('Rendering', 'Progressive Scan'),
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      children: [
        const SizedBox(height: 16),
        _sectionHeader('DIMENSIONS'),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: Column(
            children: [
              for (int i = 0; i < dimensionRows.length; i++) ...[
                if (i > 0) const Divider(height: 12, color: Colors.white10),
                _infoRow(dimensionRows[i].key, dimensionRows[i].value),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionHeader('SPECIFICATIONS'),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: Column(
            children: [
              for (int i = 0; i < specs.length; i++) ...[
                if (i > 0) const Divider(height: 12, color: Colors.white10),
                _infoRow(specs[i].key, specs[i].value),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
