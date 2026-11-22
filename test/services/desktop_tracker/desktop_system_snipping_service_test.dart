import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_io/io.dart' as io;
import 'package:pokevault/services/desktop_tracker/desktop_system_snipping_service.dart';

void main() {
  group('DesktopSystemSnippingService Tests (TDD)', () {
    test('triggerWindowsScreenclip runs ms-screenclip: process successfully', () async {
      String? executedCommand;
      List<String>? executedArgs;

      final service = DesktopSystemSnippingService(
        processRunner: (cmd, args) async {
          executedCommand = cmd;
          executedArgs = args;
          return io.ProcessResult(0, 0, 'OK', '');
        },
      );

      final success = await service.triggerWindowsScreenclip();
      expect(success, isTrue);
      expect(executedCommand, anyOf('cmd', 'explorer.exe', 'powershell'));
      expect(executedArgs?.join(' '), contains('ms-screenclip:'));
    });

    test('getClipboardImageBytes returns Uint8List when valid image exists in clipboard', () async {
      final samplePngBytes = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13]);

      final service = DesktopSystemSnippingService(
        clipboardBytesProvider: () async => samplePngBytes,
      );

      final bytes = await service.getClipboardImageBytes();
      expect(bytes, isNotNull);
      expect(bytes!.length, samplePngBytes.length);
    });

    test('getClipboardImageBytes returns null when clipboard is empty or has non-image content', () async {
      final service = DesktopSystemSnippingService(
        clipboardBytesProvider: () async => null,
      );

      final bytes = await service.getClipboardImageBytes();
      expect(bytes, isNull);
    });

    test('captureDesktopSnippet converts clipboard bytes to CapturedFrame', () async {
      final samplePngBytes = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]);

      final service = DesktopSystemSnippingService(
        clipboardBytesProvider: () async => samplePngBytes,
        dimensionDecoder: (bytes) async => (width: 400, height: 250),
      );

      final frame = await service.captureDesktopSnippet();
      expect(frame, isNotNull);
      expect(frame!.width, 400);
      expect(frame.height, 250);
      expect(frame.bytes, samplePngBytes);
    });

    test('captureDesktopSnippet returns null when decoding dimensions fails or bytes are null', () async {
      final service = DesktopSystemSnippingService(
        clipboardBytesProvider: () async => null,
      );

      final frame = await service.captureDesktopSnippet();
      expect(frame, isNull);
    });

    test('Adversarial: ProcessRunner throwing exception fails gracefully without crashing', () async {
      final service = DesktopSystemSnippingService(
        processRunner: (cmd, args) async {
          throw io.ProcessException(cmd, args, 'System blocked command');
        },
        clipboardBytesProvider: () async {
          throw Exception('Clipboard locked by another process');
        },
      );

      final clipSuccess = await service.triggerWindowsScreenclip();
      expect(clipSuccess, isFalse);

      final bytes = await service.getClipboardImageBytes();
      expect(bytes, isNull);

      final frame = await service.captureDesktopSnippet();
      expect(frame, isNull);
    });
  });
}
