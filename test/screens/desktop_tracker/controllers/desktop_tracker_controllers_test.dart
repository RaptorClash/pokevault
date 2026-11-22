import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/screens/desktop_tracker/controllers/desktop_tracker_dex_controller.dart';
import 'package:pokevault/screens/desktop_tracker/controllers/desktop_tracker_zones_controller.dart';
import 'package:pokevault/services/desktop_tracker/screen_region.dart';
import 'package:pokevault/services/desktop_tracker/window_detector.dart';
import 'package:pokevault/services/scanner_core/models/scanner_event.dart';
import 'package:pokevault/services/scanner_core/models/scanner_settings.dart';

class _MockDexProvider extends Mock implements DexProvider {}

class _FakeUserDex extends Fake implements UserDex {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeUserDex());
  });

  group('DesktopTrackerZonesController (TDD)', () {
    const emulatorWin = DesktopWindowInfo(
      id: 10,
      hwnd: 10,
      title: 'mGBA - Smaragd',
      processName: 'mGBA.exe',
      bounds: Rect.fromLTWH(100, 200, 800, 600),
    );

    const desktopScreen = DesktopWindowInfo(
      id: 1,
      hwnd: 0,
      title: 'Desktop / Screen',
      processName: 'explorer.exe',
      isDesktopScreen: true,
      bounds: Rect.fromLTWH(0, 0, 1920, 1080),
    );

    test('resolveAbsoluteZoneARegion prefers customScreenRegion and handles bounds', () {
      final custom = ScreenRegion(
        x: 50,
        y: 60,
        width: 300,
        height: 120,
        isAbsoluteScreen: true,
        label: 'Custom',
      );
      expect(
        DesktopTrackerZonesController.resolveAbsoluteZoneARegion(
          selectedWindow: emulatorWin,
          customScreenRegion: custom,
          cropRegion: const Rect.fromLTWH(10, 20, 400, 150),
        ),
        equals(custom),
      );

      final presetRegion =
          DesktopTrackerZonesController.resolveAbsoluteZoneARegion(
        selectedWindow: emulatorWin,
        customScreenRegion: null,
        cropRegion: const Rect.fromLTWH(10, 20, 400, 150),
      );
      expect(presetRegion, isNotNull);
      expect(presetRegion!.isAbsoluteScreen, isTrue);
      expect(presetRegion.x, 110);
      expect(presetRegion.y, 220);

      expect(
        DesktopTrackerZonesController.resolveAbsoluteZoneARegion(
          selectedWindow: desktopScreen,
          customScreenRegion: null,
          cropRegion: const Rect.fromLTWH(10, 20, 400, 150),
        ),
        isNull,
      );
    });

    test('resolveAbsoluteZoneBRegion resolves disabled, customRegion, and preset', () {
      expect(
        DesktopTrackerZonesController.resolveAbsoluteZoneBRegion(
          selectedWindow: emulatorWin,
          liveFocusPreset: LiveFocusPreset.disabled,
          liveFocusScreenRegion: null,
        ),
        isNull,
      );

      final customFocus = ScreenRegion(
        x: 400,
        y: 250,
        width: 240,
        height: 80,
        isAbsoluteScreen: true,
      );
      expect(
        DesktopTrackerZonesController.resolveAbsoluteZoneBRegion(
          selectedWindow: emulatorWin,
          liveFocusPreset: LiveFocusPreset.customRegion,
          liveFocusScreenRegion: customFocus,
        ),
        equals(customFocus),
      );

      final mapped = DesktopTrackerZonesController.resolveAbsoluteZoneBRegion(
        selectedWindow: emulatorWin,
        liveFocusPreset: LiveFocusPreset.topRight,
        liveFocusScreenRegion: null,
      );
      expect(mapped, isNotNull);
      expect(mapped!.x, greaterThanOrEqualTo(100));
    });

    test('computeOverlayBorderSpecs respects showScreenBorders and multi-instance slots', () {
      expect(
        DesktopTrackerZonesController.computeOverlayBorderSpecs(
          showScreenBorders: false,
          selectedWindow: emulatorWin,
          customScreenRegion: null,
          cropRegion: const Rect.fromLTWH(0, 400, 800, 200),
          isScanningActive: true,
          liveFocusPreset: LiveFocusPreset.topRight,
          liveFocusScreenRegion: null,
          multiInstanceSlots: const [],
          windows: const [emulatorWin],
        ),
        isEmpty,
      );

      final slotRegion = ScreenRegion(
        x: 20,
        y: 20,
        width: 200,
        height: 80,
        isAbsoluteScreen: true,
      );
      final specs = DesktopTrackerZonesController.computeOverlayBorderSpecs(
        showScreenBorders: true,
        selectedWindow: emulatorWin,
        customScreenRegion: null,
        cropRegion: const Rect.fromLTWH(0, 400, 800, 200),
        isScanningActive: true,
        liveFocusPreset: LiveFocusPreset.topRight,
        liveFocusScreenRegion: null,
        multiInstanceSlots: [
          MultiInstanceSlot(
            id: 1,
            label: 'Smaragd',
            colorHex: 0xFFA855F7,
            scanRegion: slotRegion,
          ),
        ],
        windows: const [emulatorWin],
      );
      expect(specs.any((s) => s.id == 'zone_a'), isTrue);
      expect(specs.any((s) => s.id == 'zone_b'), isTrue);
      expect(specs.any((s) => s.id == 'multi_1_scan'), isTrue);
    });

    test('multi-instance CRUD adds up to 4 slots, applies region, updates, removes, and clears', () {
      var slots = <MultiInstanceSlot>[];
      for (var i = 0; i < 6; i++) {
        slots = DesktopTrackerZonesController.addMultiInstanceSlot(
          slots,
          maxSlots: 4,
        );
      }
      expect(slots.length, 4);

      final region = ScreenRegion(
        x: 15,
        y: 25,
        width: 120,
        height: 45,
        isAbsoluteScreen: true,
      );
      slots = DesktopTrackerZonesController.applyMultiSlotRegion(
        slots,
        slots.first.id,
        region,
        isFocus: true,
      );
      expect(slots.first.focusPreset, LiveFocusPreset.customRegion);
      expect(slots.first.focusRegion?.width, 120);

      slots = DesktopTrackerZonesController.removeMultiInstanceSlot(
        slots,
        slots.first.id,
      );
      expect(slots.length, 3);
    });
  });

  group('DesktopTrackerDexController (TDD)', () {
    late _MockDexProvider mockDexProvider;
    late UserDex dexA;
    late UserDex dexB;

    setUp(() {
      mockDexProvider = _MockDexProvider();
      dexA = UserDex(
        id: 'dex_a',
        title: 'Kanto',
        region: 'kanto',
        isShinyDex: false,
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        caughtIds: ['1'],
        shinyIds: [],
        alphaIds: [],
      );
      dexB = UserDex(
        id: 'dex_b',
        title: 'Shiny Johto',
        region: 'johto',
        isShinyDex: true,
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        caughtIds: [],
      );

      when(() => mockDexProvider.userDexes).thenReturn([dexA, dexB]);
      when(() => mockDexProvider.allPokemon).thenReturn(<Pokemon>[]);
      when(() => mockDexProvider.saveUserDexAndSync(any()))
          .thenAnswer((_) async {});
    });

    test('resolveTargetDex returns matching dex or falls back to first', () {
      expect(
        DesktopTrackerDexController.resolveTargetDex(mockDexProvider, 'dex_b')
            ?.id,
        'dex_b',
      );
      expect(
        DesktopTrackerDexController.resolveTargetDex(mockDexProvider, 'missing')
            ?.id,
        'dex_a',
      );
    });

    test('persistCaughtStatus records caught, shiny, alpha cleanly and avoids redundant saves', () async {
      final changed = await DesktopTrackerDexController.persistCaughtStatus(
        mockDexProvider,
        dexA,
        25,
        isShiny: true,
        isAlpha: true,
      );
      expect(changed, isTrue);
      expect(dexA.caughtIds, contains('25'));
      expect(dexA.shinyIds, contains('25'));
      expect(dexA.alphaIds, contains('25'));
      verify(() => mockDexProvider.saveUserDexAndSync(dexA)).called(1);

      final changedAgain = await DesktopTrackerDexController.persistCaughtStatus(
        mockDexProvider,
        dexA,
        25,
        isShiny: true,
        isAlpha: true,
        skipSaveIfUnchanged: true,
      );
      expect(changedAgain, isFalse);
      verifyNever(() => mockDexProvider.saveUserDexAndSync(dexA));
    });

    test('correctEventAt rolls back old pokemon if no other caught event exists', () async {
      dexA.caughtIds.add('25');
      final events = <ScannerEvent>[
        ScannerEvent(
          type: ScannerEventType.caught,
          matchedName: 'Pikachu',
          pokemonId: 25,
          rawText: 'Pikachu gefangen!',
          timestamp: DateTime.now(),
          autoAddedCaught: true,
        ),
      ];

      final corrected = await DesktopTrackerDexController.correctEventAt(
        events: events,
        index: 0,
        newPokemonId: 4,
        newPokemonName: 'Glumanda',
        dexProvider: mockDexProvider,
        targetDex: dexA,
        autoMarkCaught: true,
      );

      expect(corrected.matchedName, 'Glumanda');
      expect(corrected.pokemonId, 4);
      expect(dexA.caughtIds, isNot(contains('25')));
      expect(dexA.caughtIds, contains('4'));
    });

    test('deleteEventAt preserves caught flag if another caught event exists for same pokemon', () async {
      dexA.caughtIds.add('25');
      final events = <ScannerEvent>[
        ScannerEvent(
          type: ScannerEventType.caught,
          matchedName: 'Pikachu',
          pokemonId: 25,
          rawText: 'Pikachu #1',
          timestamp: DateTime.now(),
          autoAddedCaught: true,
        ),
        ScannerEvent(
          type: ScannerEventType.caught,
          matchedName: 'Pikachu',
          pokemonId: 25,
          rawText: 'Pikachu #2',
          timestamp: DateTime.now(),
          autoAddedCaught: true,
        ),
      ];

      await DesktopTrackerDexController.deleteEventAt(
        events: events,
        index: 0,
        dexProvider: mockDexProvider,
        targetDex: dexA,
      );

      expect(events.length, 1);
      expect(dexA.caughtIds, contains('25'));
    });

    test('prepareIncomingEvent computes autoAdded flags consistently for desktop and mobile', () {
      final newCatch = ScannerEvent(
        type: ScannerEventType.caught,
        matchedName: 'Pikachu',
        pokemonId: 25,
        isShiny: true,
        isAlpha: true,
        rawText: 'Pikachu wurde gefangen!',
        timestamp: DateTime.now(),
      );
      final preparedNew = DesktopTrackerDexController.prepareIncomingEvent(
        newCatch,
        targetDex: dexA,
        autoMarkCaught: true,
      );
      expect(preparedNew.autoAddedCaught, isTrue);
      expect(preparedNew.autoAddedShiny, isTrue);
      expect(preparedNew.autoAddedAlpha, isTrue);

      // Already caught in dexA ('1'), shiny/alpha not yet present
      final existingCatch = ScannerEvent(
        type: ScannerEventType.caught,
        matchedName: 'Bisasam',
        pokemonId: 1,
        isShiny: true,
        isAlpha: false,
        rawText: 'Bisasam wurde gefangen!',
        timestamp: DateTime.now(),
      );
      final preparedExisting = DesktopTrackerDexController.prepareIncomingEvent(
        existingCatch,
        targetDex: dexA,
        autoMarkCaught: true,
      );
      expect(preparedExisting.autoAddedCaught, isFalse);
      expect(preparedExisting.autoAddedShiny, isTrue);
      expect(preparedExisting.autoAddedAlpha, isFalse);

      // Disabled autoMark or encounter event leaves flags untouched
      final preparedDisabled = DesktopTrackerDexController.prepareIncomingEvent(
        newCatch,
        targetDex: dexA,
        autoMarkCaught: false,
      );
      expect(preparedDisabled.autoAddedCaught, isFalse);
      expect(preparedDisabled.autoAddedShiny, isFalse);
    });

    test('refreshEvolutionStatusFor routes updates through custom onSyncServiceStatus callback', () {
      final controller = DesktopTrackerDexController();
      final synced = <Object?>[];
      final statusChanges = <Object?>[];

      final bulba = Pokemon(
        id: 1,
        nameDe: 'Bisasam',
        nameEn: 'Bulbasaur',
        hasGenderDifferences: false,
        genderRate: 1,
        captureRate: 45,
        evolutionChainId: -1,
        eggGroups: const ['Monster'],
        weight: 6.9,
        speed: 45,
        forms: const [],
      );
      when(() => mockDexProvider.allPokemon).thenReturn([bulba]);

      controller.refreshEvolutionStatusFor(
        event: ScannerEvent(
          type: ScannerEventType.encounter,
          matchedName: 'Bisasam',
          pokemonId: 1,
          rawText: 'Bisasam',
          timestamp: DateTime.now(),
        ),
        activeDex: dexA,
        dexProvider: mockDexProvider,
        languageCode: 'de',
        isMounted: () => true,
        onStatusChanged: statusChanges.add,
        onSyncServiceStatus: synced.add,
      );

      expect(statusChanges, [null]);
      expect(synced, [null]);
    });
  });

  group('DesktopTrackerZonesController Extra Focus Boxes (TDD)', () {
    test('computeOverlayBorderSpecs emits cyan Focus B1, B2, B3 borders when extraFocusRegions are configured', () {
      const win = DesktopWindowInfo(
        id: 77,
        title: 'melonDS',
        bounds: Rect.fromLTWH(0, 0, 800, 600),
      );
      final b1 = ScreenRegion(x: 40, y: 40, width: 180, height: 60, isAbsoluteScreen: true);
      final b2 = ScreenRegion(x: 340, y: 40, width: 180, height: 60, isAbsoluteScreen: true);

      final specs = DesktopTrackerZonesController.computeOverlayBorderSpecs(
        showScreenBorders: true,
        selectedWindow: win,
        customScreenRegion: null,
        cropRegion: null,
        isScanningActive: true,
        liveFocusPreset: LiveFocusPreset.customRegion,
        liveFocusScreenRegion: b1,
        extraFocusRegions: [b2],
        multiInstanceSlots: const [],
        windows: const [win],
      );

      final focusBorders = specs.where((s) => s.id.startsWith('zone_b')).toList();
      expect(focusBorders, hasLength(2));
      expect(focusBorders[0].label, 'Fokus B1');
      expect(focusBorders[1].label, 'Fokus B2');
      expect(focusBorders[1].colorArgb, 0xFF06B6D4);
    });
  });
}
