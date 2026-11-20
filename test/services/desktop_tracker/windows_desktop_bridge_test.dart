import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/services/desktop_tracker/desktop_capture_driver.dart';
import 'package:pokevault/services/desktop_tracker/screen_region.dart';
import 'package:pokevault/services/desktop_tracker/window_detector.dart';
import 'package:pokevault/services/desktop_tracker/windows_desktop_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WindowsDesktopBridge Unit & MethodChannel Tests (TDD)', () {
    const channel = MethodChannel('pokevault/desktop_tracker');
    late WindowsDesktopBridge bridge;
    final List<MethodCall> recordedCalls = [];

    setUp(() {
      recordedCalls.clear();
      bridge = WindowsDesktopBridge(channel: channel);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('mapPokemonLanguageToBcp47 maps franchise language codes accurately', () {
      expect(WindowsDesktopBridge.mapPokemonLanguageToBcp47('de'), 'de-DE');
      expect(WindowsDesktopBridge.mapPokemonLanguageToBcp47('en'), 'en-US');
      expect(WindowsDesktopBridge.mapPokemonLanguageToBcp47('fr'), 'fr-FR');
      expect(WindowsDesktopBridge.mapPokemonLanguageToBcp47('es'), 'es-ES');
      expect(WindowsDesktopBridge.mapPokemonLanguageToBcp47('it'), 'it-IT');
      expect(WindowsDesktopBridge.mapPokemonLanguageToBcp47('ja'), 'ja-JP');
      expect(WindowsDesktopBridge.mapPokemonLanguageToBcp47('ko'), 'ko-KR');
      expect(WindowsDesktopBridge.mapPokemonLanguageToBcp47('zh-Hans'), 'zh-Hans');
      expect(WindowsDesktopBridge.mapPokemonLanguageToBcp47('zh-Hant'), 'zh-Hant');
      expect(WindowsDesktopBridge.mapPokemonLanguageToBcp47('unknown'), 'en-US');
    });

    test('enumerateWindowsAndMonitors parses monitors, UTF-8 titles, bounds, and multiple windows per PID', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        recordedCalls.add(call);
        if (call.method == 'enumerateWindows') {
          return {
            'monitors': [
              {
                'index': 1,
                'title': '🖥️ Monitor 1 (Primär) — 2560×1440',
                'x': 0.0,
                'y': 0.0,
                'width': 2560.0,
                'height': 1440.0,
                'isPrimary': true,
                'isVirtualDesktop': false,
              },
              {
                'index': 2,
                'title': '🖥️ Monitor 2 — 1920×1080',
                'x': -1920.0,
                'y': 180.0,
                'width': 1920.0,
                'height': 1080.0,
                'isPrimary': false,
                'isVirtualDesktop': false,
              },
            ],
            'windows': [
              {
                'hwnd': 10001,
                'pid': 4200,
                'title': '[60/60] melonDS 1.1 — Pokémon Platin (Ümlaut)',
                'processName': 'melonDS.exe',
                'x': 100.0,
                'y': 50.0,
                'width': 1280.0,
                'height': 960.0,
                'isMinimized': false,
              },
              {
                'hwnd': 20001,
                'pid': 8800,
                'title': 'PokéWiki — Google Chrome',
                'processName': 'chrome.exe',
                'x': -1800.0,
                'y': 200.0,
                'width': 1400.0,
                'height': 900.0,
                'isMinimized': false,
              },
              {
                'hwnd': 20002,
                'pid': 8800,
                'title': 'Second Chrome Window',
                'processName': 'chrome.exe',
                'x': 50.0,
                'y': 50.0,
                'width': 1000.0,
                'height': 700.0,
                'isMinimized': true,
              },
            ],
          };
        }
        return null;
      });

      final results = await bridge.enumerateWindowsAndMonitors();
      expect(recordedCalls.single.method, 'enumerateWindows');
      expect(results.length, 5);

      // Verify melonDS bounds, hwnd, and UTF-8 title
      final melon = results.firstWhere((w) => w.hwnd == 10001);
      expect(melon.isKnownEmulator, isTrue);
      expect(melon.emulatorType, EmulatorType.melonds);
      expect(melon.bounds, const Rect.fromLTWH(100, 50, 1280, 960));
      expect(melon.width, 1280.0);
      expect(melon.height, 960.0);
      expect(melon.title, contains('Pokémon Platin (Ümlaut)'));

      // Verify both Chrome windows with same PID (8800) remain distinct by HWND
      final chromes = results.where((w) => w.processName == 'chrome.exe').toList();
      expect(chromes.length, 2);
      expect(chromes[0] == chromes[1], isFalse);
      expect(chromes.any((w) => w.isMinimized), isTrue);

      // Verify negative multi-monitor bounds
      final mon2 = results.firstWhere((w) => w.monitorIndex == 2);
      expect(mon2.isDesktopScreen, isTrue);
      expect(mon2.bounds, const Rect.fromLTWH(-1920, 180, 1920, 1080));
    });

    test('startDesktopSnipping sends hideAppWindow=false and parses negative multi-monitor coordinates', () async {
      final samplePng = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        recordedCalls.add(call);
        if (call.method == 'startDesktopSnipping') {
          return {
            'x': -1200.0,
            'y': 300.0,
            'width': 480.0,
            'height': 150.0,
            'previewPng': samplePng,
          };
        }
        return null;
      });

      final res = await bridge.startDesktopSnipping(hideAppWindow: false);
      expect(recordedCalls.single.method, 'startDesktopSnipping');
      expect(recordedCalls.single.arguments, {'hideAppWindow': false});

      expect(res, isNotNull);
      expect(res!.region.x, -1200.0);
      expect(res.region.y, 300.0);
      expect(res.region.width, 480.0);
      expect(res.region.height, 150.0);
      expect(res.region.isAbsoluteScreen, isTrue);
      expect(res.previewBytes, equals(samplePng));
    });

    test('startDesktopSnipping returns null when user cancels with ESC', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => null);

      final res = await bridge.startDesktopSnipping(hideAppWindow: false);
      expect(res, isNull);
    });

    test('captureRegion and captureWindow construct CapturedFrame with bgra8888 format', () async {
      final rawBgra = Uint8List.fromList(List.filled(16, 255));

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        recordedCalls.add(call);
        return {
          'width': 2,
          'height': 2,
          'pixelFormat': 'bgra8888',
          'captureMethod': 'bitblt_screen',
          'bytes': rawBgra,
        };
      });

      final region = ScreenRegion(
        x: -100,
        y: 200,
        width: 400,
        height: 120,
        isAbsoluteScreen: true,
      );
      final f1 = await bridge.captureRegion(region);
      expect(f1, isNotNull);
      expect(f1!.width, 2);
      expect(f1.height, 2);
      expect(f1.pixelFormat, 'bgra8888');
      expect(f1.captureMethod, 'bitblt_screen');
      expect(recordedCalls.last.method, 'captureRegion');

      const win = DesktopWindowInfo(
        id: 42,
        hwnd: 9999,
        title: 'melonDS',
        width: 1280,
        height: 960,
      );
      final f2 = await bridge.captureWindow(
        win,
        cropRegion: const Rect.fromLTWH(0, 500, 1280, 200),
      );
      expect(f2, isNotNull);
      expect(recordedCalls.last.method, 'captureWindow');
      expect(recordedCalls.last.arguments['hwnd'], 9999);
    });

    test('recognizeText passes languageTag and returns trimmed lines + diagnostic metadata', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        recordedCalls.add(call);
        return {
          'lines': ['  Ein wildes Shiny Sheinux erscheint!  ', '', '   '],
          'usedFallbackLanguage': false,
          'resolvedLanguageTag': 'de-DE',
          'requestedLanguageTag': 'de-DE',
          'availableLanguages': ['de-DE', 'en-US'],
          'ocrSucceeded': true,
          'ocrDurationMs': 38,
        };
      });

      const frame = CapturedFrame(
        width: 400,
        height: 100,
        bytes: [1, 2, 3, 4],
        pixelFormat: 'bgra8888',
      );
      final result = await bridge.recognizeText(frame, languageTag: 'de-DE');

      expect(recordedCalls.single.method, 'recognizeText');
      expect(recordedCalls.single.arguments['languageTag'], 'de-DE');
      expect(result.lines, ['Ein wildes Shiny Sheinux erscheint!']);
      expect(result.usedFallbackLanguage, isFalse);
      expect(result.resolvedLanguageTag, 'de-DE');
      expect(result.requestedLanguageTag, 'de-DE');
      expect(result.availableLanguageTags, ['de-DE', 'en-US']);
      expect(result.ocrSucceeded, isTrue);
      expect(result.ocrDurationMs, 38);
    });

    test('showFloatingHud, updateFloatingHud, hideFloatingHud and incoming callbacks work', () async {
      bool markCaughtTriggered = false;
      bool closeTriggered = false;
      bool? compactTriggered;
      Offset? movedPos;

      bridge.onHudAction = (action) {
        switch (action.type) {
          case NativeHudActionType.markCaught:
            markCaughtTriggered = true;
            break;
          case NativeHudActionType.close:
            closeTriggered = true;
            break;
          case NativeHudActionType.compactChanged:
            compactTriggered = action.boolValue;
            break;
          case NativeHudActionType.moved:
            movedPos = action.position;
            break;
          default:
            break;
        }
      };

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        recordedCalls.add(call);
        return true;
      });

      await bridge.showFloatingHud(
        const NativeHudState(
          pokemonName: 'Sheinux',
          pokemonId: 403,
          isShiny: true,
          isCaught: false,
          opacity: 0.9,
          isCompact: false,
          isPinned: true,
          anchorRect: Rect.fromLTWH(100, 100, 800, 600),
        ),
      );
      expect(recordedCalls.last.method, 'showFloatingHud');
      expect(recordedCalls.last.arguments['anchorRect']['width'], 800.0);

      await bridge.updateFloatingHud(
        const NativeHudState(
          pokemonName: 'Pikachu',
          pokemonId: 25,
          isShiny: false,
          isCaught: true,
        ),
      );
      expect(recordedCalls.last.method, 'updateFloatingHud');

      await bridge.hideFloatingHud();
      expect(recordedCalls.last.method, 'hideFloatingHud');

      // Simulate native -> Dart callbacks
      const codec = StandardMethodCodec();
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        'pokevault/desktop_tracker',
        codec.encodeMethodCall(const MethodCall('onHudMarkCaught')),
        (_) {},
      );
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        'pokevault/desktop_tracker',
        codec.encodeMethodCall(const MethodCall('onHudCompactChanged', {'isCompact': true})),
        (_) {},
      );
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        'pokevault/desktop_tracker',
        codec.encodeMethodCall(const MethodCall('onHudMoved', {'x': 350.0, 'y': 220.0})),
        (_) {},
      );
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        'pokevault/desktop_tracker',
        codec.encodeMethodCall(const MethodCall('onHudClose')),
        (_) {},
      );

      expect(markCaughtTriggered, isTrue);
      expect(compactTriggered, isTrue);
      expect(movedPos, const Offset(350.0, 220.0));
      expect(closeTriggered, isTrue);
    });

    test('Adversarial: MissingPluginException and PlatformException fail gracefully', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'ERR_WIN32', message: 'Simulated failure');
      });

      expect(await bridge.enumerateWindowsAndMonitors(), isEmpty);
      expect(await bridge.startDesktopSnipping(), isNull);
      expect(
        await bridge.captureRegion(ScreenRegion(x: 0, y: 0, width: 100, height: 100)),
        isNull,
      );
      final ocr = await bridge.recognizeText(
        const CapturedFrame(width: 10, height: 10, bytes: [1, 2, 3, 4]),
      );
      expect(ocr.lines, isEmpty);
    });

    test('setScanRegionBorder invokes showScanRegionBorder and hideScanRegionBorder', () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return true;
      });

      final region = ScreenRegion(
        x: 50,
        y: 80,
        width: 420,
        height: 160,
        isAbsoluteScreen: true,
      );
      await bridge.setScanRegionBorder(region, active: true);
      await bridge.setScanRegionBorder(null);

      expect(calls.length, 2);
      expect(calls[0].method, 'showScanRegionBorder');
      final showArgs = Map<String, dynamic>.from(calls[0].arguments as Map);
      expect(showArgs['x'], 50.0);
      expect(showArgs['y'], 80.0);
      expect(showArgs['width'], 420.0);
      expect(showArgs['height'], 160.0);
      expect(showArgs['active'], isTrue);
      expect(calls[1].method, 'hideScanRegionBorder');
    });

    test('recognizeText forwards optional preprocessProfile argument over MethodChannel', () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        if (call.method == 'recognizeText') {
          return {
            'lines': ['Klasse!'],
            'ocrSucceeded': true,
          };
        }
        return null;
      });

      await bridge.recognizeText(
        const CapturedFrame(width: 4, height: 4, bytes: [1, 2, 3, 4]),
        languageTag: 'de-DE',
        preprocessProfile: 'pixelArtDs',
      );

      expect(calls.single.method, 'recognizeText');
      final args = Map<String, dynamic>.from(calls.single.arguments as Map);
      expect(args['languageTag'], 'de-DE');
      expect(args['preprocessProfile'], 'pixelArtDs');
    });

    test('setOverlayBorders forwards multi-zone cyan/green/multi-instance specs and NativeHudState includes evolutionSummary', () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return true;
      });

      await bridge.setOverlayBorders([
        OverlayBorderSpec(
          id: 'zone_a',
          region: ScreenRegion(x: 100, y: 400, width: 600, height: 140, isAbsoluteScreen: true),
          colorArgb: 0xFF10B981,
          label: 'Scan',
        ),
        OverlayBorderSpec(
          id: 'zone_b',
          region: ScreenRegion(x: 100, y: 80, width: 320, height: 90, isAbsoluteScreen: true),
          colorArgb: 0xFF06B6D4,
          label: 'Fokus',
        ),
      ]);

      expect(calls.single.method, 'setOverlayBorders');
      final payload = Map<String, dynamic>.from(calls.single.arguments as Map);
      final borders = (payload['borders'] as List).cast<Map>();
      expect(borders, hasLength(2));
      expect(borders[1]['id'], 'zone_b');
      expect(borders[1]['colorArgb'], 0xFF06B6D4);
      expect(borders[1]['label'], 'Fokus');

      const hudState = NativeHudState(
        pokemonName: 'Flampion',
        pokemonId: 554,
        isCaught: true,
        hasEvent: true,
        evolutionSummary: 'Entw.: Flampivian fehlt!',
        hasMissingEvolutions: true,
        instanceLabel: '#1',
      );
      final map = hudState.toMap();
      expect(map['evolutionSummary'], 'Entw.: Flampivian fehlt!');
      expect(map['hasMissingEvolutions'], isTrue);
      expect(map['instanceLabel'], '#1');
    });

    test('NativeHudState and startDesktopSnipping forward localized labels and capture tolerates List<dynamic> bytes', () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        if (call.method == 'captureRegion') {
          return <String, dynamic>{
            'width': 1,
            'height': 1,
            'bytes': <dynamic>[10, 20, 30, 255],
          };
        }
        return true;
      });

      const hud = NativeHudState(
        pokemonName: 'Pikachu',
        waitingLabel: 'Waiting for event...',
        caughtLabel: 'Caught',
        missingLabel: 'Missing in Dex',
        footerLabel: 'Opacity: 92% · Drag to move',
      );
      await bridge.showFloatingHud(hud);
      await bridge.startDesktopSnipping(
        hintLabel: 'Drag region · ESC = Cancel',
        confirmLabel: 'Start Live OCR (Enter)',
        cancelLabel: 'Cancel',
      );
      final frame = await bridge.captureRegion(
        ScreenRegion(x: 0, y: 0, width: 1, height: 1, isAbsoluteScreen: true),
      );

      final hudArgs = Map<String, dynamic>.from(calls[0].arguments as Map);
      expect(hudArgs['waitingLabel'], 'Waiting for event...');
      expect(hudArgs['caughtLabel'], 'Caught');
      expect(hudArgs['missingLabel'], 'Missing in Dex');
      expect(hudArgs['footerLabel'], 'Opacity: 92% · Drag to move');

      final snipArgs = Map<String, dynamic>.from(calls[1].arguments as Map);
      expect(snipArgs['hintLabel'], 'Drag region · ESC = Cancel');
      expect(snipArgs['confirmLabel'], 'Start Live OCR (Enter)');
      expect(snipArgs['cancelLabel'], 'Cancel');

      expect(frame, isNotNull);
      expect(frame!.bytes, [10, 20, 30, 255]);
    });
  });
}
