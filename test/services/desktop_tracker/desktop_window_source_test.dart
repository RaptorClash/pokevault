import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/services/desktop_tracker/desktop_capture_driver.dart';
import 'package:pokevault/services/desktop_tracker/desktop_ocr_driver.dart';
import 'package:pokevault/services/desktop_tracker/desktop_window_source.dart';
import 'package:pokevault/services/desktop_tracker/screen_region.dart';
import 'package:pokevault/services/desktop_tracker/window_detector.dart';
import 'package:pokevault/services/scanner_core/models/scanner_settings.dart';
import 'package:pokevault/services/scanner_core/source/scanner_source.dart';

class MockCaptureDriver implements DesktopCaptureDriver {
  int captureCount = 0;
  Rect? lastCrop;
  ScreenRegion? lastScreenRegion;
  DesktopWindowInfo? lastWindow;

  @override
  Future<CapturedFrame?> captureWindow({
    required DesktopWindowInfo window,
    Rect? cropRegion,
    ScreenRegion? screenRegion,
  }) async {
    captureCount++;
    lastWindow = window;
    lastCrop = cropRegion;
    lastScreenRegion = screenRegion;
    return CapturedFrame(
      width: 800,
      height: 600,
      bytes: [1, captureCount & 0xFF, 3],
    );
  }
}

class MockOcrDriver implements DesktopOcrDriver {
  String textToReturn = 'Glumanda wurde gefangen!';
  List<String>? linesToReturn;
  int ocrCount = 0;

  @override
  Future<List<String>> recognizeText(CapturedFrame frame) async {
    ocrCount++;
    if (linesToReturn != null) return List<String>.from(linesToReturn!);
    if (textToReturn.isEmpty) return [];
    return [textToReturn];
  }
}

void main() {
  group('DesktopWindowSource Tests (TDD)', () {
    late MockCaptureDriver captureDriver;
    late MockOcrDriver ocrDriver;
    late DesktopWindowSource source;

    setUp(() {
      captureDriver = MockCaptureDriver();
      ocrDriver = MockOcrDriver();
      source = DesktopWindowSource(
        captureDriver: captureDriver,
        ocrDriver: ocrDriver,
        pollInterval: const Duration(milliseconds: 50),
      );
    });

    tearDown(() async {
      await source.dispose();
    });

    test('Initial state is stopped with no text emitted', () {
      expect(source.isRunning, isFalse);
    });

    test('Periodically captures selected window and streams OCR text', () async {
      const window = DesktopWindowInfo(id: 123, title: 'mGBA - Pokemon');
      source.setSelectedWindow(window);
      source.setCropRegion(const Rect.fromLTWH(0, 400, 800, 200));

      final emitted = <String>[];
      final sub = source.textStream.listen(emitted.add);

      await source.start();
      expect(source.isRunning, isTrue);

      // Wait for at least 2 ticks
      await Future.delayed(const Duration(milliseconds: 140));

      expect(emitted, contains('Glumanda wurde gefangen!'));
      expect(captureDriver.captureCount, greaterThanOrEqualTo(2));
      expect(captureDriver.lastWindow?.id, 123);
      expect(captureDriver.lastCrop?.top, 400);
      expect(ocrDriver.ocrCount, greaterThanOrEqualTo(2));

      await source.stop();
      expect(source.isRunning, isFalse);
      await sub.cancel();
    });

    test('Does not capture if no window is selected', () async {
      source.setSelectedWindow(null);
      await source.start();

      await Future.delayed(const Duration(milliseconds: 80));
      expect(captureDriver.captureCount, 0);

      await source.stop();
    });

    test('triggerSingleScan executes immediate poll and emits recognized text on demand', () async {
      final desktop = DesktopWindowInfo.primaryScreen();
      source.setSelectedWindow(desktop);

      final emitted = <String>[];
      final sub = source.textStream.listen(emitted.add);

      final frame = await source.triggerSingleScan();
      await Future.delayed(Duration.zero);

      expect(frame, isNotNull);
      expect(captureDriver.captureCount, 1);
      expect(captureDriver.lastWindow?.isDesktopScreen, isTrue);
      expect(ocrDriver.ocrCount, 1);
      expect(emitted, contains('Glumanda wurde gefangen!'));

      await sub.cancel();
    });

    test('processSnippet feeds snippet frame directly into OCR and emits text stream', () async {
      const snippet = CapturedFrame(width: 400, height: 200, bytes: [9, 8, 7]);
      ocrDriver.textToReturn = 'Ein wildes Pikachu erscheint!';

      final emitted = <String>[];
      final sub = source.textStream.listen(emitted.add);

      final lines = await source.processSnippet(snippet);
      await Future.delayed(Duration.zero);

      expect(lines, contains('Ein wildes Pikachu erscheint!'));
      expect(emitted, contains('Ein wildes Pikachu erscheint!'));
      expect(source.latestSnippetFrame, equals(snippet));

      await sub.cancel();
    });

    test('Updates liveScanStatusNotifier on every scan cycle with scan count, latestFrame, and recognized OCR preview', () async {
      source.setScreenRegion(
        ScreenRegion(
          x: 100,
          y: 200,
          width: 400,
          height: 150,
          isAbsoluteScreen: true,
        ),
      );
      ocrDriver.textToReturn = 'Route 1 · Kampfbereit';

      await source.triggerSingleScan();
      expect(source.liveScanStatusNotifier.value.scanCount, 1);
      expect(source.liveScanStatusNotifier.value.lastScanAt, isNotNull);
      expect(source.liveScanStatusNotifier.value.recognizedLines, ['Route 1 · Kampfbereit']);
      expect(source.liveScanStatusNotifier.value.latestFrame, isNotNull);

      ocrDriver.textToReturn = '';
      await source.triggerSingleScan();
      expect(source.liveScanStatusNotifier.value.scanCount, 2);
      expect(source.liveScanStatusNotifier.value.recognizedLines, isEmpty);
    });

    test('Records temporary diagnostic OCR logs on scanLogsNotifier and formats copyable output', () async {
      const window = DesktopWindowInfo(id: 77, hwnd: 1234, title: 'melonDS 1.1', width: 960, height: 1040);
      source.setSelectedWindow(window);
      source.setOcrLanguageTag('de-DE');
      ocrDriver.textToReturn = 'Ein wildes Glumanda!';

      await source.triggerSingleScan();

      final logs = source.scanLogsNotifier.value;
      expect(logs, hasLength(1));
      expect(logs.first.scanNumber, 1);
      expect(logs.first.sourceMode, 'window');
      expect(logs.first.targetDescription, contains('melonDS 1.1'));
      expect(logs.first.frameWidth, 800);
      expect(logs.first.frameHeight, 600);
      expect(logs.first.requestedLanguage, 'de-DE');
      expect(logs.first.rawLines, ['Ein wildes Glumanda!']);

      final formatted = logs.first.toFormattedText();
      expect(formatted, contains('#1'));
      expect(formatted, contains('melonDS 1.1'));
      expect(formatted, contains('800x600'));
      expect(formatted, contains('Ein wildes Glumanda!'));

      source.clearScanLogs();
      expect(source.scanLogsNotifier.value, isEmpty);
    });

    test('setPollInterval updates interval dynamically and clamps unsafe low values', () {
      expect(source.pollInterval, const Duration(milliseconds: 50));
      source.setPollInterval(const Duration(milliseconds: 250));
      expect(source.pollInterval, const Duration(milliseconds: 250));

      source.setPollInterval(const Duration(milliseconds: 20));
      expect(source.pollInterval, const Duration(milliseconds: 150));

      source.setPollInterval(const Duration(seconds: 9));
      expect(source.pollInterval, const Duration(milliseconds: 5000));
    });

    test('Emits combined multi-line OCR text stream when multiple valid lines exist', () async {
      const window = DesktopWindowInfo(id: 77, hwnd: 1234, title: 'melonDS 1.1', width: 960, height: 1040);
      source.setSelectedWindow(window);
      ocrDriver.linesToReturn = ['Klase!', 'Flampion wurde gefangen!'];

      final emitted = <String>[];
      final sub = source.textStream.listen(emitted.add);

      await source.triggerSingleScan();
      await Future.delayed(Duration.zero);

      expect(emitted, contains('Klase!'));
      expect(emitted, contains('Flampion wurde gefangen!'));
      expect(emitted, contains('Klase!\nFlampion wurde gefangen!'));

      await sub.cancel();
    });

    test('capturePreviewOnly captures monitor preview frame without incrementing scanCount or calling OCR', () async {
      final monitor = DesktopWindowInfo.primaryScreen();
      source.setSelectedWindow(monitor);

      final frame = await source.capturePreviewOnly();
      expect(frame, isNotNull);
      expect(captureDriver.captureCount, 1);
      expect(ocrDriver.ocrCount, 0);
      expect(source.liveScanStatusNotifier.value.scanCount, 0);
      expect(source.liveScanStatusNotifier.value.latestFrame, equals(frame));
      expect(source.scanLogsNotifier.value, isEmpty);
    });

    test('Dual-Zone captures Zone B enemy HUD on focusTextStream when LiveFocusPreset is active', () async {
      const window = DesktopWindowInfo(id: 77, hwnd: 1234, title: 'melonDS 1.1', width: 1000, height: 1000);
      source.setSelectedWindow(window);
      source.setLiveFocusPreset(LiveFocusPreset.topRight);

      final capturedCrops = <Rect?>[];
      final multiCapture = _SequenceCaptureDriver(onCapture: (crop, region) {
        capturedCrops.add(crop);
      });
      final multiOcr = _AlternatingOcrDriver(['', 'Zurrokex Lv.16   Ganovil Lv.17']);
      final dualSource = DesktopWindowSource(
        captureDriver: multiCapture,
        ocrDriver: multiOcr,
        pollInterval: const Duration(milliseconds: 50),
      );
      addTearDown(() async => await dualSource.dispose());

      dualSource.setSelectedWindow(window);
      dualSource.setLiveFocusPreset(LiveFocusPreset.topRight);

      final zoneBTexts = <String>[];
      final sub = dualSource.focusTextStream.listen(zoneBTexts.add);
      addTearDown(() async => await sub.cancel());

      await dualSource.triggerSingleScan();
      await Future.delayed(Duration.zero);

      expect(capturedCrops.length, 2);
      expect(capturedCrops[1], isNotNull);
      expect(capturedCrops[1]!.left, closeTo(580.0, 0.01));
      expect(zoneBTexts, contains('Zurrokex Lv.16   Ganovil Lv.17'));
    });

    test('Frame pixel-diff fingerprint skips OCR on unchanged static frames and resumes on pixel change', () async {
      const window = DesktopWindowInfo(id: 77, hwnd: 1234, title: 'melonDS 1.1', width: 800, height: 600);
      final countingCapture = _SequenceFrameCaptureDriver([
        CapturedFrame(width: 40, height: 40, bytes: List<int>.filled(40 * 40 * 4, 120)),
        CapturedFrame(width: 40, height: 40, bytes: List<int>.filled(40 * 40 * 4, 120)),
        CapturedFrame(width: 40, height: 40, bytes: List<int>.filled(40 * 40 * 4, 120)),
        CapturedFrame(width: 40, height: 40, bytes: List<int>.filled(40 * 40 * 4, 240)),
      ]);
      final countingOcr = _CountingOcrDriver(['Ein wildes Flampion erscheint!']);
      final fastSource = DesktopWindowSource(
        captureDriver: countingCapture,
        ocrDriver: countingOcr,
        pollInterval: const Duration(milliseconds: 50),
      );
      addTearDown(() async => await fastSource.dispose());

      fastSource.setSelectedWindow(window);
      await fastSource.triggerSingleScan();
      await fastSource.triggerSingleScan();
      await fastSource.triggerSingleScan();
      // Only 1 OCR run for 3 identical frames
      expect(countingCapture.captureCount, 3);
      expect(countingOcr.ocrCount, 1);

      // 4th frame has different pixel content -> triggers OCR again
      await fastSource.triggerSingleScan();
      expect(countingCapture.captureCount, 4);
      expect(countingOcr.ocrCount, 2);
    });

    test('Multi-instance slots scan independently and emit tagged slot batches on multiInstanceFocusStream', () async {
      const window = DesktopWindowInfo(id: 88, hwnd: 5555, title: 'Desktop', width: 1920, height: 1080);
      final slotCapture = _RegionAwareCaptureDriver({
        10.0: CapturedFrame(width: 20, height: 20, bytes: List<int>.filled(20 * 20 * 4, 50)),
        510.0: CapturedFrame(width: 20, height: 20, bytes: List<int>.filled(20 * 20 * 4, 90)),
      });
      final slotOcr = _AlternatingOcrDriver(['', 'Flampion Lv.15', 'Ganovil Lv.17']);
      final multiSource = DesktopWindowSource(
        captureDriver: slotCapture,
        ocrDriver: slotOcr,
        pollInterval: const Duration(milliseconds: 50),
      );
      addTearDown(() async => await multiSource.dispose());

      multiSource.setSelectedWindow(window);
      multiSource.setMultiInstanceSlots([
        MultiInstanceSlot(
          id: 1,
          label: '#1',
          region: ScreenRegion(x: 10, y: 10, width: 200, height: 100, isAbsoluteScreen: true),
          colorHex: 0xFFA855F7,
        ),
        MultiInstanceSlot(
          id: 2,
          label: '#2',
          region: ScreenRegion(x: 510, y: 10, width: 200, height: 100, isAbsoluteScreen: true),
          colorHex: 0xFFEC4899,
        ),
      ]);

      final emitted = <MultiInstanceTextEmission>[];
      final sub = multiSource.multiInstanceTextStream.listen(emitted.add);
      addTearDown(() async => await sub.cancel());

      await multiSource.triggerSingleScan();
      await Future.delayed(Duration.zero);

      expect(emitted.where((e) => e.slotId == 1).map((e) => e.rawText), contains('Flampion Lv.15'));
      expect(emitted.where((e) => e.slotId == 2).map((e) => e.rawText), contains('Ganovil Lv.17'));
    });

    test('Coupled MultiInstanceSlot scans both scanRegion (encounterOnly=false) and focusRegion (encounterOnly=true) + resolves window presets', () async {
      const win2 = DesktopWindowInfo(
        id: 202,
        hwnd: 2002,
        title: 'melonDS #2',
        width: 800,
        height: 600,
        bounds: Rect.fromLTWH(500, 0, 800, 600),
      );
      final captureDriver = _RegionAwareCaptureDriver({
        10.0: CapturedFrame(width: 20, height: 20, bytes: List<int>.filled(20 * 20 * 4, 41)),
        20.0: CapturedFrame(width: 20, height: 20, bytes: List<int>.filled(20 * 20 * 4, 82)),
        500.0: CapturedFrame(width: 20, height: 20, bytes: List<int>.filled(20 * 20 * 4, 99)),
      });
      final ocrDriver = _AlternatingOcrDriver([
        '',
        'Flampion wurde gefangen!',
        'Zurrokex Lv.16',
        'Ganovil erscheint!',
      ]);
      final src = DesktopWindowSource(
        captureDriver: captureDriver,
        ocrDriver: ocrDriver,
        pollInterval: const Duration(milliseconds: 50),
      );
      addTearDown(() async => await src.dispose());

      src.setSelectedWindow(const DesktopWindowInfo(id: 1, title: 'Desktop', isDesktopScreen: true));
      src.updateKnownWindows([win2]);
      src.setMultiInstanceSlots([
        MultiInstanceSlot(
          id: 2,
          label: '#2',
          colorHex: 0xFFA855F7,
          scanEnabled: true,
          scanRegion: ScreenRegion(x: 10, y: 10, width: 300, height: 100, isAbsoluteScreen: true),
          focusPreset: LiveFocusPreset.customRegion,
          focusRegion: ScreenRegion(x: 20, y: 20, width: 200, height: 60, isAbsoluteScreen: true),
        ),
        const MultiInstanceSlot(
          id: 3,
          label: '#3',
          colorHex: 0xFFEC4899,
          windowHwnd: 2002,
          windowId: 202,
          windowTitle: 'melonDS #2',
          scanPreset: ScanRegionPreset.fullWindow,
          focusPreset: LiveFocusPreset.disabled,
          scanEnabled: true,
        ),
      ]);

      final emissions = <MultiInstanceTextEmission>[];
      final sub = src.multiInstanceTextStream.listen(emissions.add);
      addTearDown(() async => await sub.cancel());

      await src.triggerSingleScan();
      await Future.delayed(Duration.zero);

      expect(
        emissions.any((e) => e.slotId == 2 && !e.encounterOnly && e.rawText.contains('Flampion')),
        isTrue,
      );
      expect(
        emissions.any((e) => e.slotId == 2 && e.encounterOnly && e.rawText.contains('Zurrokex')),
        isTrue,
      );
      expect(
        emissions.any((e) => e.slotId == 3 && !e.encounterOnly && e.rawText.contains('Ganovil')),
        isTrue,
      );
    });
  });
}

class _SequenceFrameCaptureDriver implements DesktopCaptureDriver {
  final List<CapturedFrame> frames;
  int captureCount = 0;
  _SequenceFrameCaptureDriver(this.frames);

  @override
  Future<CapturedFrame?> captureWindow({
    required DesktopWindowInfo window,
    Rect? cropRegion,
    ScreenRegion? screenRegion,
  }) async {
    final f = frames[captureCount % frames.length];
    captureCount++;
    return f;
  }
}

class _RegionAwareCaptureDriver implements DesktopCaptureDriver {
  final Map<double, CapturedFrame> framesByX;
  _RegionAwareCaptureDriver(this.framesByX);

  @override
  Future<CapturedFrame?> captureWindow({
    required DesktopWindowInfo window,
    Rect? cropRegion,
    ScreenRegion? screenRegion,
  }) async {
    if (screenRegion != null && framesByX.containsKey(screenRegion.x)) {
      return framesByX[screenRegion.x];
    }
    if (window.bounds != null && framesByX.containsKey(window.bounds!.left)) {
      return framesByX[window.bounds!.left];
    }
    return CapturedFrame(width: 20, height: 20, bytes: List<int>.filled(20 * 20 * 4, 1));
  }
}

class _CountingOcrDriver implements DesktopOcrDriver {
  final List<String> lines;
  int ocrCount = 0;
  _CountingOcrDriver(this.lines);

  @override
  Future<List<String>> recognizeText(CapturedFrame frame) async {
    ocrCount++;
    return lines;
  }
}

class _SequenceCaptureDriver implements DesktopCaptureDriver {
  final void Function(Rect? crop, ScreenRegion? region) onCapture;
  _SequenceCaptureDriver({required this.onCapture});

  @override
  Future<CapturedFrame?> captureWindow({
    required DesktopWindowInfo window,
    Rect? cropRegion,
    ScreenRegion? screenRegion,
  }) async {
    onCapture(cropRegion, screenRegion);
    return const CapturedFrame(width: 420, height: 220, bytes: [1, 2, 3]);
  }
}

class _AlternatingOcrDriver implements DesktopOcrDriver {
  final List<String> responses;
  int _idx = 0;
  _AlternatingOcrDriver(this.responses);

  @override
  Future<List<String>> recognizeText(CapturedFrame frame) async {
    final text = responses[_idx % responses.length];
    _idx++;
    return text.isEmpty ? [] : [text];
  }
}
