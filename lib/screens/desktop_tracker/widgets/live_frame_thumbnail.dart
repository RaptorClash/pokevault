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

  void _maybeDecodeFrame() {
    final frame = widget.liveFrame;
    if (frame == null ||
        (identical(frame, _lastDecodedFrame) &&
            _lastDecodeWidth == widget.maxDecodeWidth)) {
      return;
    }
    _lastDecodedFrame = frame;
    _lastDecodeWidth = widget.maxDecodeWidth;

    if (frame.pixelFormat == 'bgra8888' &&
        frame.width > 0 &&
        frame.height > 0 &&
        frame.bytes.length >= frame.width * frame.height * 4) {
      final rawBytes = frame.bytes is Uint8List
          ? frame.bytes as Uint8List
          : Uint8List.fromList(frame.bytes);
      final maxW = widget.maxDecodeWidth;
      int? targetWidth;
      int? targetHeight;
      if (maxW != null && maxW > 0 && frame.width > maxW) {
        targetWidth = maxW;
        targetHeight = (frame.height * maxW / frame.width).round().clamp(1, frame.height);
      }
      ui.decodeImageFromPixels(
        rawBytes,
        frame.width,
        frame.height,
        ui.PixelFormat.bgra8888,
        (image) {
          if (!mounted || !identical(widget.liveFrame, frame)) {
            image.dispose();
            return;
          }
          final prev = _decodedImage;
          setState(() {
            _decodedImage = image;
          });
          prev?.dispose();
        },
        targetWidth: targetWidth,
        targetHeight: targetHeight,
      );
    } else if (_decodedImage != null) {
      final prev = _decodedImage;
      _decodedImage = null;
      prev?.dispose();
    }
  }

  @override
  void dispose() {
    _decodedImage?.dispose();
    _decodedImage = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frame = widget.liveFrame;
    final Widget content;
    if (frame != null && frame.pixelFormat == 'png' && frame.bytes.isNotEmpty) {
      content = Image.memory(
        frame.bytes is Uint8List
            ? frame.bytes as Uint8List
            : Uint8List.fromList(frame.bytes),
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
