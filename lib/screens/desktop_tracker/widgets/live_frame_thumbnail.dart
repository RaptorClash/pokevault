import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../../../services/desktop_tracker/desktop_capture_driver.dart';

/// Renders either encoded PNG preview bytes or raw BGRA8888 [CapturedFrame] pixels.
class LiveFrameThumbnail extends StatefulWidget {
  final CapturedFrame? liveFrame;
  final Uint8List? fallbackPngBytes;
  final IconData fallbackIcon;
  final int? maxDecodeWidth;

  const LiveFrameThumbnail({
    super.key,
    required this.liveFrame,
    required this.fallbackPngBytes,
    required this.fallbackIcon,
    this.maxDecodeWidth = 320,
  });

  @override
  State<LiveFrameThumbnail> createState() => _LiveFrameThumbnailState();
}

class _LiveFrameThumbnailState extends State<LiveFrameThumbnail> {
  ui.Image? _decodedImage;
  CapturedFrame? _lastDecodedFrame;
  int? _lastDecodeWidth;
  bool _decodingInFlight = false;
  CapturedFrame? _pendingFrame;
  int? _pendingDecodeWidth;
  CapturedFrame? _cachedPngFrame;
  Uint8List? _cachedPngBytes;

  @override
  void initState() {
    super.initState();
    _maybeDecodeFrame();
  }

  @override
  void didUpdateWidget(covariant LiveFrameThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.liveFrame, oldWidget.liveFrame) ||
        widget.maxDecodeWidth != oldWidget.maxDecodeWidth) {
      _maybeDecodeFrame();
    }
  }

  void _disposeImageSafely(ui.Image? image) {
    if (image == null) return;
    try {
      WidgetsBinding.instance.addPostFrameCallback((_) => image.dispose());
    } catch (_) {
      image.dispose();
    }
  }

  void _maybeDecodeFrame() {
    final frame = widget.liveFrame;
    if (frame == null) {
      _lastDecodedFrame = null;
      _lastDecodeWidth = null;
      _pendingFrame = null;
      _pendingDecodeWidth = null;
      _cachedPngFrame = null;
      _cachedPngBytes = null;
      if (_decodedImage != null) {
        final prev = _decodedImage;
        _decodedImage = null;
        _disposeImageSafely(prev);
      }
      return;
    }

    if (identical(frame, _lastDecodedFrame) &&
        _lastDecodeWidth == widget.maxDecodeWidth) {
      return;
    }
    _lastDecodedFrame = frame;
    _lastDecodeWidth = widget.maxDecodeWidth;

    if (frame.pixelFormat == 'png' && frame.bytes.isNotEmpty) {
      if (!identical(_cachedPngFrame, frame)) {
        _cachedPngFrame = frame;
        _cachedPngBytes = frame.bytes is Uint8List
            ? frame.bytes as Uint8List
            : Uint8List.fromList(frame.bytes);
      }
      _pendingFrame = null;
      if (_decodedImage != null) {
        final prev = _decodedImage;
        _decodedImage = null;
        _disposeImageSafely(prev);
      }
      return;
    }

    _cachedPngFrame = null;
    _cachedPngBytes = null;

    if (frame.pixelFormat == 'bgra8888' &&
        frame.width > 0 &&
        frame.height > 0 &&
        frame.bytes.length >= frame.width * frame.height * 4) {
      if (_decodingInFlight) {
        _pendingFrame = frame;
        _pendingDecodeWidth = widget.maxDecodeWidth;
        return;
      }
      _decodeBgraFrame(frame, widget.maxDecodeWidth);
    } else if (_decodedImage != null) {
      final prev = _decodedImage;
      _decodedImage = null;
      _disposeImageSafely(prev);
    }
  }

  void _decodeBgraFrame(CapturedFrame frame, int? maxW) {
    _decodingInFlight = true;
    final rawBytes = frame.bytes is Uint8List
        ? frame.bytes as Uint8List
        : Uint8List.fromList(frame.bytes);
    int? targetWidth;
    int? targetHeight;
    if (maxW != null && maxW > 0 && frame.width > maxW) {
      targetWidth = maxW;
      targetHeight =
          (frame.height * maxW / frame.width).round().clamp(1, frame.height);
    }
    ui.decodeImageFromPixels(
      rawBytes,
      frame.width,
      frame.height,
      ui.PixelFormat.bgra8888,
      (image) {
        _decodingInFlight = false;
        if (!mounted || !identical(widget.liveFrame, frame)) {
          image.dispose();
          _drainPendingDecode();
          return;
        }
        final prev = _decodedImage;
        setState(() {
          _decodedImage = image;
        });
        _disposeImageSafely(prev);
        _drainPendingDecode();
      },
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );
  }

  void _drainPendingDecode() {
    if (!mounted || _decodingInFlight) return;
    final pending = _pendingFrame;
    final pendingWidth = _pendingDecodeWidth;
    _pendingFrame = null;
    _pendingDecodeWidth = null;
    if (pending != null && identical(widget.liveFrame, pending)) {
      _decodeBgraFrame(pending, pendingWidth);
    }
  }

  @override
  void dispose() {
    final img = _decodedImage;
    _decodedImage = null;
    _pendingFrame = null;
    _disposeImageSafely(img);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frame = widget.liveFrame;
    final Widget content;
    if (frame != null && frame.pixelFormat == 'png' && frame.bytes.isNotEmpty) {
      final pngBytes = identical(_cachedPngFrame, frame) &&
              _cachedPngBytes != null
          ? _cachedPngBytes!
          : (frame.bytes is Uint8List
              ? frame.bytes as Uint8List
              : Uint8List.fromList(frame.bytes));
      content = Image.memory(
        pngBytes,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        cacheWidth: widget.maxDecodeWidth,
        errorBuilder: (_, _, _) =>
            Icon(widget.fallbackIcon, size: 18, color: Colors.white54),
      );
    } else if (_decodedImage != null) {
      content = RawImage(
        image: _decodedImage,
        fit: BoxFit.contain,
      );
    } else if (widget.fallbackPngBytes != null &&
        widget.fallbackPngBytes!.isNotEmpty) {
      content = Image.memory(
        widget.fallbackPngBytes!,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        cacheWidth: widget.maxDecodeWidth,
        errorBuilder: (_, _, _) =>
            Icon(widget.fallbackIcon, size: 18, color: Colors.white54),
      );
    } else {
      content = Center(
        child: Icon(widget.fallbackIcon, size: 18, color: Colors.white54),
      );
    }
    return RepaintBoundary(child: content);
  }
}
