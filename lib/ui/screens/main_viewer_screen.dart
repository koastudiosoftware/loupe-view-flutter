import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/gestures.dart';
import '../components/window_title_bar.dart';
import '../components/image_viewer_hud.dart';

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
  bool _isFitToWindow = true;

  // Clean integer percentage table for presets
  static const List<int> zoomPresets = [
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
    if (kDebugMode) print('-> _isFitToWindow set to FALSE by _zoomIn');
    _isFitToWindow = false;
    int currentIndex = zoomPresets.indexWhere((p) => p > _zoomPercent);
    if (currentIndex == -1) currentIndex = zoomPresets.length - 1;
    _setZoomPercent(zoomPresets[currentIndex], _cachedViewportWidth ?? 0.0,
        _cachedViewportHeight ?? 0.0);
  }

  void _zoomOut() {
    if (kDebugMode) print('-> _isFitToWindow set to FALSE by _zoomOut');
    _isFitToWindow = false;
    int currentIndex = zoomPresets.lastIndexWhere((p) => p < _zoomPercent);
    if (currentIndex == -1) currentIndex = 0;
    _setZoomPercent(zoomPresets[currentIndex], _cachedViewportWidth ?? 0.0,
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
    if (kDebugMode) print('-> _isFitToWindow set to TRUE by _zoomToFit');

    _setZoomPercent(fitPercent, viewportWidth, viewportHeight, isFit: true);
  }

  void _setZoomPercent(int percent, double viewportWidth, double viewportHeight,
      {bool isFit = false}) {
    if (_imageWidth == null ||
        _imageHeight == null ||
        _imageWidth == 0 ||
        _imageHeight == 0) return;

    if (kDebugMode) print('-> _isFitToWindow set to $isFit by _setZoomPercent');
    _isFitToWindow = isFit;

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
    if (kDebugMode) print('-> _isFitToWindow set to FALSE by _zoomByStep');
    _isFitToWindow = false;
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
        appBar: WindowTitleBar(currentTitle: _fileName),
        body: Stack(
          children: [
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
                                _zoomToFit(newWidth, newHeight);
                              } else {
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
                              scaleEnabled: false,
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
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ImageViewerHUD(
                fileType: _fileExtension,
                dimensions: _dimensions,
                fileSize: _fileSizeStr,
                currentZoom: _zoomPercent / 100.0,
                zoomPresets: zoomPresets,
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
                onZoomFit: () => _zoomToFit(
                    _cachedViewportWidth ?? 0.0, _cachedViewportHeight ?? 0.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
