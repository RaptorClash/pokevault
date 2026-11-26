import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/services/desktop_tracker/desktop_capture_driver.dart';
import 'package:pokevault/services/desktop_tracker/desktop_ocr_driver.dart';
import 'package:pokevault/services/desktop_tracker/desktop_window_source.dart';
import 'package:pokevault/services/desktop_tracker/screen_region.dart';
import 'package:pokevault/services/desktop_tracker/window_detector.dart';
import 'package:pokevault/services/desktop_tracker/windows_desktop_bridge.dart';
import 'package:pokevault/services/scanner_core/media/frame_transition_detector.dart';
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

    test('Zone B triggers multi-band OCR fallback when full frame yields fewer than 2 lines and merges extraFocusRegions', () async {
      const w = 160;
      const h = 100;
      final zoneBBytes = List<int>.filled(w * h * 4, 255);
      // Distinct top (y<40 -> 30), middle (40..59 -> 100), bottom (y>=60 -> 200)
      for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
          final off = (y * w + x) * 4;
          zoneBBytes[off] = y < 40 ? 30 : (y >= 60 ? 200 : 100);
        }
      }
      final fullZoneBFrame = CapturedFrame(
        width: w,
        height: h,
        bytes: zoneBBytes,
        pixelFormat: 'bgra8888',
      );
      final extraBoxFrame = CapturedFrame(
        width: 120,
        height: 40,
        bytes: List<int>.filled(120 * 40 * 4, 88),
        pixelFormat: 'bgra8888',
      );

      final region1 = ScreenRegion(
        x: 50,
        y: 50,
        width: 160,
        height: 100,
        isAbsoluteScreen: true,
        label: 'Fokus B1',
      );
      final region2 = ScreenRegion(
        x: 300,
        y: 50,
        width: 120,
        height: 40,
        isAbsoluteScreen: true,
        label: 'Fokus B2',
      );

      final cap = _RegionAwareCaptureDriver({
        50: fullZoneBFrame,
        300: extraBoxFrame,
      });
      final bandOcr = _BandSensitiveOcrDriver(
        extraBoxWidth: 120,
        fullFrameLines: const ['Sleima ♀ Lv.17'],
        topBandLines: const ['Sleima ♀ Lv.17'],
        bottomBandLines: const ['Zubat ♂ Lv.15'],
        extraBoxLines: const ['Flampion ♂ Lv.18'],
      );
      final multiBandSource = DesktopWindowSource(
        captureDriver: cap,
        ocrDriver: bandOcr,
        pollInterval: const Duration(milliseconds: 50),
      );
      addTearDown(() async => await multiBandSource.dispose());

      multiBandSource.setSelectedWindow(
        const DesktopWindowInfo(id: 77, hwnd: 1234, title: 'melonDS 1.1', width: 960, height: 1040),
      );
      multiBandSource.setLiveFocusScreenRegion(region1);
      multiBandSource.setExtraFocusRegions([region2]);

      final focusTexts = <String>[];
      final sub = multiBandSource.focusTextStream.listen(focusTexts.add);
      addTearDown(() async => await sub.cancel());

      await multiBandSource.triggerSingleScan();
      await Future.delayed(Duration.zero);

      expect(focusTexts, isNotEmpty);
      expect(focusTexts.last, contains('Sleima ♀ Lv.17'));
      expect(focusTexts.last, contains('Zubat ♂ Lv.15'));
      expect(focusTexts.last, contains('Flampion ♂ Lv.18'));
      expect(multiBandSource.focusBoxPreviewLines['B1'], contains('Zubat'));
      expect(multiBandSource.focusBoxPreviewLines['B2'], contains('Flampion'));
    });

    test('computeFrameFingerprint detects small localized pixel changes inside BGRA8888 Zone B frames', () {
      const w = 240;
      const h = 60;
      final baseBytes = List<int>.filled(w * h * 4, 24);
      final mutatedBytes = List<int>.from(baseBytes);
      // Modify a small 10x4 HUD text patch inside the frame
      for (int y = 24; y < 28; y++) {
        for (int x = 100; x < 110; x++) {
          final off = (y * w + x) * 4;
          mutatedBytes[off] = 240;
          mutatedBytes[off + 1] = 240;
          mutatedBytes[off + 2] = 240;
          mutatedBytes[off + 3] = 255;
        }
      }

      final f1 = CapturedFrame(
        width: w,
        height: h,
        bytes: baseBytes,
        pixelFormat: 'bgra8888',
      );
      final f2 = CapturedFrame(
        width: w,
        height: h,
        bytes: mutatedBytes,
        pixelFormat: 'bgra8888',
      );

      expect(computeFrameFingerprint(f1), isNot(equals(computeFrameFingerprint(f2))));
    });

    test('Zone B triggers luminance inversion when raw OCR returns only fragmented shadow-noise lines', () async {
      const w = 160;
      const h = 48;
      // Dark background (18) so inverted pixels become bright (237)
      final rawBytes = List<int>.filled(w * h * 4, 18);
      for (int off = 3; off < rawBytes.length; off += 4) {
        rawBytes[off] = 255;
      }
      final rawFrame = CapturedFrame(
        width: w,
        height: h,
        bytes: rawBytes,
        pixelFormat: 'bgra8888',
      );

      final noiseCap = _RegionAwareCaptureDriver({50: rawFrame});
      final invOcr = _InversionAwareOcrDriver();
      final src = DesktopWindowSource(
        captureDriver: noiseCap,
        ocrDriver: invOcr,
        pollInterval: const Duration(milliseconds: 50),
      );
      addTearDown(src.dispose);

      src.setLiveFocusScreenRegion(
        ScreenRegion(
          x: 50,
          y: 50,
          width: 160,
          height: 48,
          isAbsoluteScreen: true,
          label: 'Fokus B1',
        ),
      );

      final focusTexts = <String>[];
      final sub = src.focusTextStream.listen(focusTexts.add);
      addTearDown(sub.cancel);

      // Should even work via fallback DesktopWindowInfo.primaryScreen() when _selectedWindow is null
      await src.triggerSingleScan();
      await Future<void>.delayed(Duration.zero);

      expect(invOcr.sawInvertedFrame, isTrue);
      expect(focusTexts, isNotEmpty);
      expect(focusTexts.last, contains('Folikon Lv.22'));
      expect(src.liveFocusStatusNotifier.value.recognizedLines, contains('Folikon Lv.22'));
    });

    test('focusBoxFramesNotifier tracks latest CapturedFrame for B1 and B2 and resets cleanly', () async {
      final frameB1 = CapturedFrame(
        width: 80,
        height: 40,
        bytes: List<int>.filled(80 * 40 * 4, 42),
        pixelFormat: 'bgra8888',
      );
      final frameB2 = CapturedFrame(
        width: 90,
        height: 40,
        bytes: List<int>.filled(90 * 40 * 4, 84),
        pixelFormat: 'bgra8888',
      );

      final boxCap = _RegionAwareCaptureDriver({50: frameB1, 300: frameB2});
      final src = DesktopWindowSource(
        captureDriver: boxCap,
        ocrDriver: _CountingOcrDriver(const ['Pikachu Lv.7', 'Flampion Lv.15']),
        pollInterval: const Duration(milliseconds: 50),
      );
      addTearDown(src.dispose);

      src.setLiveFocusScreenRegion(
        ScreenRegion(x: 50, y: 50, width: 80, height: 40, isAbsoluteScreen: true),
      );
      src.setExtraFocusRegions([
        ScreenRegion(x: 300, y: 50, width: 90, height: 40, isAbsoluteScreen: true),
      ]);

      await src.triggerSingleScan();

      expect(src.focusBoxFramesNotifier.value['B1'], equals(frameB1));
      expect(src.focusBoxFramesNotifier.value['B2'], equals(frameB2));

      src.setLiveFocusPreset(LiveFocusPreset.disabled);
      expect(src.focusBoxFramesNotifier.value.containsKey('B1'), isFalse);
      expect(src.liveFocusStatusNotifier.value.scanCount, 0);
      expect(src.liveFocusStatusNotifier.value.latestFrame, isNull);
    });

    test('nativeBridge.captureAndAnalyze fast-path skips legacy drivers, throttles thumbnails to ~1Hz, and forwards Luma/HSV/SelfOverlap', () async {
      var clock = Duration.zero;
      final legacyCap = _CountingOnlyCaptureDriver();
      final legacyOcr = _CountingOcrDriver(const ['Legacy']);
      final nativeBridge = _FastPathBridge();

      final src = DesktopWindowSource(
        captureDriver: legacyCap,
        ocrDriver: legacyOcr,
        nativeBridge: nativeBridge,
        elapsedClock: () => clock,
      );
      addTearDown(src.dispose);

      src.setSelectedWindow(
        const DesktopWindowInfo(
          id: 1,
          hwnd: 999,
          title: 'Monitor 1',
          width: 1920,
          height: 1080,
          isDesktopScreen: true,
        ),
      );
      src.setScreenRegion(
        ScreenRegion(
          x: 0,
          y: 0,
          width: 1920,
          height: 1080,
          isAbsoluteScreen: true,
        ),
      );
      src.setPreviewPolicy(enabled: true, maxWidth: 320);

      final texts = <String>[];
      final transitions = <FrameTransitionEvent>[];
      final visuals = <SlotVisualFrame>[];
      final tSub = src.textStream.listen(texts.add);
      final trSub = src.transitionStream.listen(transitions.add);
      final vSub = src.visualFrameStream.listen(visuals.add);
      addTearDown(() async {
        await tSub.cancel();
        await trSub.cancel();
        await vSub.cancel();
      });

      // Tick 1: should include thumbnail (first request), computeColorHistogram == true, maskSelfWindow == false
      nativeBridge.nextResult = const NativeCaptureAnalyzeResult(
        captured: true,
        ocrSkipped: false,
        lines: ['Ein wildes Pikachu erscheint!'],
        frameWidth: 1920,
        frameHeight: 1080,
        captureMethod: 'bitblt_screen',
        brightnessSummary: 'luma=10..220 avg=120 nonBlack=95%',
        avgLuma: 120.0,
        stdDev: 5.0,
        colorHistogram: [0.1, 0.2, 0.3, 0.4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        selfWindowOverlaps: true,
        thumbnailFrame: CapturedFrame(
          width: 320,
          height: 180,
          bytes: [137, 80, 78, 71],
          pixelFormat: 'png',
        ),
      );

      await src.triggerSingleScan();
      await Future<void>.delayed(Duration.zero);

      expect(legacyCap.captureCount, 0);
      expect(legacyOcr.ocrCount, 0);
      expect(nativeBridge.requests, hasLength(1));
      expect(nativeBridge.requests.last.includeThumbnail, isTrue);
      expect(nativeBridge.requests.last.thumbnailMaxWidth, 320);
      expect(nativeBridge.requests.last.computeColorHistogram, isTrue);
      expect(nativeBridge.requests.last.maskSelfWindow, isFalse);
      expect(src.selfWindowOverlapNotifier.value, isTrue);
      expect(texts, contains('Ein wildes Pikachu erscheint!'));
      expect(visuals, hasLength(1));
      expect(visuals.first.precomputedHistogram, hasLength(16));

      // Tick 2 at +400ms: thumbnail throttled (<1000ms), static frame skipped OCR, black transition entered
      clock += const Duration(milliseconds: 400);
      nativeBridge.nextResult = const NativeCaptureAnalyzeResult(
        captured: true,
        ocrSkipped: true,
        frameWidth: 1920,
        frameHeight: 1080,
        captureMethod: 'bitblt_screen',
        avgLuma: 2.0,
        stdDev: 0.0,
        selfWindowOverlaps: true,
      );
      await src.triggerSingleScan();
      expect(nativeBridge.requests.last.includeThumbnail, isFalse);

      // Tick 2b at +700ms: second consecutive black sample confirms transition duration
      clock += const Duration(milliseconds: 300);
      await src.triggerSingleScan();

      // Tick 3 at +1100ms: thumbnail allowed again (>=1000ms), transition back to normal -> blackScreenEnded!
      clock += const Duration(milliseconds: 400);
      src.setMaskSelfWindow(true);
      nativeBridge.nextResult = const NativeCaptureAnalyzeResult(
        captured: true,
        ocrSkipped: false,
        lines: ['Pikachu'],
        frameWidth: 1920,
        frameHeight: 1080,
        captureMethod: 'bitblt_screen',
        avgLuma: 120.0,
        stdDev: 5.0,
        selfWindowOverlaps: false,
      );
      await src.triggerSingleScan();
      await Future<void>.delayed(Duration.zero);
      expect(nativeBridge.requests.last.includeThumbnail, isTrue);
      expect(nativeBridge.requests.last.maskSelfWindow, isTrue);
      expect(transitions, hasLength(1));
      expect(transitions.first.type, FrameTransitionType.blackScreenEnded);

      // Background mode (preview disabled): 0 thumbnail requests even after 5 seconds
      clock += const Duration(seconds: 5);
      src.setPreviewPolicy(enabled: false);
      await src.triggerSingleScan();
      expect(nativeBridge.requests.last.includeThumbnail, isFalse);
    });

    test('Multi-instance slots use nativeBridge.captureAndAnalyze when nativeBridge is configured', () async {
      final legacyCap = _CountingOnlyCaptureDriver();
      final legacyOcr = _CountingOcrDriver(const []);
      final nativeBridge = _FastPathBridge();

      final src = DesktopWindowSource(
        captureDriver: legacyCap,
        ocrDriver: legacyOcr,
        nativeBridge: nativeBridge,
      );
      addTearDown(src.dispose);

      src.setMultiInstanceSlots([
        MultiInstanceSlot(
          id: 2,
          label: '#2',
          colorHex: 0xFFA855F7,
          scanEnabled: true,
          scanRegion: ScreenRegion(
            x: 100,
            y: 200,
            width: 300,
            height: 100,
            isAbsoluteScreen: true,
          ),
        ),
      ]);

      final multiEmissions = <MultiInstanceTextEmission>[];
      final sub = src.multiInstanceTextStream.listen(multiEmissions.add);
      addTearDown(sub.cancel);

      nativeBridge.nextResult = const NativeCaptureAnalyzeResult(
        captured: true,
        ocrSkipped: false,
        lines: ['Ein wildes Zorua erscheint!'],
        frameWidth: 300,
        frameHeight: 100,
      );

      await src.triggerSingleScan();
      await Future<void>.delayed(Duration.zero);

      expect(legacyCap.captureCount, 0);
      expect(legacyOcr.ocrCount, 0);
      expect(multiEmissions, hasLength(1));
      expect(multiEmissions.first.slotId, 2);
      expect(multiEmissions.first.rawText, contains('Zorua'));
    });

    test('capturePreviewOnly sends skipOcr=true, invalidation clears native cache & propagates forceOcr to Zone A/B/Multi, and Zone B throttles thumbnails', () async {
      final legacyCap = _CountingOnlyCaptureDriver();
      final legacyOcr = _CountingOcrDriver(const []);
      final nativeBridge = _FastPathBridge();
      var clock = Duration.zero;

      final src = DesktopWindowSource(
        captureDriver: legacyCap,
        ocrDriver: legacyOcr,
        nativeBridge: nativeBridge,
        elapsedClock: () => clock,
      );
      addTearDown(src.dispose);

      src.setSelectedWindow(
        const DesktopWindowInfo(id: 1, hwnd: 101, title: 'mGBA', width: 800, height: 600),
      );
      src.setLiveFocusPreset(LiveFocusPreset.topRight);
      src.setMultiInstanceSlots([
        MultiInstanceSlot(
          id: 2,
          label: '#2',
          colorHex: 0xFFA855F7,
          scanEnabled: true,
          scanRegion: ScreenRegion(
            x: 10,
            y: 20,
            width: 200,
            height: 80,
            isAbsoluteScreen: true,
          ),
        ),
      ]);
      final clearCallsBefore = nativeBridge.clearCacheCalls;

      // 1. capturePreviewOnly must request skipOcr=true and NOT increment scanCount
      nativeBridge.nextResult = const NativeCaptureAnalyzeResult(
        captured: true,
        ocrSkipped: true,
        frameWidth: 800,
        frameHeight: 600,
        thumbnailFrame: CapturedFrame(
          width: 320,
          height: 240,
          bytes: [137, 80, 78, 71],
          pixelFormat: 'png',
        ),
      );
      final previewFrame = await src.capturePreviewOnly();
      expect(previewFrame, isNotNull);
      expect(nativeBridge.requests.last.skipOcr, isTrue);
      expect(nativeBridge.requests.last.includeThumbnail, isTrue);
      expect(src.liveScanStatusNotifier.value.scanCount, 0);

      // 2. Language/profile/mask change invalidates native cache and forces OCR across Zone A, Zone B, and Multi-Slot #2
      src.setOcrLanguageTag('en-US');
      expect(nativeBridge.clearCacheCalls, greaterThan(clearCallsBefore));

      nativeBridge.requests.clear();
      nativeBridge.nextResult = const NativeCaptureAnalyzeResult(
        captured: true,
        ocrSkipped: false,
        lines: ['Wild Pikachu appeared!'],
        frameWidth: 800,
        frameHeight: 600,
        thumbnailFrame: CapturedFrame(
          width: 320,
          height: 240,
          bytes: [137, 80, 78, 71],
          pixelFormat: 'png',
        ),
      );
      await src.triggerSingleScan();

      final zoneAReq1 = nativeBridge.requests.firstWhere((r) => r.slotKey == 'zoneA');
      final zoneBReq1 = nativeBridge.requests.firstWhere((r) => r.slotKey == 'zoneB_1');
      final multiReq1 = nativeBridge.requests.firstWhere((r) => r.slotKey == 'multi_2_scan');
      expect(zoneAReq1.forceOcr, isTrue);
      expect(zoneBReq1.forceOcr, isTrue);
      expect(multiReq1.forceOcr, isTrue);
      expect(zoneBReq1.includeThumbnail, isTrue);

      // 3. +400ms later: forceOcr resets to false, Zone B thumbnail is throttled, focusScanCount stays 1
      clock += const Duration(milliseconds: 400);
      nativeBridge.requests.clear();
      nativeBridge.nextResult = const NativeCaptureAnalyzeResult(
        captured: true,
        ocrSkipped: true,
        frameWidth: 800,
        frameHeight: 600,
      );
      await src.triggerSingleScan();
      expect(nativeBridge.requests.every((r) => !r.forceOcr), isTrue);
      final zoneBReq2 = nativeBridge.requests.firstWhere((r) => r.slotKey == 'zoneB_1');
      expect(zoneBReq2.includeThumbnail, isFalse);

      // 4. +700ms later (>=1000ms): Zone B thumbnail allowed again, updates focusBoxFramesNotifier even if ocrSkipped=true
      clock += const Duration(milliseconds: 700);
      nativeBridge.requests.clear();
      const updatedThumb = CapturedFrame(
        width: 160,
        height: 90,
        bytes: [137, 80, 78, 72],
        pixelFormat: 'png',
      );
      nativeBridge.nextResult = const NativeCaptureAnalyzeResult(
        captured: true,
        ocrSkipped: true,
        frameWidth: 800,
        frameHeight: 600,
        thumbnailFrame: updatedThumb,
      );
      await src.triggerSingleScan();
      final zoneBReq3 = nativeBridge.requests.firstWhere((r) => r.slotKey == 'zoneB_1');
      expect(zoneBReq3.includeThumbnail, isTrue);
      expect(src.focusBoxFramesNotifier.value['B1'], equals(updatedThumb));
      expect(src.liveFocusStatusNotifier.value.latestFrame, equals(updatedThumb));
      expect(src.liveFocusStatusNotifier.value.scanCount, 1);
    });

    test('Multi-Instance-only without Zone A skips full-monitor Zone A scan; minimized slot does not disable native fast-path for healthy slots', () async {
      final legacyCap = _CountingOnlyCaptureDriver();
      final legacyOcr = _CountingOcrDriver(const []);
      final nativeBridge = _FastPathBridge();

      final src = DesktopWindowSource(
        captureDriver: legacyCap,
        ocrDriver: legacyOcr,
        nativeBridge: nativeBridge,
      );
      addTearDown(src.dispose);

      const healthyWin = DesktopWindowInfo(
        id: 1,
        hwnd: 101,
        title: 'mGBA #1',
        width: 800,
        height: 600,
      );
      const minimizedWin = DesktopWindowInfo(
        id: 2,
        hwnd: 202,
        title: 'mGBA #2',
        width: 0,
        height: 0,
        isMinimized: true,
      );
      src.updateKnownWindows([healthyWin, minimizedWin]);
      src.setMultiInstanceSlots([
        const MultiInstanceSlot(
          id: 1,
          label: '#1',
          colorHex: 0xFFA855F7,
          windowHwnd: 101,
          windowTitle: 'mGBA #1',
          scanEnabled: true,
        ),
        const MultiInstanceSlot(
          id: 2,
          label: '#2',
          colorHex: 0xFFEC4899,
          windowHwnd: 202,
          windowTitle: 'mGBA #2',
          scanEnabled: true,
        ),
      ]);

      nativeBridge.nextResult = const NativeCaptureAnalyzeResult(
        captured: true,
        ocrSkipped: false,
        lines: ['Ein wildes Glumanda erscheint!'],
        frameWidth: 800,
        frameHeight: 600,
        selfWindowOverlaps: true,
      );

      await src.triggerSingleScan();

      // Zone A must NOT run on primary screen when no Zone A window/region is configured
      expect(nativeBridge.requests.any((r) => r.slotKey == 'zoneA'), isFalse);
      // Healthy slot #1 must still use native fast-path despite slot #2 being minimized
      expect(nativeBridge.requests.any((r) => r.slotKey == 'multi_1_scan'), isTrue);
      expect(legacyCap.captureCount, 0);
      expect(src.selfWindowOverlapNotifier.value, isTrue);
    });

    test('capturePreviewOnly & processSnippet safely ignore post-dispose completions and failed capture preserves forceNextNativeOcr', () async {
      final nativeBridge = _FastPathBridge();
      final slowCap = _DelayedCaptureDriver();
      final slowOcr = _DelayedOcrDriver();
      final src = DesktopWindowSource(
        captureDriver: slowCap,
        ocrDriver: slowOcr,
        nativeBridge: nativeBridge,
      );

      src.setSelectedWindow(
        const DesktopWindowInfo(id: 1, hwnd: 101, title: 'mGBA', width: 800, height: 600),
      );
      src.setOcrLanguageTag('en-US'); // sets _forceNextNativeOcr = true

      // First scan fails capture -> _forceNextNativeOcr must remain true for retry!
      nativeBridge.nextResult = const NativeCaptureAnalyzeResult(captured: false);
      await src.triggerSingleScan();
      expect(nativeBridge.requests.last.forceOcr, isTrue);

      nativeBridge.nextResult = const NativeCaptureAnalyzeResult(
        captured: true,
        ocrSkipped: false,
        lines: ['Wild Pikachu appeared!'],
        frameWidth: 800,
        frameHeight: 600,
      );
      await src.triggerSingleScan();
      expect(nativeBridge.requests.last.forceOcr, isTrue);

      // Start snippet & preview without native bridge and dispose while awaiting -> no crash
      final src2 = DesktopWindowSource(
        captureDriver: slowCap,
        ocrDriver: slowOcr,
      );
      src2.setSelectedWindow(
        const DesktopWindowInfo(id: 1, title: 'mGBA', width: 800, height: 600),
      );
      final snippetFuture = src2.processSnippet(
        const CapturedFrame(width: 20, height: 20, bytes: [1, 2, 3, 4]),
      );
      final previewFuture = src2.capturePreviewOnly();
      await src2.dispose();
      await snippetFuture;
      await previewFuture;
    });
  });
}

class _CountingOnlyCaptureDriver implements DesktopCaptureDriver {
  int captureCount = 0;
  @override
  Future<CapturedFrame?> captureWindow({
    required DesktopWindowInfo window,
    Rect? cropRegion,
    ScreenRegion? screenRegion,
  }) async {
    captureCount++;
    return null;
  }
}

class _DelayedCaptureDriver implements DesktopCaptureDriver {
  @override
  Future<CapturedFrame?> captureWindow({
    required DesktopWindowInfo window,
    Rect? cropRegion,
    ScreenRegion? screenRegion,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 25));
    return const CapturedFrame(width: 20, height: 20, bytes: [1, 2, 3, 4]);
  }
}

class _DelayedOcrDriver implements DesktopOcrDriver {
  @override
  Future<List<String>> recognizeText(CapturedFrame frame) async {
    await Future<void>.delayed(const Duration(milliseconds: 25));
    return const ['Pikachu'];
  }
}

class _FastPathBridge implements DesktopPlatformBridge {
  final List<NativeCaptureAnalyzeRequest> requests = [];
  int clearCacheCalls = 0;
  NativeCaptureAnalyzeResult nextResult = const NativeCaptureAnalyzeResult();

  @override
  ValueChanged<NativeHudAction>? onHudAction;

  @override
  Future<NativeCaptureAnalyzeResult?> captureAndAnalyze(
    NativeCaptureAnalyzeRequest request,
  ) async {
    requests.add(request);
    return nextResult;
  }

  @override
  Future<void> clearNativeScanCache() async {
    clearCacheCalls++;
  }

  @override
  Future<CapturedFrame?> captureRegion(ScreenRegion region) async => null;

  @override
  Future<CapturedFrame?> captureWindow(
    DesktopWindowInfo window, {
    Rect? cropRegion,
  }) async =>
      null;

  @override
  Future<List<DesktopWindowInfo>> enumerateWindowsAndMonitors() async =>
      const [];

  @override
  Future<void> hideFloatingHud() async {}

  @override
  Future<OcrRecognitionResult> recognizeText(
    CapturedFrame frame, {
    String? languageTag,
    String? preprocessProfile,
  }) async =>
      const OcrRecognitionResult();

  @override
  Future<void> setOverlayBorders(List<OverlayBorderSpec> borders) async {}

  @override
  Future<void> setScanRegionBorder(
    ScreenRegion? region, {
    bool active = true,
  }) async {}

  @override
  Future<bool> showFloatingHud(NativeHudState state) async => true;

  @override
  Future<ScreenRegionCaptureResult?> startDesktopSnipping({
    bool hideAppWindow = false,
    String? hintLabel,
    String? confirmLabel,
    String? cancelLabel,
  }) async =>
      null;

  @override
  Future<bool> updateFloatingHud(NativeHudState state) async => true;
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

class _BandSensitiveOcrDriver implements DesktopOcrDriver {
  final int extraBoxWidth;
  final List<String> fullFrameLines;
  final List<String> topBandLines;
  final List<String> bottomBandLines;
  final List<String> extraBoxLines;

  _BandSensitiveOcrDriver({
    required this.extraBoxWidth,
    required this.fullFrameLines,
    required this.topBandLines,
    required this.bottomBandLines,
    required this.extraBoxLines,
  });

  @override
  Future<List<String>> recognizeText(CapturedFrame frame) async {
    if (frame.width == extraBoxWidth && frame.height == 40) {
      return extraBoxLines;
    }
    if (frame.width == 160 && frame.height == 100) {
      return fullFrameLines;
    }
    if (frame.bytes.isNotEmpty && frame.bytes.first == 30) {
      return topBandLines;
    }
    if (frame.bytes.length >= 4 && frame.bytes[frame.bytes.length - 4] == 200) {
      return bottomBandLines;
    }
    return const [];
  }
}

class _InversionAwareOcrDriver implements DesktopOcrDriver {
  bool sawInvertedFrame = false;

  @override
  Future<List<String>> recognizeText(CapturedFrame frame) async {
    if (frame.bytes.isNotEmpty && frame.bytes.first >= 200) {
      sawInvertedFrame = true;
      return const ['Folikon Lv.22'];
    }
    return const ['2-2', 'alb,.m', 'F ikon', '& b:.2-2'];
  }
}
