import 'package:flutter/material.dart';

class ImageViewerHUD extends StatelessWidget {
  final String fileType;
  final String dimensions;
  final String fileSize;
  final double currentZoom;
  final VoidCallback? onToggleFilmstrip;
  final VoidCallback? onToggleSlideshow;
  final VoidCallback? onZoomFit;
  final VoidCallback? onToggleInfo;
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback? onToggleFullscreen;
  final ValueChanged<double>? onZoomSliderChanged;

  const ImageViewerHUD({
    super.key,
    this.fileType = 'JPG',
    this.dimensions = '1408 x 768',
    this.fileSize = '397.1 KB',
    this.currentZoom = 1.0,
    this.onToggleFilmstrip,
    this.onToggleSlideshow,
    this.onZoomFit,
    this.onToggleInfo,
    this.onZoomIn,
    this.onZoomOut,
    this.onToggleFullscreen,
    this.onZoomSliderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xCC1E1E1E), // Translucent dark background
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Filmstrip & Slideshow toggles
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

          // 2. File stats (Type, Dimensions, Size)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Text(fileType, style: _hudTextStyle(fontWeight: FontWeight.bold)),
                const _VerticalSeparator(),
                Text(dimensions, style: _hudTextStyle()),
                const _VerticalSeparator(),
                Text(fileSize, style: _hudTextStyle()),
              ],
            ),
          ),
          const _HudDivider(),

          // 3. Zoom Fit & Info
          _HudIconButton(
            icon: Icons.fit_screen_outlined,
            tooltip: 'Zoom to fit',
            onPressed: onZoomFit,
          ),
          _HudIconButton(
            icon: Icons.info_outline,
            tooltip: 'File info',
            onPressed: onToggleInfo,
          ),
          const _HudDivider(),

          // 4. Zoom Controls (Minus, Slider, Plus, Preset Dropdown)
          _HudIconButton(
            icon: Icons.remove,
            tooltip: 'Zoom out',
            onPressed: onZoomOut,
          ),
          SizedBox(
            width: 90,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                activeTrackColor: Colors.blueAccent,
                inactiveTrackColor: Colors.white24,
                thumbColor: Colors.blueAccent,
              ),
              child: Slider(
                value: currentZoom,
                min: 0.1,
                max: 5.0,
                onChanged: onZoomSliderChanged,
              ),
            ),
          ),
          _HudIconButton(
            icon: Icons.add,
            tooltip: 'Zoom in',
            onPressed: onZoomIn,
          ),

          // Zoom Preset Button / Dropdown look
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Text(
                  '${(currentZoom * 100).toInt()}%',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, size: 14, color: Colors.white70),
              ],
            ),
          ),

          const SizedBox(width: 4),
          const _HudDivider(),

          // 5. Fullscreen toggle
          _HudIconButton(
            icon: Icons.fullscreen,
            tooltip: 'Fullscreen',
            onPressed: onToggleFullscreen,
          ),
        ],
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