import '../../models/pokemon.dart';
import 'engine/ocr_detection_engine.dart';
import 'engine/pokemon_fuzzy_matcher.dart';
import 'models/scanner_settings.dart';
import 'scanner_coordinator.dart';

/// Shared helper to construct a configured [ScannerCoordinator] from Dex entries
/// for both Desktop Tracker and Mobile Camera Tracker entry points.
class ScannerLauncherHelper {
  const ScannerLauncherHelper._();

  static ScannerCoordinator buildCoordinator(
    List<Pokemon> allPokemon, {
    ScannerSettings? settings,
  }) {
    final entries = <PokemonMatcherEntry>[];
    for (final p in allPokemon) {
      for (final entry in p.names.entries) {
        entries.add(
          PokemonMatcherEntry(
            id: p.id,
            name: entry.value,
            language: entry.key,
          ),
        );
      }
    }

    return ScannerCoordinator(
      engine: OcrDetectionEngine(),
      matcher: PokemonFuzzyMatcher.withEntries(entries),
      settings: settings ?? ScannerSettings.defaults(),
    );
  }
}
