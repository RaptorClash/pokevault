import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/services/desktop_tracker/tracker_alert_service.dart';
import 'package:pokevault/services/scanner_core/models/scanner_event.dart';

void main() {
  group('TrackerAlertService Tests (TDD)', () {
    late TrackerAlertService service;
    late List<String> playedSounds;
    late List<String> visualAlerts;

    setUp(() {
      playedSounds = [];
      visualAlerts = [];
      service = TrackerAlertService(
        soundPlayer: (type) => playedSounds.add(type),
        visualAlertHandler: (type) => visualAlerts.add(type),
        settings: const TrackerAlertSettings(
          soundEnabled: true,
          soundOnShiny: true,
          soundOnAlpha: true,
          soundOnNormal: false,
          visualGlowEnabled: true,
        ),
      );
    });

    test('Plays shiny alert and triggers visual glow when shiny pokemon is detected', () async {
      final event = ScannerEvent(
        type: ScannerEventType.encounter,
        matchedName: 'Glumanda',
        pokemonId: 4,
        isShiny: true,
        rawText: 'Ein wildes schillerndes Glumanda erscheint!',
        timestamp: DateTime.now(),
      );

      service.handleEvent(event);

      expect(playedSounds, contains('shiny'));
      expect(visualAlerts, contains('shiny'));
    });

    test('Plays alpha alert when alpha pokemon is detected', () async {
      final event = ScannerEvent(
        type: ScannerEventType.encounter,
        matchedName: 'Knakrack',
        pokemonId: 445,
        isAlpha: true,
        rawText: 'Ein wildes Alpha-Knakrack greift an!',
        timestamp: DateTime.now(),
      );

      service.handleEvent(event);

      expect(playedSounds, contains('alpha'));
      expect(visualAlerts, contains('alpha'));
    });

    test('Does not play sound for normal encounter if soundOnNormal is false', () async {
      final event = ScannerEvent(
        type: ScannerEventType.encounter,
        matchedName: 'Taubsi',
        pokemonId: 16,
        isShiny: false,
        isAlpha: false,
        rawText: 'Ein wildes Taubsi erscheint!',
        timestamp: DateTime.now(),
      );

      service.handleEvent(event);

      expect(playedSounds, isEmpty);
      expect(visualAlerts, isEmpty);
    });

    test('Respects global soundEnabled toggle (disables all sounds when false)', () async {
      service.updateSettings(service.settings.copyWith(soundEnabled: false));

      final shinyEvent = ScannerEvent(
        type: ScannerEventType.encounter,
        matchedName: 'Glumanda',
        isShiny: true,
        rawText: 'schillerndes Glumanda',
        timestamp: DateTime.now(),
      );

      service.handleEvent(shinyEvent);

      expect(playedSounds, isEmpty);
      // Visual alert should still fire if visualGlowEnabled is true
      expect(visualAlerts, contains('shiny'));
    });

    test('Settings serialization and copyWith works properly', () {
      final defaults = TrackerAlertSettings.defaults();
      expect(defaults.soundEnabled, isTrue);
      expect(defaults.soundOnShiny, isTrue);

      final copy = defaults.copyWith(soundOnNormal: true);
      expect(copy.soundOnNormal, isTrue);

      final map = copy.toMap();
      final fromMap = TrackerAlertSettings.fromMap(map);
      expect(fromMap.soundOnNormal, isTrue);
      expect(fromMap.soundOnShiny, isTrue);
    });
  });
}
