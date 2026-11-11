import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/services/scanner_core/models/scanner_event.dart';
import 'package:pokevault/services/scanner_core/models/scanner_settings.dart';

void main() {
  group('ScannerModels & ScannerSettings Tests (TDD)', () {
    test('ScannerEvent initialization and properties', () {
      final now = DateTime.now();
      final event = ScannerEvent(
        type: ScannerEventType.caught,
        pokemonId: 4,
        rawText: 'Glumanda wurde gefangen!',
        matchedName: 'Glumanda',
        isShiny: true,
        gender: 'male',
        isAlpha: false,
        preEvolutionId: null,
        preEvolutionName: null,
        confidence: 0.95,
        timestamp: now,
        languageCode: 'de',
      );

      expect(event.type, ScannerEventType.caught);
      expect(event.pokemonId, 4);
      expect(event.rawText, 'Glumanda wurde gefangen!');
      expect(event.matchedName, 'Glumanda');
      expect(event.isShiny, isTrue);
      expect(event.gender, 'male');
      expect(event.isAlpha, isFalse);
      expect(event.confidence, 0.95);
      expect(event.timestamp, now);
      expect(event.languageCode, 'de');
    });

    test('ScannerSettings defaults and copyWith', () {
      final settings = ScannerSettings.defaults();

      expect(settings.autoMarkCaught, isTrue);
      expect(settings.trackEvolutions, isTrue);
      expect(settings.livingDexEvolutionAction, LivingDexEvolutionAction.askBeforeRemoving);
      expect(settings.detectShinies, isTrue);
      expect(settings.detectAlphas, isTrue);
      expect(settings.playAudioFeedback, isTrue);
      expect(settings.playHapticFeedback, isTrue);
      expect(settings.desktopOverlayMode, DesktopOverlayMode.floatingHud);
      expect(settings.ocrLanguage, 'auto');

      final updated = settings.copyWith(
        autoMarkCaught: false,
        desktopOverlayMode: DesktopOverlayMode.clickThroughOverlay,
        livingDexEvolutionAction: LivingDexEvolutionAction.autoRemovePreEvolution,
      );

      expect(updated.autoMarkCaught, isFalse);
      expect(updated.desktopOverlayMode, DesktopOverlayMode.clickThroughOverlay);
      expect(updated.livingDexEvolutionAction, LivingDexEvolutionAction.autoRemovePreEvolution);
      expect(updated.detectShinies, isTrue); // unchanged
    });

    test('ScannerSettings serialization toMap and fromMap', () {
      const settings = ScannerSettings(
        autoMarkCaught: false,
        trackEvolutions: true,
        livingDexEvolutionAction: LivingDexEvolutionAction.autoRemovePreEvolution,
        detectShinies: false,
        detectAlphas: true,
        playAudioFeedback: false,
        playHapticFeedback: true,
        desktopOverlayMode: DesktopOverlayMode.silentBackground,
        ocrLanguage: 'de',
      );

      final map = settings.toMap();
      final fromMap = ScannerSettings.fromMap(map);

      expect(fromMap.autoMarkCaught, isFalse);
      expect(fromMap.trackEvolutions, isTrue);
      expect(fromMap.livingDexEvolutionAction, LivingDexEvolutionAction.autoRemovePreEvolution);
      expect(fromMap.detectShinies, isFalse);
      expect(fromMap.detectAlphas, isTrue);
      expect(fromMap.playAudioFeedback, isFalse);
      expect(fromMap.playHapticFeedback, isTrue);
      expect(fromMap.desktopOverlayMode, DesktopOverlayMode.silentBackground);
      expect(fromMap.ocrLanguage, 'de');
    });

    test('ScannerSettings fromMap with empty/corrupted data falls back to safe defaults', () {
      final empty = ScannerSettings.fromMap({});
      expect(empty.autoMarkCaught, isTrue);
      expect(empty.livingDexEvolutionAction, LivingDexEvolutionAction.askBeforeRemoving);
      expect(empty.desktopOverlayMode, DesktopOverlayMode.floatingHud);

      final corrupted = ScannerSettings.fromMap({
        'livingDexEvolutionAction': 'invalid_action_value',
        'desktopOverlayMode': 'non_existent_mode',
      });
      expect(corrupted.livingDexEvolutionAction, LivingDexEvolutionAction.askBeforeRemoving);
      expect(corrupted.desktopOverlayMode, DesktopOverlayMode.floatingHud);
    });
  });
}
