import 'dart:isolate';
import 'package:camera/camera.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../desktop_tracker/desktop_capture_driver.dart';
import '../scanner_core/media/image_frame_decoder.dart';
import 'camera_frame_processor.dart';

/// Shared helper for converting [CameraImage] streams into upright BGRA8888
/// [CapturedFrame]s, selecting platform-optimal image formats, and picking
/// still photos across both Mobile and Desktop/Web camera flows.
class CameraImageConverter {
  CameraImageConverter._();

  /// Returns the platform-appropriate [ImageFormatGroup] for [CameraController].
  static ImageFormatGroup? preferredImageFormatGroup() {
    if (kIsWeb) return null;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return ImageFormatGroup.bgra8888;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return ImageFormatGroup.yuv420;
    }
    return null;
  }

  /// Converts a [CameraImage] (3-plane YUV420, 2-plane NV21/NV12, or single-plane BGRA8888)
  /// into an upright BGRA8888 [CapturedFrame] rotated according to [sensorOrientation]
  /// and optional [deviceOrientation].
  static CapturedFrame? convertToUprightBgra(
    CameraImage image,
    int sensorOrientation, {
    DeviceOrientation? deviceOrientation,
    bool isFrontCamera = false,
  }) {
    final effectiveRotation = CameraFrameProcessor.resolveEffectiveRotationDegrees(
      sensorOrientation: sensorOrientation,
      deviceRotationDegrees:
          CameraFrameProcessor.deviceOrientationToDegrees(deviceOrientation),
      isFrontCamera: isFrontCamera,
    );

    if (image.planes.length >= 3) {
      final yPlane = image.planes[0];
      final uPlane = image.planes[1];
      final vPlane = image.planes[2];
      return CameraFrameProcessor.convertYuv420ToBgraFrame(
        width: image.width,
        height: image.height,
        yBytes: yPlane.bytes,
        uBytes: uPlane.bytes,
        vBytes: vPlane.bytes,
        yRowStride: yPlane.bytesPerRow,
        uvRowStride: uPlane.bytesPerRow,
        uvPixelStride: uPlane.bytesPerPixel ?? 1,
        sensorOrientation: effectiveRotation,
      );
    }

    if (image.planes.length == 2) {
      final yPlane = image.planes[0];
      final uvPlane = image.planes[1];
      final isNv21 = image.format.group == ImageFormatGroup.nv21;
      return CameraFrameProcessor.convertTwoPlaneYuvToBgraFrame(
        width: image.width,
        height: image.height,
        yBytes: yPlane.bytes,
        uvBytes: uvPlane.bytes,
        yRowStride: yPlane.bytesPerRow,
        uvRowStride: uvPlane.bytesPerRow,
        isNv21Order: isNv21,
        sensorOrientation: effectiveRotation,
      );
    }

    if (image.planes.isNotEmpty) {
      final p = image.planes.first;
      // Single-plane NV21 (some Android devices report 1 packed Y+VU plane)
      if (image.format.group == ImageFormatGroup.nv21 &&
          p.bytes.length < image.width * image.height * 4) {
        final yLen = image.width * image.height;
        if (p.bytes.length > yLen) {
          final yBytes = Uint8List.sublistView(p.bytes, 0, yLen);
          final uvBytes = Uint8List.sublistView(p.bytes, yLen);
          return CameraFrameProcessor.convertTwoPlaneYuvToBgraFrame(
            width: image.width,
            height: image.height,
            yBytes: yBytes,
            uvBytes: uvBytes,
            yRowStride: image.width,
            uvRowStride: image.width,
            isNv21Order: true,
            sensorOrientation: effectiveRotation,
          );
        }
      }

      final bgra = CameraFrameProcessor.extractPackedBgraBytes(
        planeBytes: p.bytes,
        width: image.width,
        height: image.height,
        bytesPerRow: p.bytesPerRow,
      );
      return CameraFrameProcessor.rotateBgraFrame(
        CapturedFrame(
          width: image.width,
          height: image.height,
          bytes: bgra,
          pixelFormat: 'bgra8888',
          captureMethod: 'camera_bgra',
        ),
        effectiveRotation,
      );
    }

    return null;
  }

  /// Snapshots [CameraImage] planes synchronously using zero-copy [TransferableTypedData]
  /// and executes YUV/BGRA conversion + rotation on a background isolate (falling back to synchronous on Web).
  static Future<CapturedFrame?> convertCameraImageInIsolate(
    CameraImage image,
    int sensorOrientation, {
    DeviceOrientation? deviceOrientation,
    bool isFrontCamera = false,
  }) async {
    final effectiveRotation = CameraFrameProcessor.resolveEffectiveRotationDegrees(
      sensorOrientation: sensorOrientation,
      deviceRotationDegrees:
          CameraFrameProcessor.deviceOrientationToDegrees(deviceOrientation),
      isFrontCamera: isFrontCamera,
    );
    final width = image.width;
    final height = image.height;
    final formatGroup = image.format.group;
    final rowStrides = image.planes
        .map((p) => p.bytesPerRow)
        .toList(growable: false);
    final pixelStrides = image.planes
        .map((p) => p.bytesPerPixel ?? 1)
        .toList(growable: false);

    if (kIsWeb) {
      final planeBytes = image.planes
          .map((p) => Uint8List.fromList(p.bytes))
          .toList(growable: false);
      return _convertRawPlanes(
        width: width,
        height: height,
        formatGroup: formatGroup,
        planeBytes: planeBytes,
        rowStrides: rowStrides,
        pixelStrides: pixelStrides,
        effectiveRotation: effectiveRotation,
      );
    }

    final transferablePlanes = image.planes
        .map((p) => TransferableTypedData.fromList([p.bytes]))
        .toList(growable: false);

    final packedResult = await Isolate.run(() {
      final planeBytes = transferablePlanes
          .map((t) => t.materialize().asUint8List())
          .toList(growable: false);
      final converted = _convertRawPlanes(
        width: width,
        height: height,
        formatGroup: formatGroup,
        planeBytes: planeBytes,
        rowStrides: rowStrides,
        pixelStrides: pixelStrides,
        effectiveRotation: effectiveRotation,
      );
      if (converted == null) return null;
      return (
        width: converted.width,
        height: converted.height,
        bytes: TransferableTypedData.fromList([
          converted.bytes is Uint8List
              ? converted.bytes as Uint8List
              : Uint8List.fromList(converted.bytes),
        ]),
        pixelFormat: converted.pixelFormat,
        captureMethod: converted.captureMethod,
      );
    });

    if (packedResult == null) return null;
    return CapturedFrame(
      width: packedResult.width,
      height: packedResult.height,
      bytes: packedResult.bytes.materialize().asUint8List(),
      pixelFormat: packedResult.pixelFormat,
      captureMethod: packedResult.captureMethod,
    );
  }

  static CapturedFrame? _convertRawPlanes({
    required int width,
    required int height,
    required ImageFormatGroup formatGroup,
    required List<Uint8List> planeBytes,
    required List<int> rowStrides,
    required List<int> pixelStrides,
    required int effectiveRotation,
  }) {
    if (planeBytes.length >= 3) {
      return CameraFrameProcessor.convertYuv420ToBgraFrame(
        width: width,
        height: height,
        yBytes: planeBytes[0],
        uBytes: planeBytes[1],
        vBytes: planeBytes[2],
        yRowStride: rowStrides[0],
        uvRowStride: rowStrides[1],
        uvPixelStride: pixelStrides[1],
        sensorOrientation: effectiveRotation,
      );
    }

    if (planeBytes.length == 2) {
      return CameraFrameProcessor.convertTwoPlaneYuvToBgraFrame(
        width: width,
        height: height,
        yBytes: planeBytes[0],
        uvBytes: planeBytes[1],
        yRowStride: rowStrides[0],
        uvRowStride: rowStrides[1],
        isNv21Order: formatGroup == ImageFormatGroup.nv21,
        sensorOrientation: effectiveRotation,
      );
    }

    if (planeBytes.isNotEmpty) {
      final p0 = planeBytes.first;
      if (formatGroup == ImageFormatGroup.nv21 &&
          p0.length < width * height * 4) {
        final yLen = width * height;
        if (p0.length > yLen) {
          return CameraFrameProcessor.convertTwoPlaneYuvToBgraFrame(
            width: width,
            height: height,
            yBytes: Uint8List.sublistView(p0, 0, yLen),
            uvBytes: Uint8List.sublistView(p0, yLen),
            yRowStride: width,
            uvRowStride: width,
            isNv21Order: true,
            sensorOrientation: effectiveRotation,
          );
        }
      }

      final bgra = CameraFrameProcessor.extractPackedBgraBytes(
        planeBytes: p0,
        width: width,
        height: height,
        bytesPerRow: rowStrides.first,
      );
      return CameraFrameProcessor.rotateBgraFrame(
        CapturedFrame(
          width: width,
          height: height,
          bytes: bgra,
          pixelFormat: 'bgra8888',
          captureMethod: 'camera_bgra',
        ),
        effectiveRotation,
      );
    }

    return null;
  }

  /// Picks an image file via system file selector (or [overridePicker]) and
  /// decodes it into an RGBA/BGRA [CapturedFrame] for single-shot OCR.
  static Future<CapturedFrame?> pickAndDecodePhotoFrame({
    Future<CapturedFrame?> Function()? overridePicker,
  }) async {
    if (overridePicker != null) {
      return overridePicker();
    }
    const typeGroup = XTypeGroup(
      label: 'Bilder',
      extensions: ['png', 'jpg', 'jpeg', 'webp', 'bmp'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return ImageFrameDecoder.decodeBytesToBgraFrame(bytes);
  }

  /// Classifies whether a [CameraException] represents denied OS/browser permission
  /// and returns a localized, actionable error description.
  static ({bool isPermissionDenied, String message}) formatCameraError(
    CameraException error,
  ) {
    final code = error.code.toLowerCase();
    final isDenied = code.contains('access') ||
        code.contains('denied') ||
        code.contains('permission') ||
        code.contains('notallowed');
    final desc = error.description ?? error.code;
    final message = kIsWeb
        ? '$desc (Hinweis: Browser-Webcams benötigen HTTPS oder localhost.)'
        : desc;
    return (isPermissionDenied: isDenied, message: message);
  }
}
