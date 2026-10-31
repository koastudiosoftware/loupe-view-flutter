import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/gestures.dart';

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
  final ValueChanged<double>? onZoomSelected;

  const ImageViewerHUD({
    super.key,
    this.fileType = 'JPG',
    this.dimensions = '---',
    this.fileSize = '---',
    this.currentZoom = 1.0,
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
                  itemBuilder: (context) => _MainViewerScreenState._zoomPresets.reversed.map((preset) {
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

class MainViewerScreen extends StatefulWidget {
  const MainViewerScreen({super.key});

  @override
  State<MainViewerScreen> createState() => _MainViewerScreenState();
}

class _MainViewerScreenState extends State<MainViewerScreen> {
  File? _loadedImageFile;
  String _fileName = 'No Image Loaded';
  String _fileExtension = '---';
  String _dimensions = '---';
  String _fileSizeStr = '---';
  double _zoomLevel = 1.0;
  bool _isDraggingOver = false;

  int? _imageWidth;
  int? _imageHeight;
  double? _cachedViewportWidth;
  double? _cachedViewportHeight;

  final TransformationController _transformationController =
      TransformationController();

// Pure integer percentage state — zero floating-point drift
  int _zoomPercent = 100;

  bool _isFitToWindow = true; // Starts true when an image loads

  // Clean integer percentage table for presets
  static const List<int> _zoomPresets = [
    10,
    25,
    50,
    75,
    100,
    150,
    200,
    300,
    400,
    500,
    600,
    700,
    800
  ];

  void _zoomIn() {
    if (kDebugMode) {
      print('-> _isFitToWindow set to FALSE by _zoomIn');
    }
    _isFitToWindow = false; // Manual zoom breaks fit mode
    int currentIndex = _zoomPresets.indexWhere((p) => p > _zoomPercent);
    if (currentIndex == -1) currentIndex = _zoomPresets.length - 1;
    _setZoomPercent(_zoomPresets[currentIndex], _cachedViewportWidth ?? 0.0,
        _cachedViewportHeight ?? 0.0);
  }

  void _zoomOut() {
    if (kDebugMode) {
      print('-> _isFitToWindow set to FALSE by _zoomOut');
    }
    _isFitToWindow = false; // Manual zoom breaks fit mode
    int currentIndex = _zoomPresets.lastIndexWhere((p) => p < _zoomPercent);
    if (currentIndex == -1) currentIndex = 0;
    _setZoomPercent(_zoomPresets[currentIndex], _cachedViewportWidth ?? 0.0,
        _cachedViewportHeight ?? 0.0);
  }

  void _zoomToFit(double viewportWidth, double viewportHeight) {
    if (_imageWidth == null ||
        _imageHeight == null ||
        _imageWidth == 0 ||
        _imageHeight == 0) return;

    final scaleX = viewportWidth / _imageWidth!;
    final scaleY = viewportHeight / _imageHeight!;
    double fitScale = scaleX < scaleY ? scaleX : scaleY;
    fitScale = fitScale.clamp(0.1, 8.0);

    final fitPercent = (fitScale * 100).round();

    if (kDebugMode) {
      print('-> _isFitToWindow set to TRUE by _zoomToFit');
    }

    // Explicitly pass isFit: true here!
    _setZoomPercent(fitPercent, viewportWidth, viewportHeight, isFit: true);
  }

  void _setZoomPercent(int percent, double viewportWidth, double viewportHeight,
      {bool isFit = false}) {
    if (_imageWidth == null ||
        _imageHeight == null ||
        _imageWidth == 0 ||
        _imageHeight == 0) return;

    if (kDebugMode) {
      print('-> _isFitToWindow set to $isFit by _setZoomPercent');
    }

    _isFitToWindow = isFit; // Only true if explicitly called by fit-to-window

    final clampedPercent = percent.clamp(10, 800);
    final scale = clampedPercent / 100.0;

    setState(() {
      _zoomPercent = clampedPercent;
    });

    final dx = (viewportWidth - _imageWidth! * scale) / 2;
    final dy = (viewportHeight - _imageHeight! * scale) / 2;

    final matrix = Matrix4.identity()
      ..translateByDouble(dx, dy, 0.0, 1.0)
      ..scaleByDouble(scale, scale, 1.0, 1.0);

    _transformationController.value = matrix;
  }

  void _zoomByStep(int delta) {
    if (kDebugMode) {
      print('-> _isFitToWindow set to FALSE by _zoomByStep');
    }

    _isFitToWindow = false; // Manual scroll breaks fit mode
    int newPercent;
    if (delta > 0) {
      newPercent = ((_zoomPercent + 10) ~/ 10) * 10;
      if (newPercent <= _zoomPercent) newPercent += 10;
    } else {
      newPercent = (_zoomPercent ~/ 10) * 10;
      if (newPercent >= _zoomPercent) newPercent -= 10;
    }
    newPercent = newPercent.clamp(10, 800);
    _setZoomPercent(
        newPercent, _cachedViewportWidth ?? 0.0, _cachedViewportHeight ?? 0.0);
  }

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_onTransformationChanged);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    super.dispose();
  }

  void _onTransformationChanged() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    if ((currentScale - _zoomLevel).abs() > 0.005) {
      setState(() {
        _zoomLevel = currentScale.clamp(0.1, 8.0);
      });
    }
  }

  Future<void> _handleDroppedFile(File file) async {
    final bytes = await file.length();
    final sizeKb = (bytes / 1024).toStringAsFixed(1);
    final ext = file.path.split('.').last.toUpperCase();
    final name = file.uri.pathSegments.last;

    int? width;
    int? height;
    var dimensionsStr = 'Unknown';
    try {
      final decodedImage = await _getImageDimensions(file);
      if (decodedImage != null) {
        width = decodedImage.image.width;
        height = decodedImage.image.height;
        dimensionsStr = '$width x $height';
      }
    } catch (_) {}

    setState(() {
      _loadedImageFile = file;
      _fileName = '$name [1/1]';
      _fileExtension = ext;
      _fileSizeStr = '$sizeKb KB';
      _dimensions = dimensionsStr;
      _imageWidth = width;
      _imageHeight = height;
    });

    if (_cachedViewportWidth != null && _cachedViewportHeight != null) {
      _zoomToFit(_cachedViewportWidth!, _cachedViewportHeight!);
    } else {
      _transformationController.value = Matrix4.identity();
    }
  }

  Future<ImageInfo?> _getImageDimensions(File file) async {
    final completer = Completer<ImageInfo?>();
    final image = Image.file(file);
    final stream = image.image.resolve(const ImageConfiguration());

    late final ImageStreamListener listener;
    listener = ImageStreamListener((info, synchronousCall) {
      stream.removeListener(listener);
      completer.complete(info);
    }, onError: (exception, stackTrace) {
      stream.removeListener(listener);
      completer.complete(null);
    });

    stream.addListener(listener);
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (details) => setState(() => _isDraggingOver = true),
      onDragExited: (details) => setState(() => _isDraggingOver = false),
      onDragDone: (details) async {
        setState(() => _isDraggingOver = false);
        if (details.files.isNotEmpty) {
          final droppedFile = File(details.files.first.path);
          await _handleDroppedFile(droppedFile);
        }
      },
      child: Scaffold(
          appBar: CustomTitleBar(currentTitle: _fileName),
          body: Stack(
            children: [
              // 1. Background Canvas / Image View Area
              Positioned.fill(
                child: Listener(
                  onPointerSignal: (pointerSignal) {
                    if (pointerSignal is PointerScrollEvent) {
                      final int step =
                          pointerSignal.scrollDelta.dy < 0 ? 10 : -10;
                      _zoomByStep(step);
                    }
                  },
                  child: _loadedImageFile == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.center_focus_strong,
                                  size: 64, color: Colors.deepOrangeAccent),
                              const SizedBox(height: 16),
                              Text(
                                'Loupe View',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Drag and drop an image or folder here to begin',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final newWidth = constraints.maxWidth;
                            final newHeight = constraints.maxHeight;

                            if (_imageWidth != null &&
                                _imageHeight != null &&
                                (newWidth != (_cachedViewportWidth ?? 0.0) ||
                                    newHeight !=
                                        (_cachedViewportHeight ?? 0.0))) {
                              _cachedViewportWidth = newWidth;
                              _cachedViewportHeight = newHeight;

                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (kDebugMode) {
                                  print(
                                      'Window resized! Width: $newWidth, Height: $newHeight, IsFit: $_isFitToWindow');
                                }
                                if (_isFitToWindow) {
                                  // Dynamically re-fit to the new window dimensions
                                  _zoomToFit(newWidth, newHeight);
                                } else {
                                  // Maintain current fixed zoom percent, recenter canvas
                                  final scale = _zoomPercent / 100.0;
                                  final dx =
                                      (newWidth - _imageWidth! * scale) / 2;
                                  final dy =
                                      (newHeight - _imageHeight! * scale) / 2;

                                  _transformationController.value =
                                      Matrix4.identity()
                                        ..translateByDouble(dx, dy, 0.0, 1.0)
                                        ..scaleByDouble(scale, scale, 1.0, 1.0);
                                }
                              });
                            }

                            return Container(
                              color: const Color(0xFF121212),
                              child: InteractiveViewer(
                                transformationController:
                                    _transformationController,
                                scaleEnabled:
                                    false, // Handled manually via scroll and buttons
                                panEnabled: true,
                                minScale: 0.1,
                                maxScale: 8.0,
                                constrained: false,
                                child: SizedBox(
                                  width: _imageWidth!.toDouble(),
                                  height: _imageHeight!.toDouble(),
                                  child: Image.file(_loadedImageFile!),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),

              // 2. Docked Footer Status Bar / HUD
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ImageViewerHUD(
                  fileType: _fileExtension,
                  dimensions: _dimensions,
                  fileSize: _fileSizeStr,
                  currentZoom: _zoomPercent / 100.0,
                  onZoomSliderChanged: (value) => _setZoomPercent(
                      (value * 100).round(),
                      _cachedViewportWidth ?? 0.0,
                      _cachedViewportHeight ?? 0.0),
                  onZoomSelected: (value) => _setZoomPercent(
                      (value * 100).round(),
                      _cachedViewportWidth ?? 0.0,
                      _cachedViewportHeight ?? 0.0),
                  onZoomIn: _zoomIn,
                  onZoomOut: _zoomOut,
                  onZoomFit: () => _zoomToFit(_cachedViewportWidth ?? 0.0,
                      _cachedViewportHeight ?? 0.0),
                ),
              ),
            ],
          )),
    );
  }
}
