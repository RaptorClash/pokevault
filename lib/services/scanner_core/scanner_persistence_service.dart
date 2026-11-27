import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/scanner_settings.dart';

/// Persists reusable OCR scanner settings (interval, preprocess profile, custom patterns)
/// across both Desktop Tracker and future Camera Scanner sessions.
class ScannerPersistenceService {
  static const String _settingsStorageKey = 'pokevault_scanner_settings_v1';

  Future<ScannerSettings> loadScannerSettings({ScannerSettings? base}) async {
    final fallback = base ?? ScannerSettings.defaults();
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(_settingsStorageKey);
      if (rawJson == null || rawJson.trim().isEmpty) {
        return fallback;
      }
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map) {
        return fallback;
      }
      final persisted = ScannerSettings.fromMap(Map<String, dynamic>.from(decoded));
      return fallback.copyWith(
        autoMarkCaught: persisted.autoMarkCaught,
        trackEvolutions: persisted.trackEvolutions,
        livingDexEvolutionAction: persisted.livingDexEvolutionAction,
        detectShinies: persisted.detectShinies,
        detectAlphas: persisted.detectAlphas,
        playAudioFeedback: persisted.playAudioFeedback,
        playHapticFeedback: persisted.playHapticFeedback,
        desktopOverlayMode: persisted.desktopOverlayMode,
        ocrLanguage: persisted.ocrLanguage,
        scanIntervalMs: persisted.scanIntervalMs,
        preprocessProfile: persisted.preprocessProfile,
        customPatterns: persisted.customPatterns,
        liveFocusPreset: persisted.liveFocusPreset,
        ignoredPokemonIds: persisted.ignoredPokemonIds,
        showScreenBorders: persisted.showScreenBorders,
        multiInstanceSlots: persisted.multiInstanceSlots,
        extraFocusRegions: persisted.extraFocusRegions,
        maskSelfWindow: persisted.maskSelfWindow,
        suppressSelfScanWarning: persisted.suppressSelfScanWarning,
      );
    } catch (_) {
      return fallback;
    }
  }

  Future<void> saveScannerSettings(ScannerSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_settingsStorageKey, jsonEncode(settings.toMap()));
    } catch (_) {
      // Non-fatal in headless test environments without platform channels
    }
  }
}
