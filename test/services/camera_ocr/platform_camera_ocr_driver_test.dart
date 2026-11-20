import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pokevault/services/camera_ocr/platform_camera_ocr_driver.dart';
import 'package:pokevault/services/camera_ocr/platform_camera_ocr_driver_io.dart';
import 'package:pokevault/services/camera_ocr/platform_camera_ocr_driver_web.dart'
    hide createPlatformCameraOcrDriver;
import 'package:pokevault/services/desktop_tracker/desktop_capture_driver.dart';
import 'package:pokevault/services/desktop_tracker/desktop_ocr_driver.dart';
import 'package:pokevault/services/desktop_tracker/windows_desktop_bridge.dart';
import 'package:pokevault/services/mobile_scanner/mobile_ocr_driver.dart';
import 'package:pokevault/services/scanner_core/models/scanner_settings.dart';

class _MockDesktopBridge extends Mock implements DesktopPlatformBridge {}

class _FakeCapturedFrame extends Fake implements CapturedFrame {}

CapturedFrame _sampleBgraFrame({int width = 2, int height = 2}) {
  final bytes = Uint8List(width * height * 4);
  for (int i = 0; i < width * height; i++) {
    bytes[i * 4] = 10; // B
    bytes[i * 4 + 1] = 20; // G
    bytes[i * 4 + 2] = 30; // R
    bytes[i * 4 + 3] = 255; // A
  }
  return CapturedFrame(
    width: width,
    height: height,
    bytes: bytes,
    pixelFormat: 'bgra8888',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(_FakeCapturedFrame());
  });

  group('WindowsCameraOcrDriver (TDD)', () {
    late _MockDesktopBridge mockBridge;

    setUp(() {
      mockBridge = _MockDesktopBridge();
    });

    test('delegates frame, languageTag and preprocessProfile to DesktopPlatformBridge', () async {
      when(
        () => mockBridge.recognizeText(
          any(),
          languageTag: any(named: 'languageTag'),
          preprocessProfile: any(named: 'preprocessProfile'),
        ),
      ).thenAnswer(
        (_) async => const OcrRecognitionResult(
          lines: ['  Pikachu  ', '', 'Lv. 12'],
          ocrSucceeded: true,
        ),
      );

      final driver = WindowsCameraOcrDriver(
        bridge: mockBridge,
        initialLanguageTag: 'de-DE',
        initialPreprocessProfile: OcrPreprocessProfile.cameraDisplay,
      );

      expect(driver, isA<LanguageAwareOcrDriver>());
      expect(driver, isA<PreprocessAwareOcrDriver>());

      driver.setLanguageTag('ja-JP');
      driver.setPreprocessProfile(OcrPreprocessProfile.standard);

      final lines = await driver.recognizeText(_sampleBgraFrame());
      expect(lines, ['Pikachu', 'Lv. 12']);

      verify(
        () => mockBridge.recognizeText(
          any(),
          languageTag: 'ja-JP',
          preprocessProfile: 'standard',
        ),
      ).called(1);
    });

    test('skips bridge call on empty/zero-size frame and handles failed OCR gracefully', () async {
      final driver = WindowsCameraOcrDriver(bridge: mockBridge);
      final emptyResult = await driver.recognizeText(
        CapturedFrame(width: 0, height: 0, bytes: Uint8List(0)),
      );
      expect(emptyResult, isEmpty);
      verifyNever(() => mockBridge.recognizeText(any()));

      when(
        () => mockBridge.recognizeText(
          any(),
          languageTag: any(named: 'languageTag'),
          preprocessProfile: any(named: 'preprocessProfile'),
        ),
      ).thenAnswer(
        (_) async => const OcrRecognitionResult(
          ocrSucceeded: false,
          errorHint: 'No OCR language pack',
        ),
      );

      final failedResult = await driver.recognizeText(_sampleBgraFrame());
      expect(failedResult, isEmpty);
      expect(driver.lastDiagnosticHint, contains('No OCR language pack'));
    });
  });

  group('MacosVisionOcrDriver (TDD)', () {
    const channelName = 'pokevault/macos_vision_ocr_test';
    late List<MethodCall> recordedCalls;

    setUp(() {
      recordedCalls = [];
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel(channelName), null);
    });

    test('invokes Vision MethodChannel with frame bytes and parses lines', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel(channelName),
        (call) async {
          recordedCalls.add(call);
          return {
            'lines': ['Glumanda', '   ', 'Feuer'],
            'ocrSucceeded': true,
          };
        },
      );

      final driver = MacosVisionOcrDriver(
        channel: const MethodChannel(channelName),
        initialLanguageTag: 'de-DE',
      );
      driver.setPreprocessProfile(OcrPreprocessProfile.cameraDisplay);

      final lines = await driver.recognizeText(_sampleBgraFrame(width: 4, height: 3));
      expect(lines, ['Glumanda', 'Feuer']);
      expect(recordedCalls.single.method, 'recognizeText');
      final args = recordedCalls.single.arguments as Map;
      expect(args['width'], 4);
      expect(args['height'], 3);
      expect(args['languageTag'], 'de-DE');
      expect(args['preprocessProfile'], 'cameraDisplay');
      expect(args['pixelFormat'], 'bgra8888');
    });

    test('handles MissingPluginException and malformed responses without throwing', () async {
      final driver = MacosVisionOcrDriver(
        channel: const MethodChannel(channelName),
      );
      final lines = await driver.recognizeText(_sampleBgraFrame());
      expect(lines, isEmpty);
      expect(driver.lastDiagnosticHint, isNotNull);
    });
  });

  group('LinuxTesseractOcrDriver (TDD)', () {
    test('maps PokéVault/BCP-47 language tags to tesseract codes', () {
      expect(LinuxTesseractOcrDriver.mapLanguageToTesseract('de-DE'), 'deu');
      expect(LinuxTesseractOcrDriver.mapLanguageToTesseract('en-US'), 'eng');
      expect(LinuxTesseractOcrDriver.mapLanguageToTesseract('ja-JP'), 'jpn');
      expect(LinuxTesseractOcrDriver.mapLanguageToTesseract('ko-KR'), 'kor');
      expect(LinuxTesseractOcrDriver.mapLanguageToTesseract('zh-Hans'), 'chi_sim');
      expect(LinuxTesseractOcrDriver.mapLanguageToTesseract('zh-Hant'), 'chi_tra');
      expect(LinuxTesseractOcrDriver.mapLanguageToTesseract('fr'), 'fra');
      expect(LinuxTesseractOcrDriver.mapLanguageToTesseract(null), 'eng');
    });

    test('encodes BGRA frame as binary PPM (P6) and invokes tesseract CLI cleanly', () async {
      Uint8List? capturedStdin;
      List<String>? capturedArgs;
      String? capturedExe;

      final driver = LinuxTesseractOcrDriver(
        initialLanguageTag: 'de-DE',
        processRunner: (exe, args, {required Uint8List stdinBytes}) async {
          capturedExe = exe;
          capturedArgs = args;
          capturedStdin = stdinBytes;
          return const LinuxOcrProcessResult(
            exitCode: 0,
            stdout: 'Bisasam\n\nPflanze\n',
            stderr: '',
          );
        },
      );

      final lines = await driver.recognizeText(_sampleBgraFrame(width: 2, height: 1));
      expect(lines, ['Bisasam', 'Pflanze']);
      expect(capturedExe, 'tesseract');
      expect(capturedArgs, containsAll(['stdin', 'stdout', '-l', 'deu']));
      // P6 header: "P6\n2 1\n255\n" followed by 2 RGB pixels (30, 20, 10)
      expect(capturedStdin, isNotNull);
      final headerPrefix = String.fromCharCodes(capturedStdin!.take(11));
      expect(headerPrefix, 'P6\n2 1\n255\n');
      expect(capturedStdin!.sublist(11), [30, 20, 10, 30, 20, 10]);
    });

    test('reports helpful install hint when tesseract binary is unavailable', () async {
      final driver = LinuxTesseractOcrDriver(
        processRunner: (_, _, {required Uint8List stdinBytes}) async {
          throw const LinuxOcrExecutableMissingException('tesseract not found');
        },
      );

      final lines = await driver.recognizeText(_sampleBgraFrame());
      expect(lines, isEmpty);
      expect(driver.lastDiagnosticHint, contains('tesseract-ocr'));
    });
  });

  group('WebTesseractOcrDriver (TDD)', () {
    test('swaps BGRA8888 to RGBA8888 and delegates to web engine bridge', () async {
      Uint8List? receivedRgba;
      String? receivedLang;

      final driver = WebTesseractOcrDriver(
        initialLanguageTag: 'de-DE',
        delegate: _FakeWebTesseractDelegate(
          onRecognize: (rgba, w, h, lang) async {
            receivedRgba = rgba;
            receivedLang = lang;
            return const WebTesseractResult(
              lines: ['Schiggy', 'Wasser'],
              cacheSource: WebOcrCacheSource.localBundled,
            );
          },
        ),
      );

      final lines = await driver.recognizeText(_sampleBgraFrame(width: 1, height: 1));
      expect(lines, ['Schiggy', 'Wasser']);
      expect(receivedLang, 'deu');
      // Sample BGRA is [10, 20, 30, 255] -> RGBA [30, 20, 10, 255]
      expect(receivedRgba, [30, 20, 10, 255]);
      expect(driver.statusNotifier.value.cacheSource, WebOcrCacheSource.localBundled);
      expect(driver.statusNotifier.value.languageCode, 'deu');
    });

    test('updates status notifier for IndexedDB-cached extra languages', () async {
      final driver = WebTesseractOcrDriver(
        initialLanguageTag: 'ja-JP',
        delegate: _FakeWebTesseractDelegate(
          onRecognize: (_, _, _, lang) async {
            return const WebTesseractResult(
              lines: ['ピカチュウ'],
              cacheSource: WebOcrCacheSource.indexedDbCache,
            );
          },
        ),
      );

      final lines = await driver.recognizeText(_sampleBgraFrame(width: 1, height: 1));
      expect(lines, ['ピカチュウ']);
      expect(
        driver.statusNotifier.value.cacheSource,
        WebOcrCacheSource.indexedDbCache,
      );
      expect(driver.statusNotifier.value.languageCode, 'jpn');
    });
  });

  group('PlatformCameraOcrDriverFactory (TDD)', () {
    test('selects exact driver per target platform', () {
      expect(
        selectIoCameraOcrDriverForPlatform(TargetPlatform.android),
        isA<MobileOcrDriver>(),
      );
      expect(
        selectIoCameraOcrDriverForPlatform(TargetPlatform.iOS),
        isA<MobileOcrDriver>(),
      );
      expect(
        selectIoCameraOcrDriverForPlatform(
          TargetPlatform.windows,
          windowsBridge: _MockDesktopBridge(),
        ),
        isA<WindowsCameraOcrDriver>(),
      );
      expect(
        selectIoCameraOcrDriverForPlatform(TargetPlatform.macOS),
        isA<MacosVisionOcrDriver>(),
      );
      expect(
        selectIoCameraOcrDriverForPlatform(TargetPlatform.linux),
        isA<LinuxTesseractOcrDriver>(),
      );
    });

    test('MacosVisionOcrDriver propagates native errorHint when ocrSucceeded is false', () async {
      const ch = MethodChannel('pokevault/macos_vision_ocr_test');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(ch, (call) async {
        return {
          'lines': <String>[],
          'ocrSucceeded': false,
          'errorHint': 'Vision language pack unavailable',
        };
      });
      final driver = MacosVisionOcrDriver(channel: ch);
      final lines = await driver.recognizeText(_sampleBgraFrame(width: 2, height: 2));
      expect(lines, isEmpty);
      expect(driver.lastDiagnosticHint, 'Vision language pack unavailable');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(ch, null);
    });
  });
}

class _FakeWebTesseractDelegate implements WebTesseractDelegate {
  final Future<WebTesseractResult> Function(
    Uint8List rgbaBytes,
    int width,
    int height,
    String tesseractLang,
  ) onRecognize;

  _FakeWebTesseractDelegate({required this.onRecognize});

  @override
  Future<WebTesseractResult> recognizeRgba({
    required Uint8List rgbaBytes,
    required int width,
    required int height,
    required String tesseractLang,
  }) =>
      onRecognize(rgbaBytes, width, height, tesseractLang);

  @override
  Future<void> dispose() async {}
}
