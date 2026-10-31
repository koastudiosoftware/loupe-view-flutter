import 'package:flutter/material.dart';

/// Docked Bottom Status Bar Widget
class ImageViewerHUD extends StatelessWidget {
  final String fileType;
  final String dimensions;
  final String fileSize;
  final double currentZoom;
  final List<int> zoomPresets;
  final VoidCallback? onToggleFilmstrip;
  final VoidCallback? onToggleSlideshow;
  final VoidCallback? onZoomFit;
  final VoidCallback? onToggleInfo;
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback? onToggleFullscreen;
  final ValueChanged<double>? onZoomSliderChanged;
  final ValueChanged<double>? onZoomSelected;

  const ImageViewerHUD({
    super.key,
    this.fileType = 'JPG',
    this.dimensions = '---',
    this.fileSize = '---',
    this.currentZoom = 1.0,
    required this.zoomPresets,
    this.onToggleFilmstrip,
    this.onToggleSlideshow,
    this.onZoomFit,
    this.onToggleInfo,
    this.onZoomIn,
    this.onZoomOut,
    this.onToggleFullscreen,
    this.onZoomSliderChanged,
    this.onZoomSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Group: Filmstrip, Slideshow, Info, and File Stats
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HudIconButton(
                icon: Icons.view_sidebar_outlined,
                tooltip: 'Toggle filmstrip',
                onPressed: onToggleFilmstrip,
              ),
              _HudIconButton(
                icon: Icons.play_arrow_outlined,
                tooltip: 'Slideshow',
                onPressed: onToggleSlideshow,
              ),
              const _HudDivider(),
              _HudIconButton(
                icon: Icons.info_outline,
                tooltip: 'File info',
                onPressed: onToggleInfo,
              ),
              const _HudDivider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    Text(fileType,
                        style: _hudTextStyle(fontWeight: FontWeight.bold)),
                    const _VerticalSeparator(),
                    Text(dimensions, style: _hudTextStyle()),
                    const _VerticalSeparator(),
                    Text(fileSize, style: _hudTextStyle()),
                  ],
                ),
              ),
            ],
          ),

          // Right Group: Zoom Fit, Zoom Controls, Fullscreen
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HudIconButton(
                icon: Icons.fit_screen_outlined,
                tooltip: 'Zoom to fit',
                onPressed: onZoomFit,
              ),
              const _HudDivider(),
              _HudIconButton(
                icon: Icons.remove,
                tooltip: 'Zoom out',
                onPressed: onZoomOut,
              ),
              // Zoom Slider container (150px)
              SizedBox(
                width: 150,
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 2,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 5),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 10),
                    activeTrackColor: Colors.blueAccent,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: Colors.blueAccent,
                  ),
                  child: Slider(
                    value: currentZoom,
                    min: 0.1,
                    max: 8.0,
                    onChanged: onZoomSliderChanged,
                  ),
                ),
              ),
              _HudIconButton(
                icon: Icons.add,
                tooltip: 'Zoom in',
                onPressed: onZoomIn,
              ),
              const SizedBox(width: 4),

              // Operational Zoom Preset Dropdown Menu (800% down to 10%)
              SizedBox(
                width: 58,
                child: PopupMenuButton<double>(
                  tooltip: 'Zoom presets',
                  offset: const Offset(0, -320),
                  color: const Color(0xFF2A2A2A),
                  itemBuilder: (context) => zoomPresets.reversed.map((preset) {
                    final scale = preset / 100.0;
                    return _popupItem(scale, '$preset%');
                  }).toList(),
                  onSelected: (value) {
                    if (onZoomSelected != null) {
                      onZoomSelected!(value);
                    }
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(currentZoom * 100).toInt()}%',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.white70),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.arrow_drop_down,
                            size: 14, color: Colors.white70),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 4),
              const _HudDivider(),
              _HudIconButton(
                icon: Icons.fullscreen,
                tooltip: 'Fullscreen',
                onPressed: onToggleFullscreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<double> _popupItem(double value, String label) {
    return PopupMenuItem<double>(
      value: value,
      height: 32,
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Colors.white70),
      ),
    );
  }

  TextStyle _hudTextStyle({FontWeight fontWeight = FontWeight.normal}) {
    return TextStyle(
      fontSize: 12,
      color: Colors.white70,
      fontWeight: fontWeight,
    );
  }
}

class _HudIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _HudIconButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          hoverColor: Colors.white.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(icon, size: 16, color: Colors.white70),
          ),
        ),
      ),
    );
  }
}

class _HudDivider extends StatelessWidget {
  const _HudDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      width: 1,
      color: Colors.white.withValues(alpha: 0.12),
      margin: const EdgeInsets.symmetric(horizontal: 6),
    );
  }
}

class _VerticalSeparator extends StatelessWidget {
  const _VerticalSeparator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Text('|', style: TextStyle(fontSize: 11, color: Colors.white24)),
    );
  }
}
