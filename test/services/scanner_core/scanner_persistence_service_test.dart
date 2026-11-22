import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokevault/services/scanner_core/models/scanner_event.dart';
import 'package:pokevault/services/scanner_core/models/scanner_settings.dart';
import 'package:pokevault/services/scanner_core/scanner_persistence_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ScannerPersistenceService TDD', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('roundtrips all ScannerSettings fields including ocrLanguage and toggles', () async {
      final service = ScannerPersistenceService();
      const saved = ScannerSettings(
        autoMarkCaught: false,
        trackEvolutions: false,
        livingDexEvolutionAction: LivingDexEvolutionAction.autoRemovePreEvolution,
        detectShinies: false,
        detectAlphas: false,
        playAudioFeedback: false,
        playHapticFeedback: false,
        desktopOverlayMode: DesktopOverlayMode.floatingHud,
        ocrLanguage: 'ja',
        preprocessProfile: OcrPreprocessProfile.cameraDisplay,
        scanIntervalMs: 650,
        customPatterns: [
          CustomOcrPattern(
            id: 'p1',
            template: 'Wild {pokemon}!',
            eventType: ScannerEventType.encounter,
          ),
        ],
        liveFocusPreset: LiveFocusPreset.topLeft,
        ignoredPokemonIds: [25, 133],
        showScreenBorders: false,
        multiInstanceSlots: [],
      );

      await service.saveScannerSettings(saved);
      final loaded = await service.loadScannerSettings(
        base: ScannerSettings.defaults(),
      );

      expect(loaded.ocrLanguage, 'ja');
      expect(loaded.autoMarkCaught, isFalse);
      expect(loaded.trackEvolutions, isFalse);
      expect(loaded.livingDexEvolutionAction, LivingDexEvolutionAction.autoRemovePreEvolution);
      expect(loaded.detectShinies, isFalse);
      expect(loaded.detectAlphas, isFalse);
      expect(loaded.playAudioFeedback, isFalse);
      expect(loaded.playHapticFeedback, isFalse);
      expect(loaded.desktopOverlayMode, DesktopOverlayMode.floatingHud);
      expect(loaded.preprocessProfile, OcrPreprocessProfile.cameraDisplay);
      expect(loaded.scanIntervalMs, 650);
      expect(loaded.customPatterns, hasLength(1));
      expect(loaded.liveFocusPreset, LiveFocusPreset.topLeft);
      expect(loaded.ignoredPokemonIds, [25, 133]);
      expect(loaded.showScreenBorders, isFalse);
    });
  });
}
