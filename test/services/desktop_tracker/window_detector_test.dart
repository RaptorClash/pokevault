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
  });
}
