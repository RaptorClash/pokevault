import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_io/io.dart' as io;
import 'package:pokevault/services/desktop_tracker/window_detector.dart';
import 'package:pokevault/services/scanner_core/models/scanner_settings.dart';

void main() {
  group('WindowDetector Tests (TDD & Adversarial)', () {
    late WindowDetector detector;

    setUp(() {
      detector = WindowDetector();
    });

    test('Identifies known emulator processes from window titles', () {
      final w1 = detector.identifyEmulator('mGBA - 0.10.3 - Pokemon - Feuerrote Edition (Germany)');
      expect(w1.isKnownEmulator, isTrue);
      expect(w1.emulatorType, EmulatorType.mgba);
      expect(w1.extractedRomName, 'Pokemon - Feuerrote Edition (Germany)');

      final w2 = detector.identifyEmulator('DeSmuME 0.9.13 x64 | Pokemon HeartGold');
      expect(w2.isKnownEmulator, isTrue);
      expect(w2.emulatorType, EmulatorType.desmume);

      final w3 = detector.identifyEmulator('Ryujinx 1.1.1300 - Pokémon Karmesin (v1.3.2) (64-bit)');
      expect(w3.isKnownEmulator, isTrue);
      expect(w3.emulatorType, EmulatorType.ryujinx);

      final w4 = detector.identifyEmulator('Citra Nightly 2100 | Pokémon Omega Rubin');
      expect(w4.isKnownEmulator, isTrue);
      expect(w4.emulatorType, EmulatorType.citra);

      final w5 = detector.identifyEmulator('Dolphin 5.0-20000 | Pokémon Colosseum');
      expect(w5.isKnownEmulator, isTrue);
      expect(w5.emulatorType, EmulatorType.dolphin);

      final w6 = detector.identifyEmulator('BizHawk 2.9.1 - Pokémon Emerald');
      expect(w6.isKnownEmulator, isTrue);
      expect(w6.emulatorType, EmulatorType.bizhawk);

      final w7 = detector.identifyEmulator('melonDS 0.9.5 - Pokemon Platinum');
      expect(w7.isKnownEmulator, isTrue);
      expect(w7.emulatorType, EmulatorType.melonds);

      final w8 = detector.identifyEmulator('[111/60] melonDS 1.1');
      expect(w8.isKnownEmulator, isTrue);
      expect(w8.emulatorType, EmulatorType.melonds);

      final w9 = detector.identifyEmulator('[79/60] melonDS 1.1 - Pokémon Black Version');
      expect(w9.isKnownEmulator, isTrue);
      expect(w9.emulatorType, EmulatorType.melonds);
      expect(w9.extractedRomName, 'Pokémon Black Version');

      final w10 = detector.identifyEmulator('RetroArch 1.19.1 - mGBA (Pokémon Emerald)');
      expect(w10.isKnownEmulator, isTrue);
      expect(w10.emulatorType, EmulatorType.retroarch);

      final w11 = detector.identifyEmulator('Cemu 2.0-89 (Experimental)');
      expect(w11.isKnownEmulator, isTrue);
      expect(w11.emulatorType, EmulatorType.cemu);

      final w12 = detector.identifyEmulator('Snes9x 1.62.3 - Pokemon');
      expect(w12.isKnownEmulator, isTrue);
      expect(w12.emulatorType, EmulatorType.snes9x);
    });

    test('Handles regular non-emulator applications safely', () {
      final w1 = detector.identifyEmulator('Google Chrome - PokéVault');
      expect(w1.isKnownEmulator, isFalse);
      expect(w1.emulatorType, EmulatorType.unknown);

      final w2 = detector.identifyEmulator('Visual Studio Code');
      expect(w2.isKnownEmulator, isFalse);

      final w3 = detector.identifyEmulator('');
      expect(w3.isKnownEmulator, isFalse);
    });

    test('Filters and sorts detected windows prioritizing active emulators', () {
      final rawWindows = [
        const DesktopWindowInfo(id: 1, title: 'Discord'),
        const DesktopWindowInfo(id: 2, title: 'mGBA - Pokemon Emerald'),
        const DesktopWindowInfo(id: 3, title: 'Spotify'),
        const DesktopWindowInfo(id: 4, title: 'Ryujinx - Pokémon Purpur'),
      ];

      final filtered = detector.filterAndRankWindows(rawWindows);

      expect(filtered.length, 4);
      // Emulators must be ranked first
      expect(filtered[0].title, contains('mGBA'));
      expect(filtered[1].title, contains('Ryujinx'));
      expect(filtered[0].isKnownEmulator, isTrue);
      expect(filtered[1].isKnownEmulator, isTrue);
    });

    test('Calculates default dialogue textbox region (lower 30% of window)', () {
      const windowWidth = 1000.0;
      const windowHeight = 600.0;

      final crop = detector.calculateDefaultDialogueRegion(
        windowWidth: windowWidth,
        windowHeight: windowHeight,
      );

      expect(crop.left, 0.0);
      expect(crop.top, 420.0); // 70% from top
      expect(crop.width, 1000.0);
      expect(crop.height, 180.0); // 30% height
    });

    test('parseTasklistCsv parses real windows and excludes system & PokéVault windows', () {
      const sampleCsv = '''"Abbildname","PID","Sitzungsname","Sitz.-Nr.","Speichernutzung","Status","Benutzername","CPU-Zeit","Fenstertitel"
"System","4","Services","0","7.116 K","Unknown","Nicht zutreffend","0:22:53","Nicht zutreffend"
"dwm.exe","2544","Console","1","119.112 K","Running","Nicht zutreffend","0:27:17","DWM Notification Window"
"taskhostw.exe","9164","Console","1","22.392 K","Running","DESKTOP\\user","0:00:02","Task Host Window"
"Code.exe","24564","Console","1","134.180 K","Running","DESKTOP\\user","0:00:22","pokevault - Visual Studio Code"
"powershell.exe","26128","Console","1","64.356 K","Running","DESKTOP\\user","0:00:01","OleMainThreadWndName"
"melonDS.exe","16404","Console","1","672.504 K","Running","DESKTOP\\user","0:03:02","[111/60] melonDS 1.1"
"Discord.exe","18064","Console","1","130.528 K","Running","DESKTOP\\user","0:00:58","Discord - Pokévault Community"
"PokeVault.exe","6424","Console","1","500.840 K","Running","DESKTOP\\user","0:00:20","PokéVault"
''';

      final windows = detector.parseTasklistCsv(sampleCsv);

      // Should extract 3 valid user windows: melonDS, Visual Studio Code, Discord
      expect(windows.length, 3);

      // melonDS must be first (isKnownEmulator)
      expect(windows[0].processName, 'melonDS.exe');
      expect(windows[0].id, 16404);
      expect(windows[0].title, '[111/60] melonDS 1.1');
      expect(windows[0].isKnownEmulator, isTrue);
      expect(windows[0].emulatorType, EmulatorType.melonds);

      // Non-emulators follow
      final nonEmuTitles = windows.skip(1).map((w) => w.title).toList();
      expect(nonEmuTitles, contains('pokevault - Visual Studio Code'));
      expect(nonEmuTitles, contains('Discord - Pokévault Community'));

      // Filtered out:
      final allTitles = windows.map((w) => w.title).toList();
      expect(allTitles, isNot(contains('DWM Notification Window')));
      expect(allTitles, isNot(contains('Task Host Window')));
      expect(allTitles, isNot(contains('OleMainThreadWndName')));
      expect(allTitles, isNot(contains('PokéVault')));
    });

    test('parseTasklistCsv handles empty or invalid CSV gracefully without throwing', () {
      expect(detector.parseTasklistCsv(''), isEmpty);
      expect(detector.parseTasklistCsv('header only\n'), isEmpty);
      expect(detector.parseTasklistCsv('corrupted,data,"unclosed quote'), isEmpty);
    });

    test('DesktopWindowInfo equality and hashCode are based on id (PID) and processName', () {
      const w1 = DesktopWindowInfo(
        id: 16404,
        title: '[92/60] melonDS 1.1',
        processName: 'melonDS.exe',
        emulatorType: EmulatorType.melonds,
      );

      // Same process ID and processName, but title changed due to FPS counter
      const w2 = DesktopWindowInfo(
        id: 16404,
        title: '[33/60] melonDS 1.1',
        processName: 'melonDS.exe',
        emulatorType: EmulatorType.melonds,
      );

      // Different PID
      const w3 = DesktopWindowInfo(
        id: 9999,
        title: '[33/60] melonDS 1.1',
        processName: 'melonDS.exe',
        emulatorType: EmulatorType.melonds,
      );

      expect(w1 == w2, isTrue, reason: 'Windows with matching PID and process must be equal');
      expect(w1.hashCode, equals(w2.hashCode));
      expect(w1 == w3, isFalse);
    });

    test('calculateScanRegion supports all ScanRegionPreset options correctly', () {
      const double width = 1000.0;
      const double height = 800.0;

      final full = detector.calculateScanRegion(
        ScanRegionPreset.fullWindow,
        windowWidth: width,
        windowHeight: height,
      );
      expect(full.left, 0.0);
      expect(full.top, 0.0);
      expect(full.width, 1000.0);
      expect(full.height, 800.0);

      final topScreen = detector.calculateScanRegion(
        ScanRegionPreset.dsTopScreen,
        windowWidth: width,
        windowHeight: height,
      );
      expect(topScreen.left, 0.0);
      expect(topScreen.top, 0.0);
      expect(topScreen.width, 1000.0);
      expect(topScreen.height, 416.0); // 52% of 800

      final bottomScreen = detector.calculateScanRegion(
        ScanRegionPreset.dsBottomScreen,
        windowWidth: width,
        windowHeight: height,
      );
      expect(bottomScreen.left, 0.0);
      expect(bottomScreen.top, 384.0); // starts at 48% of 800
      expect(bottomScreen.width, 1000.0);
      expect(bottomScreen.height, 416.0);

      final dialogue = detector.calculateScanRegion(
        ScanRegionPreset.bottomDialogue,
        windowWidth: width,
        windowHeight: height,
      );
      expect(dialogue.left, 0.0);
      expect(dialogue.top, 560.0); // 70% of 800
      expect(dialogue.width, 1000.0);
      expect(dialogue.height, 240.0); // 30% of 800
    });

    test('getOpenWindowsAsync completes asynchronously without blocking', () async {
      final windows = await detector.getOpenWindowsAsync();
      expect(windows, isNotEmpty);
      expect(windows.any((w) => w.isKnownEmulator), isTrue);
    });

    test('getOpenWindowsAsync executes tasklist with SESSION ne 0 filter and parses output', () async {
      List<String>? capturedArgs;
      final customDetector = WindowDetector(
        processRunner: (exe, args) async {
          capturedArgs = args;
          return io.ProcessResult(
            123,
            0,
            '''"Abbildname","PID","Sitzungsname","Sitz.-Nr.","Speichernutzung","Status","Benutzername","CPU-Zeit","Fenstertitel"\r\n"melonDS.exe","16404","Console","1","287.256 K","Running","DESKTOP\\user","0:01:00","[79/60] melonDS 1.1"\r\n"Spotify.exe","18444","Console","1","200.000 K","Running","DESKTOP\\user","0:01:00","Linkin Park - The Catalyst"\r\n''',
            '',
          );
        },
      );

      final windows = await customDetector.getOpenWindowsAsync();

      expect(capturedArgs, containsAllInOrder(['/FI', 'SESSION ne 0', '/V', '/FO', 'CSV']));
      expect(windows.length, 3);
      expect(windows[0].title, '[79/60] melonDS 1.1');
      expect(windows[0].emulatorType, EmulatorType.melonds);
      expect(windows[1].isDesktopScreen, isTrue);
      expect(windows[2].title, 'Linkin Park - The Catalyst');
    });

    test('Includes Desktop / Primary Screen as selectable target in windows list', () async {
      final screen = DesktopWindowInfo.primaryScreen(width: 1920, height: 1080);
      expect(screen.isDesktopScreen, isTrue);
      expect(screen.width, 1920.0);
      expect(screen.height, 1080.0);
      expect(screen.title, contains('Desktop'));

      final fallbacks = detector.getFallbackWindows();
      expect(fallbacks.any((w) => w.isDesktopScreen), isTrue);

      final windows = await detector.getOpenWindowsAsync();
      expect(windows.any((w) => w.isDesktopScreen), isTrue);
    });

    test('DesktopWindowInfo distinguishes multiple windows of same PID by hwnd and tracks bounds/minimized', () {
      const w1 = DesktopWindowInfo(
        id: 8800,
        hwnd: 10001,
        title: 'PokéWiki — Google Chrome',
        processName: 'chrome.exe',
        bounds: Rect.fromLTWH(0, 0, 1200, 800),
      );
      const w2 = DesktopWindowInfo(
        id: 8800,
        hwnd: 10002,
        title: 'YouTube — Google Chrome',
        processName: 'chrome.exe',
        bounds: Rect.fromLTWH(100, 100, 1000, 700),
        isMinimized: true,
      );
      const w1Updated = DesktopWindowInfo(
        id: 8800,
        hwnd: 10001,
        title: 'PokéVault Docs — Google Chrome',
        processName: 'chrome.exe',
      );

      expect(w1 == w2, isFalse);
      expect(w1 == w1Updated, isTrue);
      expect(w1.hashCode, equals(w1Updated.hashCode));
      expect(w2.isMinimized, isTrue);
      expect(w1.bounds, const Rect.fromLTWH(0, 0, 1200, 800));
    });

    test('getOpenWindowsAsync prefers nativeWindowEnumerator and does NOT inject fake emulators', () async {
      final nativeDetector = WindowDetector(
        nativeWindowEnumerator: () async => [
          DesktopWindowInfo.primaryScreen(width: 2560, height: 1440),
          const DesktopWindowInfo(
            id: 500,
            hwnd: 7701,
            title: 'Discord',
            processName: 'Discord.exe',
            width: 1200,
            height: 800,
          ),
          const DesktopWindowInfo(
            id: 600,
            hwnd: 7702,
            title: 'Azahar 2120 | Pokémon X',
            processName: 'azahar.exe',
            width: 800,
            height: 960,
          ),
        ],
      );

      final windows = await nativeDetector.getOpenWindowsAsync();

      expect(windows.length, 3);
      // Azahar recognized & ranked first
      expect(windows[0].hwnd, 7702);
      expect(windows[0].isKnownEmulator, isTrue);
      // Desktop monitor second
      expect(windows[1].isDesktopScreen, isTrue);
      expect(windows[1].width, 2560.0);
      // Discord third
      expect(windows[2].title, 'Discord');
      // No fake mGBA/Ryujinx injected!
      expect(windows.any((w) => w.title.contains('mGBA (GameBoy Advance)')), isFalse);
    });

    test('getOpenWindowsAsync with nativeWindowEnumerator returning only monitors + regular apps returns no fake emulators', () async {
      final nativeDetector = WindowDetector(
        nativeWindowEnumerator: () async => [
          DesktopWindowInfo.primaryScreen(width: 1920, height: 1080),
          const DesktopWindowInfo(
            id: 900,
            hwnd: 8801,
            title: 'Visual Studio Code',
            processName: 'Code.exe',
          ),
        ],
      );

      final windows = await nativeDetector.getOpenWindowsAsync();
      expect(windows.length, 2);
      expect(windows.any((w) => w.isKnownEmulator), isFalse);
    });

    test('calculateEnemyHudCropRegion computes accurate Zone B presets for single and horde encounters', () {
      expect(
        detector.calculateEnemyHudCropRegion(
          LiveFocusPreset.disabled,
          windowWidth: 960,
          windowHeight: 1040,
        ),
        isNull,
      );
      expect(
        detector.calculateEnemyHudCropRegion(
          LiveFocusPreset.customRegion,
          windowWidth: 960,
          windowHeight: 1040,
        ),
        isNull,
      );

      final topLeft = detector.calculateEnemyHudCropRegion(
        LiveFocusPreset.topLeft,
        windowWidth: 1000,
        windowHeight: 1000,
      )!;
      expect(topLeft.left, 0.0);
      expect(topLeft.top, 0.0);
      expect(topLeft.width, closeTo(420.0, 0.01));
      expect(topLeft.height, closeTo(220.0, 0.01));

      final topRight = detector.calculateEnemyHudCropRegion(
        LiveFocusPreset.topRight,
        windowWidth: 1000,
        windowHeight: 1000,
      )!;
      expect(topRight.left, closeTo(580.0, 0.01));
      expect(topRight.top, 0.0);
      expect(topRight.width, closeTo(420.0, 0.01));
      expect(topRight.height, closeTo(220.0, 0.01));

      final topBanner = detector.calculateEnemyHudCropRegion(
        LiveFocusPreset.topBanner,
        windowWidth: 1000,
        windowHeight: 1000,
      )!;
      expect(topBanner.left, 0.0);
      expect(topBanner.top, 0.0);
      expect(topBanner.width, 1000.0);
      expect(topBanner.height, closeTo(240.0, 0.01));
    });

    test('parseTasklistCsv dynamically locates Fenstertitel / Window Title column regardless of locale column order', () {
      const shiftedGermanCsv =
          '"Abbildname","PID","Status","Fenstertitel","Benutzername"\n'
          '"melonDS.exe","4321","Wird ausgeführt","melonDS 1.0 - Pokemon Schwarz","PC\\User"\n';
      final parsed = detector.parseTasklistCsv(shiftedGermanCsv);
      expect(parsed, hasLength(1));
      expect(parsed.first.emulatorType, EmulatorType.melonds);
      expect(parsed.first.title, 'melonDS 1.0 - Pokemon Schwarz');
    });

    test('parseTasklistCsv falls back to last column for non-DE/EN Windows locales (e.g. Spanish/French)', () {
      const spanishCsv =
          '"Nombre de imagen","PID","Nombre de sesión","Núm. de sesión","Uso de memoria","Estado","Nombre de usuario","Tiempo de CPU","Título de ventana"\n'
          '"mGBA.exe","7788","Console","1","120.000 K","Running","PC\\User","0:00:12","mGBA - 0.10.3 - Pokemon Esmeralda"\n';
      final parsedEs = detector.parseTasklistCsv(spanishCsv);
      expect(parsedEs, hasLength(1));
      expect(parsedEs.first.emulatorType, EmulatorType.mgba);
      expect(parsedEs.first.id, 7788);
      expect(parsedEs.first.title, 'mGBA - 0.10.3 - Pokemon Esmeralda');

      const frenchCsv =
          '"Nom de l\'image","PID","Nom de la session","Numéro de session","Utilisation mémoire","État","Nom d\'utilisateur","Temps processeur","Titre de la fenêtre"\n'
          '"melonDS.exe","9900","Console","1","250.000 Ko","Running","PC\\User","0:00:30","melonDS 1.0 - Pokémon Platine"\n';
      final parsedFr = detector.parseTasklistCsv(frenchCsv);
      expect(parsedFr, hasLength(1));
      expect(parsedFr.first.emulatorType, EmulatorType.melonds);
      expect(parsedFr.first.title, 'melonDS 1.0 - Pokémon Platine');
    });
  });
}
