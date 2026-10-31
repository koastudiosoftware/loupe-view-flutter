import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ImageInspectorViewModel extends ChangeNotifier {
  final TransformationController transformationController =
      TransformationController();

  // collection index/total
  int _imageIndex = 1;
  int get imageIndex => _imageIndex;

  int _totalImages = 1;
  int get totalImages => _totalImages;

  // Info panel visibility state
  bool _isInfoVisible = false;
  bool get isInfoVisible => _isInfoVisible;

  // Image zoom/scale state
  int _zoomPercent = 100;
  int get zoomPercent => _zoomPercent;

  bool _isFitToWindow = true;
  bool get isFitToWindow => _isFitToWindow;

  int? _imageWidth;
  int? _imageHeight;
  int? get imageWidth => _imageWidth;
  int? get imageHeight => _imageHeight;

  double? _cachedViewportWidth;
  double? _cachedViewportHeight;

  double _zoomLevel = 1.0;
  double get zoomLevel => _zoomLevel;

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

  ImageInspectorViewModel() {
    transformationController.addListener(_onTransformationChanged);
  }

  @override
  void dispose() {
    transformationController.removeListener(_onTransformationChanged);
    transformationController.dispose();
    super.dispose();
  }

  void _onTransformationChanged() {
    final currentScale = transformationController.value.getMaxScaleOnAxis();
    if ((currentScale - _zoomLevel).abs() > 0.005) {
      _zoomLevel = currentScale.clamp(0.1, 8.0);
      notifyListeners();
    }
  }

void toggleInfoPanel() {
    _isInfoVisible = !_isInfoVisible;
    notifyListeners();
  }

  void setImageDimensions(int width, int height) {
    _imageWidth = width;
    _imageHeight = height;
    notifyListeners();
  }

  void setImageIndex(int index, int total) {
    _imageIndex = index;
    _totalImages = total;
    notifyListeners();
  }

  void updateViewport(double width, double height) {
    if (_cachedViewportWidth == width && _cachedViewportHeight == height) {
      return;
    }

    final sizeChanged =
        (_cachedViewportWidth != width || _cachedViewportHeight != height);
    _cachedViewportWidth = width;
    _cachedViewportHeight = height;

    if (sizeChanged && _imageWidth != null && _imageHeight != null) {
      if (_isFitToWindow) {
        zoomToFit(width, height);
      } else {
        final scale = _zoomPercent / 100.0;
        final dx = (width - _imageWidth! * scale) / 2;
        final dy = (height - _imageHeight! * scale) / 2;
        transformationController.value = Matrix4.identity()
          ..translateByDouble(dx, dy, 0.0, 1.0)
          ..scaleByDouble(scale, scale, 1.0, 1.0);
      }
    }
  }

  void zoomIn() {
    if (kDebugMode) print('-> _isFitToWindow set to FALSE by zoomIn');
    _isFitToWindow = false;
    int currentIndex = zoomPresets.indexWhere((p) => p > _zoomPercent);
    if (currentIndex == -1) currentIndex = zoomPresets.length - 1;
    setZoomPercent(zoomPresets[currentIndex], _cachedViewportWidth ?? 0.0,
        _cachedViewportHeight ?? 0.0);
  }

  void zoomOut() {
    if (kDebugMode) print('-> _isFitToWindow set to FALSE by zoomOut');
    _isFitToWindow = false;
    int currentIndex = zoomPresets.lastIndexWhere((p) => p < _zoomPercent);
    if (currentIndex == -1) currentIndex = 0;
    setZoomPercent(zoomPresets[currentIndex], _cachedViewportWidth ?? 0.0,
        _cachedViewportHeight ?? 0.0);
  }

  void zoomToFit([double? viewportWidth, double? viewportHeight]) {
    final width = viewportWidth ?? _cachedViewportWidth ?? 0.0;
    final height = viewportHeight ?? _cachedViewportHeight ?? 0.0;

    if (_imageWidth == null ||
        _imageHeight == null ||
        _imageWidth == 0 ||
        _imageHeight == 0 ||
        width == 0 ||
        height == 0) {
      return;
    }

    final scaleX = width / _imageWidth!;
    final scaleY = height / _imageHeight!;
    double fitScale = scaleX < scaleY ? scaleX : scaleY;
    fitScale = fitScale.clamp(0.1, 8.0);

    final fitPercent = (fitScale * 100).round();
    if (kDebugMode) print('-> _isFitToWindow set to TRUE by zoomToFit');

    setZoomPercent(fitPercent, width, height, isFit: true);
  }

  void setZoomPercent(int percent, double viewportWidth, double viewportHeight,
      {bool isFit = false}) {
    if (_imageWidth == null ||
        _imageHeight == null ||
        _imageWidth == 0 ||
        _imageHeight == 0) {
      return;
    }

    // Fall back to internal cache if 0 is passed from the UI
    final targetWidth =
        viewportWidth > 0 ? viewportWidth : (_cachedViewportWidth ?? 0.0);
    final targetHeight =
        viewportHeight > 0 ? viewportHeight : (_cachedViewportHeight ?? 0.0);

    if (kDebugMode) print('-> _isFitToWindow set to $isFit by setZoomPercent');
    _isFitToWindow = isFit;

    final clampedPercent = percent.clamp(10, 800);
    final scale = clampedPercent / 100.0;

    _zoomPercent = clampedPercent;
    notifyListeners();

    if (targetWidth > 0 && targetHeight > 0) {
      final dx = (targetWidth - _imageWidth! * scale) / 2;
      final dy = (targetHeight - _imageHeight! * scale) / 2;

      transformationController.value = Matrix4.identity()
        ..translateByDouble(dx, dy, 0.0, 1.0)
        ..scaleByDouble(scale, scale, 1.0, 1.0);
    }
  }

  void zoomByStep(int delta) {
    if (kDebugMode) print('-> _isFitToWindow set to FALSE by zoomByStep');
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
    setZoomPercent(
        newPercent, _cachedViewportWidth ?? 0.0, _cachedViewportHeight ?? 0.0);
  }
}
