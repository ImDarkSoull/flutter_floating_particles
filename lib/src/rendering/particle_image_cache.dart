import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Loads and caches the source images that particle sprites are built from:
/// image paths, [ImageProvider]s and custom widgets.
///
/// Every load returns a clone of the cached image that the caller owns and
/// must dispose, so evicting or clearing the cache never invalidates an image
/// that is still in use.
abstract final class ParticleImageCache {
  /// Maximum number of decoded images kept in memory.
  static const int maxEntries = 32;

  /// Longest side, in pixels, that SVGs are rasterized at.
  static const double svgResolution = 256;

  static final Map<Object, ui.Image> _images = {};
  static final Map<Object, Future<ui.Image?>> _pending = {};

  /// Sources that failed to load. They are only retried when requested
  /// explicitly (`retryFailed`) or after [clear].
  static final Set<Object> _failed = {};

  /// Loads an asset path or `http(s)` URL; `.svg` files are rasterized.
  static Future<ui.Image?> loadPath(
    String path,
    ImageConfiguration configuration, {
    bool retryFailed = false,
  }) {
    return _load(path, retryFailed, () {
      if (isSvgPath(path)) return _loadSvg(path);
      return _resolveProvider(providerForPath(path), configuration);
    });
  }

  /// Loads any [ImageProvider].
  static Future<ui.Image?> loadProvider(
    ImageProvider provider,
    ImageConfiguration configuration, {
    bool retryFailed = false,
  }) {
    return _load(
      provider,
      retryFailed,
      () => _resolveProvider(provider, configuration),
    );
  }

  /// Renders [widget] in a [size] x [size] box at the device pixel ratio of
  /// [view].
  static Future<ui.Image?> loadWidget(
    Widget widget,
    double size,
    ui.FlutterView view, {
    bool retryFailed = false,
  }) {
    return _load(widget, retryFailed, () => _widgetToImage(widget, size, view));
  }

  /// Whether [key] (a path, provider or widget) is currently cached.
  static bool contains(Object key) => _images.containsKey(key);

  /// Whether [key] (a path, provider or widget) is currently loading.
  static bool isLoading(Object key) => _pending.containsKey(key);

  /// The cached image for [key], without cloning. For tests only.
  @visibleForTesting
  static ui.Image? debugPeek(Object key) => _images[key];

  /// Disposes all cached images and forgets failed loads.
  static void clear() {
    for (final image in _images.values) {
      image.dispose();
    }
    _images.clear();
    _failed.clear();
  }

  /// Whether [path] is an `http` or `https` URL.
  static bool isNetworkPath(String path) {
    final lower = path.toLowerCase();
    return lower.startsWith('http://') || lower.startsWith('https://');
  }

  /// Whether [path] points to an SVG file (ignoring any URL query).
  static bool isSvgPath(String path) {
    final uriPath = Uri.tryParse(path)?.path ?? path;
    return uriPath.toLowerCase().endsWith('.svg');
  }

  /// The [ImageProvider] used for a raster image [path].
  static ImageProvider providerForPath(String path) {
    return isNetworkPath(path) ? NetworkImage(path) : AssetImage(path);
  }

  static Future<ui.Image?> _load(
    Object key,
    bool retryFailed,
    Future<ui.Image> Function() loader,
  ) {
    final cached = _images[key];
    if (cached != null) return Future.value(cached.clone());
    if (!retryFailed && _failed.contains(key)) return Future.value(null);

    final pending = _pending[key];
    if (pending != null) {
      return pending.then((image) => image?.clone());
    }

    // Registered before the loader runs, so a loader that fails
    // synchronously cannot leave a stale entry behind.
    final completer = Completer<ui.Image?>();
    _pending[key] = completer.future;

    unawaited(() async {
      ui.Image? result;
      try {
        final image = await loader();
        _store(key, image);
        _failed.remove(key);
        result = image.clone();
      } catch (e) {
        _failed.add(key);
        debugPrint('flutter_floating_particles: failed to load $key: $e');
      }
      // The removed entry is completer.future, which completes just below
      unawaited(_pending.remove(key));
      completer.complete(result);
    }());

    return completer.future;
  }

  static void _store(Object key, ui.Image image) {
    _images.remove(key)?.dispose();
    _images[key] = image;
    while (_images.length > maxEntries) {
      final oldest = _images.keys.first;
      _images.remove(oldest)?.dispose();
    }
  }

  static Future<ui.Image> _resolveProvider(
    ImageProvider provider,
    ImageConfiguration configuration,
  ) {
    final completer = Completer<ui.Image>();
    final stream = provider.resolve(configuration);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, synchronousCall) {
        if (!completer.isCompleted) {
          completer.complete(info.image.clone());
        }
        info.dispose();
        // Removing synchronously during addListener is not allowed
        scheduleMicrotask(() => stream.removeListener(listener));
      },
      onError: (error, stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
        scheduleMicrotask(() => stream.removeListener(listener));
      },
    );
    stream.addListener(listener);
    return completer.future;
  }

  static Future<ui.Image> _loadSvg(String path) async {
    final BytesLoader loader = isNetworkPath(path)
        ? SvgNetworkLoader(path)
        : SvgAssetLoader(path);
    final PictureInfo pictureInfo = await vg.loadPicture(
      loader,
      null,
      clipViewbox: false,
    );

    try {
      final Size bounds = pictureInfo.size;
      final bool hasBounds = bounds.width > 0 && bounds.height > 0;
      final double scale = hasBounds
          ? svgResolution / max(bounds.width, bounds.height)
          : 1.0;
      final int width = hasBounds
          ? max(1, (bounds.width * scale).round())
          : svgResolution.toInt();
      final int height = hasBounds
          ? max(1, (bounds.height * scale).round())
          : svgResolution.toInt();

      final recorder = ui.PictureRecorder();
      Canvas(recorder)
        ..scale(scale, scale)
        ..drawPicture(pictureInfo.picture);
      final picture = recorder.endRecording();
      try {
        return picture.toImageSync(width, height);
      } finally {
        picture.dispose();
      }
    } finally {
      pictureInfo.picture.dispose();
    }
  }

  /// Converts a Flutter widget to ui.Image at the device pixel ratio
  static Future<ui.Image> _widgetToImage(
    Widget widget,
    double size,
    ui.FlutterView view,
  ) async {
    final devicePixelRatio = view.devicePixelRatio;
    final logicalSize = Size.square(size);
    final repaintBoundary = RenderRepaintBoundary();
    // Sized explicitly rather than from the view, whose size can still be
    // zero while the app starts (e.g. on Android)
    final renderView = RenderView(
      view: view,
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: repaintBoundary,
      ),
      configuration: ViewConfiguration(
        logicalConstraints: BoxConstraints.tight(logicalSize),
        physicalConstraints: BoxConstraints.tight(
          logicalSize * devicePixelRatio,
        ),
        devicePixelRatio: devicePixelRatio,
      ),
    );

    final pipelineOwner = PipelineOwner();
    final focusManager = FocusManager();
    final buildOwner = BuildOwner(focusManager: focusManager);

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: MediaQuery(
        data: MediaQueryData.fromView(view),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(width: size, height: size, child: widget),
        ),
      ),
    ).attachToRenderTree(buildOwner);

    try {
      buildOwner.buildScope(rootElement);
      buildOwner.finalizeTree();

      pipelineOwner.flushLayout();
      pipelineOwner.flushCompositingBits();
      pipelineOwner.flushPaint();

      return await repaintBoundary.toImage(pixelRatio: devicePixelRatio);
    } finally {
      // Tear down the offscreen tree so its elements, render objects and
      // layers are released.
      RenderObjectToWidgetAdapter<RenderBox>(
        container: repaintBoundary,
      ).attachToRenderTree(buildOwner, rootElement);
      buildOwner.finalizeTree();
      pipelineOwner.rootNode = null;
      pipelineOwner.dispose();
      renderView.dispose();
      focusManager.dispose();
    }
  }
}
