// exif_details_tab.dart
import 'package:flutter/material.dart';
import '../../models/exif_labels.dart';
import '../common/exif_formatter.dart'; // Ensure formatter is imported

class ExifDetailsTab extends StatelessWidget {
  final Map<String, String>? exifData;

  const ExifDetailsTab({
    super.key,
    this.exifData,
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

  @override
  Widget build(BuildContext context) {
    final exif = exifData ?? {};

    if (exif.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'No EXIF metadata found in this file.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Filter out General (ungrouped) keys and JPEGThumbnail
    final filteredExif = Map<String, String>.from(exif)
      ..removeWhere((k, v) {
        if (!k.contains(' ')) return true;
        final prefix = k.split(' ').first.toLowerCase();
        return prefix == 'jpegthumbnail';
      });

    if (filteredExif.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'No relevant EXIF metadata found.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Extract unique group prefixes
    final Set<String> groups =
        filteredExif.keys.map((k) => k.split(' ').first).toSet();

    final sortedGroups = groups.toList()..sort();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      children: [
        for (final group in sortedGroups) ...[
          Builder(
            builder: (context) {
              // Collect keys for this group and sort them by their MAPPED DISPLAY LABEL
              final groupKeys = filteredExif.keys
                  .where((k) => k.startsWith('$group '))
                  .toList()
                ..sort((a, b) {
                  final labelA = ExifLabels.displayNames[a] ??
                      a.substring(group.length + 1);
                  final labelB = ExifLabels.displayNames[b] ??
                      b.substring(group.length + 1);
                  return labelA.compareTo(labelB);
                });

              if (groupKeys.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _sectionHeader(group.toUpperCase()),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: Column(
                      children: [
                        for (int i = 0; i < groupKeys.length; i++) ...[
                          if (i > 0)
                            const Divider(height: 12, color: Colors.white10),
                          Builder(
                            builder: (context) {
                              final fullKey = groupKeys[i];
                              final label = ExifLabels.displayNames[fullKey] ??
                                  fullKey.substring(group.length + 1);
                              final formattedValue = ExifFormatter.formatValue(
                                  fullKey, filteredExif[fullKey]!);
                              return _infoRow(label, formattedValue);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}
