// image_info_panel.dart
import 'package:flutter/material.dart';
import 'file_details_tab.dart';
import 'exif_details_tab.dart';
import 'image_specs_tab.dart';

class ImageInfoPanel extends StatefulWidget {
  final String folderPath;
  final String fileName;
  final String filePath;
  final int fileSize; // Updated to int bytes
  final String dimensions;
  final Map<String, String>? exifData;
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
    this.exifData,
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
  int _selectedTabIndex = 0;

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
      case 0:
        return FileDetailsTab(
          folderPath: widget.folderPath,
          fileName: widget.fileName,
          filePath: widget.filePath,
          fileSize: widget.fileSize,
          onOpenLocation: widget.onOpenLocation,
        );
      case 1:
        return ExifDetailsTab(exifData: widget.exifData);
      case 2:
        return ImageSpecsTab(
          dimensions: widget.dimensions,
          filePath: widget.filePath,
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
