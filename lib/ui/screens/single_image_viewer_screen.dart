import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/gestures.dart';
import 'package:exif/exif.dart'; // Ensure exif package is imported
import '../components/window_title_bar.dart';
import '../components/image_viewer_hud.dart';
import '../../viewmodels/image_inspector_vm.dart';
import '../components/image_info_panel.dart';

class SingleImageViewerScreen extends StatefulWidget {
  const SingleImageViewerScreen({super.key});

  @override
  State<SingleImageViewerScreen> createState() =>
      _SingleImageViewerScreenState();
}

class _SingleImageViewerScreenState extends State<SingleImageViewerScreen> {
  late final ImageInspectorViewModel _viewModel;

  File? _loadedImageFile;
  String _fileName = 'No Image Loaded';
  String _fileBaseName = '---';
  String _fileExtension = '---';
  String _dimensions = '---';
  String _folderPath = '---';
  int _fileSizeCategory = 0;
  Map<String, String> _rawExifData = {};
  bool _isDraggingOver = false;

  @override
  void initState() {
    super.initState();
    _viewModel = ImageInspectorViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '---';
    if (bytes < 1024) return '$bytes Bytes';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Future<Map<String, String>> _collectExifData(File file) async {
    final Map<String, String> exifMap = {};
    try {
      final fileBytes = await file.readAsBytes();
      final tags = await readExifFromBytes(fileBytes);

      if (tags.isEmpty) {
        if (kDebugMode) print('EXIF DEBUG: No EXIF tags found in ${file.path}');
        return exifMap;
      }

      tags.forEach((key, value) {
        exifMap[key] = value.toString();
      });

      if (kDebugMode) {
        print('--- EXIF HASH MAP CONTENTS FOR: ${p.basename(file.path)} ---');
        exifMap.forEach((k, v) {
          if (kDebugMode) {
            print('$k: $v');
          }
        });
        print('------------------------------------------------------------');
      }
    } catch (e) {
      if (kDebugMode) print('EXIF DEBUG ERROR: Failed to parse EXIF - $e');
    }

    return exifMap;
  }

  Future<void> _handleDroppedFile(File file) async {
    final bytes = await file.length();
    final ext = p.extension(file.path).toUpperCase();
    final name = p.basename(file.path);
    final baseName = p.basenameWithoutExtension(file.path);
    final folderPath = p.dirname(file.path);

    // Collect real EXIF tags into the hash map
    final extractedExif = await _collectExifData(file);

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
      _fileName = name;
      _fileBaseName = baseName;
      _fileExtension = ext;
      _fileSizeCategory = bytes;
      _dimensions = dimensionsStr;
      _folderPath = folderPath;
      _rawExifData = extractedExif; // Properly assign the extracted EXIF map here
    });

    if (width != null && height != null) {
      _viewModel.setImageDimensions(width, height);
    }

    _viewModel.setImageIndex(1, 1);
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
        appBar: WindowTitleBar(
          currentTitle: _loadedImageFile == null
              ? 'Loupe View'
              : '$_fileName [${_viewModel.imageIndex}/${_viewModel.totalImages}]',
        ),
        body: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, child) {
            return Stack(
              children: [
                // 1. Background Canvas / Image View Area
                Positioned.fill(
                  child: AnimatedPadding(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    padding: EdgeInsets.only(
                        left: _viewModel.isInfoVisible ? 400.0 : 0.0),
                    child: Listener(
                      onPointerSignal: (pointerSignal) {
                        if (pointerSignal is PointerScrollEvent) {
                          final int step =
                              pointerSignal.scrollDelta.dy < 0 ? 10 : -10;
                          _viewModel.zoomByStep(step);
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
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  _viewModel.updateViewport(
                                      constraints.maxWidth,
                                      constraints.maxHeight);
                                });

                                return Container(
                                  color: const Color(0xFF121212),
                                  child: InteractiveViewer(
                                    transformationController:
                                        _viewModel.transformationController,
                                    scaleEnabled: false,
                                    panEnabled: true,
                                    minScale: 0.1,
                                    maxScale: 8.0,
                                    constrained: false,
                                    child: SizedBox(
                                      width: (_viewModel.imageWidth ?? 100)
                                          .toDouble(),
                                      height: (_viewModel.imageHeight ?? 100)
                                          .toDouble(),
                                      child: Image.file(_loadedImageFile!),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ),

                // 2. Left Slide-Out Info Panel (400px width)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  left: _viewModel.isInfoVisible ? 0 : -400,
                  top: 0,
                  bottom: 44,
                  width: 400,
                  child: ImageInfoPanel(
                    folderPath: _folderPath,
                    fileName: _fileBaseName,
                    filePath: _loadedImageFile?.path ?? 'No file path',
                    fileSize: _fileSizeCategory,
                    dimensions: _dimensions,
                    exifData: _rawExifData,
                    onClose: _viewModel.toggleInfoPanel,
                  ),
                ),

                // 3. Docked Footer Status Bar / HUD
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ImageViewerHUD(
                    fileType: _fileExtension,
                    dimensions: _dimensions,
                    fileSize: _fileSizeCategory == 0
                        ? '---'
                        : _formatBytes(_fileSizeCategory),
                    currentZoom: _viewModel.zoomPercent / 100.0,
                    zoomPresets: ImageInspectorViewModel.zoomPresets,
                    onZoomSliderChanged: (value) =>
                        _viewModel.setZoomPercent((value * 100).round(), 0, 0),
                    onZoomSelected: (value) =>
                        _viewModel.setZoomPercent((value * 100).round(), 0, 0),
                    onZoomIn: _viewModel.zoomIn,
                    onZoomOut: _viewModel.zoomOut,
                    onZoomFit: _viewModel.zoomToFit,
                    onToggleInfo: _viewModel.toggleInfoPanel,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}