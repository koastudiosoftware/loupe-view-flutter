import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Custom title bar hosting action buttons, center title, and window controls (Height: 38px)
class WindowTitleBar extends StatelessWidget implements PreferredSizeWidget {
  final String currentTitle;

  const WindowTitleBar({
    super.key,
    this.currentTitle = 'No Image Loaded',
  });

  @override
  Size get preferredSize => const Size.fromHeight(38);

  @override
  Widget build(BuildContext context) {
    return DragToMoveArea(
      child: Container(
        height: 38,
        color: const Color(0xFF1a1a1a),
        child: Row(
          children: [
            const SizedBox(width: 12),
            const Icon(Icons.center_focus_strong,
                size: 18, color: Colors.deepOrangeAccent),
            const SizedBox(width: 12),
            // Action Buttons (Settings, Print, Delete)
            _TitleBarActionButton(
              icon: Icons.settings_outlined,
              tooltip: 'Settings',
              onPressed: () {
                // TODO: Wire up settings dialog/view later
              },
            ),
            _TitleBarActionButton(
              icon: Icons.print_outlined,
              tooltip: 'Print',
              onPressed: () {
                // TODO: Wire up print action later
              },
            ),
            _TitleBarActionButton(
              icon: Icons.delete_outline,
              tooltip: 'Delete',
              onPressed: () {
                // TODO: Wire up delete action later
              },
            ),

            // Center Filename / Context Title Placeholder
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  currentTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),

            // Minimize Button
            _TitleBarButton(
              icon: Icons.remove,
              iconSize: 16,
              onPressed: () => windowManager.minimize(),
            ),
            // Maximize / Restore Button
            _TitleBarButton(
              icon: Icons.crop_square,
              iconSize: 16,
              onPressed: () async {
                if (await windowManager.isMaximized()) {
                  windowManager.unmaximize();
                } else {
                  windowManager.maximize();
                }
              },
            ),
            // Close Button (with Windows-style red hover)
            _TitleBarButton(
              icon: Icons.close,
              iconSize: 16,
              hoverColor: const Color(0xFFE81123),
              onPressed: () => windowManager.close(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper widget for title bar action buttons matching window button proportions
class _TitleBarActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _TitleBarActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: GestureDetector(
        onDoubleTap: () {},
        child: SizedBox(
          width: 46,
          height: 38,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              hoverColor: Colors.white.withValues(alpha: 0.08),
              child: Center(
                child: Icon(
                  icon,
                  size: 16,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper widget for full-square hover window control buttons
class _TitleBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? hoverColor;
  final double iconSize;

  const _TitleBarButton({
    required this.icon,
    required this.onPressed,
    this.hoverColor,
    this.iconSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () {},
      child: SizedBox(
        width: 46,
        height: 38,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            hoverColor: hoverColor ?? Colors.white.withValues(alpha: 0.08),
            child: Center(
              child: Icon(
                icon,
                size: iconSize,
                color: Colors.white70,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
