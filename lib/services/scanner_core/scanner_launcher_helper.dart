import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../../models/pokemon.dart';
import '../../providers/settings_provider.dart';
import '../../screens/desktop_tracker/desktop_tracker_screen.dart';
import '../../screens/mobile_scanner/mobile_camera_tracker_screen.dart';
import '../../utils/tracker_platform_helper.dart';
import '../desktop_tracker/desktop_tracker_service.dart';
import '../mobile_scanner/mobile_camera_tracker_service.dart';
import 'engine/ocr_detection_engine.dart';
import 'engine/pokemon_fuzzy_matcher.dart';
import 'models/scanner_settings.dart';
import 'scanner_coordinator.dart';

/// Shared helper to construct [ScannerCoordinator] instances and launch
/// Desktop Overlay or Cross-Platform Webcam/Camera Tracker flows without
/// duplicating modal-chooser or session-resume logic across screens.
class ScannerLauncherHelper {
  const ScannerLauncherHelper._();

  static String _resolvePokemonLanguage(BuildContext context) {
    try {
      return Provider.of<SettingsProvider>(context, listen: false)
          .effectivePokemonLanguage;
    } catch (_) {
      return 'de';
    }
  }

  static ScannerCoordinator buildCoordinator(
    List<Pokemon> allPokemon, {
    ScannerSettings? settings,
    String? effectivePokemonLanguage,
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

    final coordinator = ScannerCoordinator(
      engine: OcrDetectionEngine(),
      matcher: PokemonFuzzyMatcher.withEntries(entries),
      settings: settings ?? ScannerSettings.defaults(),
    );
    if (effectivePokemonLanguage != null) {
      coordinator.setEffectiveOcrLanguage(effectivePokemonLanguage);
    }
    return coordinator;
  }

  /// Opens the unified Desktop & Webcam Tracker whenever running on Desktop/Web.
  static void openDesktopOverlayTracker(
    BuildContext context, {
    required List<Pokemon> allPokemon,
    String? dexId,
  }) {
    final supportedOnDesktopOrWeb = !TrackerPlatformHelper.isMobile &&
        (TrackerPlatformHelper.isDesktopOverlaySupported ||
            TrackerPlatformHelper.isCameraTrackerSupported);
    if (!supportedOnDesktopOrWeb) return;
    final existingService = DesktopTrackerService.instance;
    final canReuseService = existingService.coordinator != null &&
        existingService.isTrackingActive &&
        (existingService.windowSource == null ||
            !existingService.windowSource!.isDisposed);
    final effectiveLang = _resolvePokemonLanguage(context);
    final coordinator = canReuseService
        ? existingService.coordinator!
        : buildCoordinator(
            allPokemon,
            effectivePokemonLanguage: effectiveLang,
          );
    if (canReuseService) {
      coordinator.setEffectiveOcrLanguage(effectiveLang);
    }
    final reusableWindowSource =
        canReuseService ? existingService.windowSource : null;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DesktopTrackerScreen(
          coordinator: coordinator,
          windowSource: reusableWindowSource,
          initialDexId: dexId ?? existingService.activeDexId,
          keepTrackingInBackground: true,
        ),
      ),
    );
  }

  /// Opens the Mobile Camera Tracker on Android / iOS (or when invoked explicitly).
  static void openCameraTracker(
    BuildContext context, {
    required List<Pokemon> allPokemon,
    String? dexId,
  }) {
    if (!TrackerPlatformHelper.isCameraTrackerSupported) return;
    final mobileService = MobileCameraTrackerService.instance;
    final effectiveLang = _resolvePokemonLanguage(context);
    final canReuseMobile =
        mobileService.coordinator != null && mobileService.isTrackingActive;
    final coordinator = canReuseMobile
        ? mobileService.coordinator!
        : buildCoordinator(
            allPokemon,
            effectivePokemonLanguage: effectiveLang,
            settings: ScannerSettings.defaults().copyWith(
              preprocessProfile: OcrPreprocessProfile.cameraDisplay,
            ),
          );
    if (canReuseMobile) {
      coordinator.setEffectiveOcrLanguage(effectiveLang);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MobileCameraTrackerScreen(
          coordinator: coordinator,
          cameraSource: mobileService.cameraSource,
          initialDexId: dexId ?? mobileService.activeDexId,
        ),
      ),
    );
  }

  /// Opens the platform-appropriate tracker:
  /// - Desktop & Web (Windows, Linux, macOS, Web): unified DesktopTrackerScreen
  ///   (Windows also includes monitors/emulators + HUD; Web/Linux/macOS focus on Webcams & Photo-Scan)
  /// - Mobile (Android, iOS): full-screen MobileCameraTrackerScreen
  static void openPlatformTracker(
    BuildContext context, {
    required List<Pokemon> allPokemon,
    String? dexId,
  }) {
    if (!TrackerPlatformHelper.isMobile &&
        (TrackerPlatformHelper.isDesktopOverlaySupported ||
            TrackerPlatformHelper.isCameraTrackerSupported)) {
      openDesktopOverlayTracker(context, allPokemon: allPokemon, dexId: dexId);
      return;
    }

    if (TrackerPlatformHelper.isCameraTrackerSupported) {
      openCameraTracker(context, allPokemon: allPokemon, dexId: dexId);
    }
  }
}
