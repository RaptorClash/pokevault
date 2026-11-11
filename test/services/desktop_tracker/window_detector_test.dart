import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/services/desktop_tracker/window_detector.dart';

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
  });
}
