import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokevault/services/desktop_tracker/screen_region.dart';
import 'package:pokevault/services/scanner_core/models/scanner_event.dart';
import 'package:pokevault/services/scanner_core/models/scanner_settings.dart';
import 'package:pokevault/services/scanner_core/scanner_persistence_service.dart';

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
      expect(corrupted.scanIntervalMs, 400);
      expect(corrupted.customPatterns, isEmpty);
    });

    test('ScannerSettings scanIntervalMs and CustomOcrPattern roundtrip + clamping', () {
      const pattern = CustomOcrPattern(
        id: 'pat_1',
        template: 'Klasse! {pokemon}',
        eventType: ScannerEventType.caught,
        enabled: true,
      );
      final updatedPattern = pattern.copyWith(enabled: false);
      expect(updatedPattern.enabled, isFalse);

      final settings = ScannerSettings(
        scanIntervalMs: 250,
        customPatterns: [pattern, updatedPattern],
      );
      expect(settings.scanIntervalMs, 250);
      expect(settings.customPatterns, hasLength(2));

      final roundtrip = ScannerSettings.fromMap(settings.toMap());
      expect(roundtrip.scanIntervalMs, 250);
      expect(roundtrip.customPatterns, hasLength(2));
      expect(roundtrip.customPatterns.first.template, 'Klasse! {pokemon}');
      expect(roundtrip.customPatterns.first.eventType, ScannerEventType.caught);
      expect(roundtrip.customPatterns.last.enabled, isFalse);

      // Clamp extreme intervals to safe bounds [150, 5000]
      expect(ScannerSettings.fromMap({'scanIntervalMs': 10}).scanIntervalMs, 150);
      expect(ScannerSettings.fromMap({'scanIntervalMs': 99999}).scanIntervalMs, 5000);
    });

    test('OcrPreprocessProfile roundtrips and ScannerPersistenceService persists settings via SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final service = ScannerPersistenceService();

      final initial = await service.loadScannerSettings();
      expect(initial.preprocessProfile, OcrPreprocessProfile.standard);
      expect(initial.scanIntervalMs, 400);
      expect(initial.customPatterns, isEmpty);

      final toSave = initial.copyWith(
        scanIntervalMs: 250,
        preprocessProfile: OcrPreprocessProfile.pixelArtDs,
        customPatterns: const [
          CustomOcrPattern(
            id: 'p_ds',
            template: 'Klasse! {pokemon}',
            eventType: ScannerEventType.caught,
            enabled: true,
          ),
        ],
      );
      await service.saveScannerSettings(toSave);

      final loaded = await service.loadScannerSettings();
      expect(loaded.scanIntervalMs, 250);
      expect(loaded.preprocessProfile, OcrPreprocessProfile.pixelArtDs);
      expect(loaded.customPatterns, hasLength(1));
      expect(loaded.customPatterns.first.template, 'Klasse! {pokemon}');

      final corruptedProfile = ScannerSettings.fromMap({'preprocessProfile': 'unknown_mode'});
      expect(corruptedProfile.preprocessProfile, OcrPreprocessProfile.standard);
    });

    test('LiveFocusPreset and ignoredPokemonIds roundtrip, persist, and fall back safely', () async {
      SharedPreferences.setMockInitialValues({});
      final service = ScannerPersistenceService();

      final initial = await service.loadScannerSettings();
      expect(initial.liveFocusPreset, LiveFocusPreset.disabled);
      expect(initial.ignoredPokemonIds, isEmpty);

      final updated = initial.copyWith(
        liveFocusPreset: LiveFocusPreset.topRight,
        ignoredPokemonIds: const [497, 500],
      );
      expect(updated.liveFocusPreset, LiveFocusPreset.topRight);
      expect(updated.ignoredPokemonIds, const [497, 500]);

      await service.saveScannerSettings(updated);
      final reloaded = await service.loadScannerSettings();
      expect(reloaded.liveFocusPreset, LiveFocusPreset.topRight);
      expect(reloaded.ignoredPokemonIds, const [497, 500]);

      final corrupted = ScannerSettings.fromMap({
        'liveFocusPreset': 'non_existent_preset',
        'ignoredPokemonIds': ['invalid', 497, '503', -1],
      });
      expect(corrupted.liveFocusPreset, LiveFocusPreset.disabled);
      expect(corrupted.ignoredPokemonIds, const [497, 503]);
    });

    test('showScreenBorders and multiInstanceSlots persist cleanly + splitRegionIntoGrid generates valid slots', () async {
      SharedPreferences.setMockInitialValues({});
      final service = ScannerPersistenceService();

      final initial = await service.loadScannerSettings();
      expect(initial.showScreenBorders, isTrue);
      expect(initial.multiInstanceSlots, isEmpty);

      final bigRegion = ScreenRegion(
        x: 100,
        y: 50,
        width: 800,
        height: 600,
        isAbsoluteScreen: true,
      );
      final gridSlots = MultiInstanceGridHelper.splitRegionIntoGrid(
        bigRegion,
        rows: 2,
        cols: 2,
      );
      expect(gridSlots, hasLength(4));
      expect(gridSlots[0].id, 1);
      expect(gridSlots[0].region.x, 100);
      expect(gridSlots[0].region.y, 50);
      expect(gridSlots[0].region.width, 400);
      expect(gridSlots[0].region.height, 300);
      expect(gridSlots[3].id, 4);
      expect(gridSlots[3].region.x, 500);
      expect(gridSlots[3].region.y, 350);

      final savedSettings = initial.copyWith(
        showScreenBorders: false,
        multiInstanceSlots: gridSlots,
      );
      await service.saveScannerSettings(savedSettings);
      final reloaded = await service.loadScannerSettings();
      expect(reloaded.showScreenBorders, isFalse);
      expect(reloaded.multiInstanceSlots, hasLength(4));
      expect(reloaded.multiInstanceSlots[1].region.x, 500);
      expect(reloaded.multiInstanceSlots[1].colorHex, gridSlots[1].colorHex);
    });

    test('Coupled MultiInstanceSlot supports scan-only, focus-only, paired Scan+Focus, and open window binding', () async {
      SharedPreferences.setMockInitialValues({});
      final service = ScannerPersistenceService();

      final slot2Coupled = MultiInstanceSlot(
        id: 2,
        label: '#2',
        colorHex: 0xFFA855F7,
        scanEnabled: true,
        scanRegion: ScreenRegion(x: 100, y: 400, width: 420, height: 110, isAbsoluteScreen: true, label: 'Scan #2'),
        focusPreset: LiveFocusPreset.customRegion,
        focusRegion: ScreenRegion(x: 120, y: 120, width: 220, height: 65, isAbsoluteScreen: true, label: 'Fokus #2'),
      );
      final slot3FocusOnly = MultiInstanceSlot(
        id: 3,
        label: '#3',
        colorHex: 0xFFEC4899,
        scanEnabled: false,
        scanRegion: null,
        focusPreset: LiveFocusPreset.customRegion,
        focusRegion: ScreenRegion(x: 800, y: 120, width: 220, height: 65, isAbsoluteScreen: true, label: 'Fokus #3'),
      );
      const slot4WindowBound = MultiInstanceSlot(
        id: 4,
        label: '#4',
        colorHex: 0xFFF59E0B,
        windowHwnd: 998877,
        windowId: 404,
        windowTitle: 'melonDS #2',
        scanPreset: ScanRegionPreset.bottomDialogue,
        focusPreset: LiveFocusPreset.topLeft,
        scanEnabled: true,
      );

      expect(slot2Coupled.hasScan, isTrue);
      expect(slot2Coupled.hasFocus, isTrue);
      expect(slot3FocusOnly.hasScan, isFalse);
      expect(slot3FocusOnly.hasFocus, isTrue);
      expect(slot4WindowBound.hasScan, isTrue);
      expect(slot4WindowBound.hasFocus, isTrue);

      await service.saveScannerSettings(
        ScannerSettings.defaults().copyWith(
          multiInstanceSlots: [slot2Coupled, slot3FocusOnly, slot4WindowBound],
        ),
      );
      final reloaded = await service.loadScannerSettings();
      expect(reloaded.multiInstanceSlots, hasLength(3));
      expect(reloaded.multiInstanceSlots[0].scanRegion?.x, 100);
      expect(reloaded.multiInstanceSlots[0].focusRegion?.x, 120);
      expect(reloaded.multiInstanceSlots[1].scanEnabled, isFalse);
      expect(reloaded.multiInstanceSlots[1].hasScan, isFalse);
      expect(reloaded.multiInstanceSlots[1].hasFocus, isTrue);
      expect(reloaded.multiInstanceSlots[2].windowHwnd, 998877);
      expect(reloaded.multiInstanceSlots[2].windowTitle, 'melonDS #2');
      expect(reloaded.multiInstanceSlots[2].scanPreset, ScanRegionPreset.bottomDialogue);
      expect(reloaded.multiInstanceSlots[2].focusPreset, LiveFocusPreset.topLeft);
    });
  });
}
