import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/services/desktop_tracker/desktop_capture_driver.dart';
import 'package:pokevault/services/mobile_scanner/camera_frame_processor.dart';
import 'package:pokevault/services/mobile_scanner/camera_frame_pump.dart';

CapturedFrame _dummyFrame() => CapturedFrame(
      width: 2,
      height: 2,
      bytes: Uint8List(16),
      pixelFormat: 'bgra8888',
    );

void main() {
  group('CameraFramePump (TDD & Adversarial)', () {
    test('uses live image stream when supported and does not engage polling fallback', () async {
      bool streamStarted = false;
      bool streamStopped = false;
      int takePictureCount = 0;

      final pump = CameraFramePump(
        startImageStream: () async {
          streamStarted = true;
        },
        stopImageStream: () async {
          streamStopped = true;
        },
        captureStillBytes: () async {
          takePictureCount++;
          return Uint8List(4);
        },
        decodeStillFrame: (_) async => _dummyFrame(),
        onDecodedFrame: (_) async {},
        pollInterval: const Duration(milliseconds: 25),
      );

      await pump.start();
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(streamStarted, isTrue);
      expect(pump.isUsingPollingFallback, isFalse);
      expect(takePictureCount, 0);

      await pump.dispose();
      expect(streamStopped, isTrue);
    });

    test('automatically falls back to takePicture polling when startImageStream throws UnimplementedError', () async {
      int takePictureCount = 0;
      final received = <CapturedFrame>[];

      final pump = CameraFramePump(
        startImageStream: () async {
          throw UnimplementedError('startImageStream is not implemented on web');
        },
        stopImageStream: () async {},
        captureStillBytes: () async {
          takePictureCount++;
          return Uint8List.fromList([1, 2, 3]);
        },
        decodeStillFrame: (_) async => _dummyFrame(),
        onDecodedFrame: (frame) async {
          received.add(frame);
        },
        pollInterval: const Duration(milliseconds: 25),
      );

      await pump.start();
      await Future<void>.delayed(const Duration(milliseconds: 95));

      expect(pump.isUsingPollingFallback, isTrue);
      expect(takePictureCount, greaterThanOrEqualTo(2));
      expect(received.length, greaterThanOrEqualTo(2));

      final countAtStop = takePictureCount;
      await pump.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(takePictureCount, countAtStop);
    });

    test('guards against overlapping still captures while slow decode is in flight', () async {
      int activeCalls = 0;
      int maxConcurrentCalls = 0;
      final decodeCompleter = Completer<CapturedFrame?>();

      final pump = CameraFramePump(
        startImageStream: () async => throw UnimplementedError(),
        stopImageStream: () async {},
        captureStillBytes: () async {
          activeCalls++;
          if (activeCalls > maxConcurrentCalls) {
            maxConcurrentCalls = activeCalls;
          }
          return Uint8List.fromList([1, 2, 3]);
        },
        decodeStillFrame: (_) async {
          final res = await decodeCompleter.future;
          activeCalls--;
          return res;
        },
        onDecodedFrame: (_) async {},
        pollInterval: const Duration(milliseconds: 15),
        forcePollingFallback: true,
      );

      await pump.start();
      await Future<void>.delayed(const Duration(milliseconds: 75));
      expect(maxConcurrentCalls, 1);

      decodeCompleter.complete(_dummyFrame());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await pump.dispose();
    });

    test('pause stops timer polling and resume restarts it cleanly', () async {
      int captures = 0;
      final pump = CameraFramePump(
        startImageStream: () async => throw UnimplementedError(),
        stopImageStream: () async {},
        captureStillBytes: () async {
          captures++;
          return Uint8List.fromList([1]);
        },
        decodeStillFrame: (_) async => _dummyFrame(),
        onDecodedFrame: (_) async {},
        pollInterval: const Duration(milliseconds: 20),
        forcePollingFallback: true,
      );

      await pump.start();
      await Future<void>.delayed(const Duration(milliseconds: 55));
      final beforePause = captures;
      expect(beforePause, greaterThanOrEqualTo(1));

      await pump.pause();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(captures, beforePause);

      await pump.resume();
      await Future<void>.delayed(const Duration(milliseconds: 55));
      expect(captures, greaterThan(beforePause));
      await pump.dispose();
    });
  });

  group('CameraFrameProcessor.extractPackedBgraBytes (TDD)', () {
    test('strips row padding when bytesPerRow exceeds width * 4', () {
      // 2x2 image -> width*4 = 8 bytes, padded to bytesPerRow = 12 bytes
      final src = Uint8List.fromList([
        // Row 0 pixels (8 bytes) + 4 padding bytes
        1, 2, 3, 255, 4, 5, 6, 255, 99, 99, 99, 99,
        // Row 1 pixels (8 bytes) + 4 padding bytes
        7, 8, 9, 255, 10, 11, 12, 255, 88, 88, 88, 88,
      ]);

      final packed = CameraFrameProcessor.extractPackedBgraBytes(
        planeBytes: src,
        width: 2,
        height: 2,
        bytesPerRow: 12,
      );

      expect(packed.length, 16);
      expect(packed, [
        1, 2, 3, 255, 4, 5, 6, 255,
        7, 8, 9, 255, 10, 11, 12, 255,
      ]);
    });
  });
}
