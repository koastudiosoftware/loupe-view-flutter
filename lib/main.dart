import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure desktop window properties and hide native frame
  await windowManager.ensureInitialized();
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 800),
    minimumSize: Size(640, 480),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden, // Hides the standard Windows title bar
    title: 'Loupe View',
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const LoupeViewApp());
}

class LoupeViewApp extends StatelessWidget {
  const LoupeViewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loupe View',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF181818),
        colorScheme: const ColorScheme.dark(
          primary: Colors.deepOrangeAccent,
          surface: Color(0xFF222222),
        ),
        useMaterial3: true,
      ),
      home: const MainViewerScreen(),
    );
  }
}

/// Custom title bar hosting action buttons, center title, and window controls (Height: 38px)
class CustomTitleBar extends StatelessWidget implements PreferredSizeWidget {
  final String currentTitle;

  const CustomTitleBar({
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
            const Icon(Icons.center_focus_strong, size: 18, color: Colors.deepOrangeAccent),
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
        // Intercept double taps so they do not trigger window maximize behaviors
        onDoubleTap: () {},
        child: SizedBox(
          width: 46,
          height: 38,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              hoverColor: Colors.white.withOpacity(0.08),
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
      // Intercept double taps to prevent window maximize toggles
      onDoubleTap: () {},
      child: SizedBox(
        width: 46,
        height: 38,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            hoverColor: hoverColor ?? Colors.white.withOpacity(0.08),
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

/// Docked Bottom Status Bar Widget
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
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Solid dark background for docked footer
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.08)),
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
                    Text(fileType, style: _hudTextStyle(fontWeight: FontWeight.bold)),
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
              const SizedBox(width: 4), // Space between plus icon and zoom list

              // Fixed-width container for zoom preset dropdown
              SizedBox(
                width: 58,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${(currentZoom * 100).toInt()}%',
                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_drop_down, size: 14, color: Colors.white70),
                    ],
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
          hoverColor: Colors.white.withOpacity(0.1),
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
      color: Colors.white.withOpacity(0.12),
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

class MainViewerScreen extends StatefulWidget {
  const MainViewerScreen({super.key});

  @override
  State<MainViewerScreen> createState() => _MainViewerScreenState();
}

class _MainViewerScreenState extends State<MainViewerScreen> {
  double _zoomLevel = 1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomTitleBar(currentTitle: 'sample_photo_01.jpg [1/24]'),
      body: Stack(
        children: [
          // Background Image Canvas area
          Container(
            color: const Color(0xFF121212),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.center_focus_strong, size: 64, color: Colors.deepOrangeAccent),
                  const SizedBox(height: 16),
                  Text(
                    'Loupe View',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Drag and drop an image or folder here to begin',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          // Docked Footer status bar pinned right at the bottom edge
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ImageViewerHUD(
              currentZoom: _zoomLevel,
              onZoomSliderChanged: (value) {
                setState(() {
                  _zoomLevel = value;
                });
              },
              onZoomIn: () {
                setState(() {
                  _zoomLevel = (_zoomLevel + 0.25).clamp(0.1, 5.0);
                });
              },
              onZoomOut: () {
                setState(() {
                  _zoomLevel = (_zoomLevel - 0.25).clamp(0.1, 5.0);
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}