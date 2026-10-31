import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/gestures.dart';
import '../components/window_title_bar.dart';
import '../components/image_viewer_hud.dart';
import '../../viewmodels/image_inspector_vm.dart'; // Import your new ViewModel

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
  String _fileExtension = '---';
  String _dimensions = '---';
  String _fileSizeStr = '---';
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
    });

    if (width != null && height != null) {
      _viewModel.setImageDimensions(width, height);
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
        body: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, child) {
            return Stack(
              children: [
                Positioned.fill(
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
                              // Feed layout size changes to the ViewModel safely
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _viewModel.updateViewport(constraints.maxWidth,
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
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ImageViewerHUD(
                    fileType: _fileExtension,
                    dimensions: _dimensions,
                    fileSize: _fileSizeStr,
                    currentZoom: _viewModel.zoomPercent / 100.0,
                    zoomPresets: ImageInspectorViewModel.zoomPresets,
                    onZoomSliderChanged: (value) =>
                        _viewModel.setZoomPercent((value * 100).round(), 0, 0),
                    onZoomSelected: (value) =>
                        _viewModel.setZoomPercent((value * 100).round(), 0, 0),
                    onZoomIn: _viewModel.zoomIn,
                    onZoomOut: _viewModel.zoomOut,
                    onZoomFit: _viewModel.zoomToFit,
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
