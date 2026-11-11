/// Behavior for Living Dex when an evolution is recognized.
enum LivingDexEvolutionAction {
  askBeforeRemoving,
  autoRemovePreEvolution,
  keepPreEvolution,
}

/// Display and interaction mode for the desktop overlay.
enum DesktopOverlayMode {
  floatingHud,
  clickThroughOverlay,
  silentBackground,
}

/// User configurable settings for OCR detection, overlay presentation, and feedback.
class ScannerSettings {
  final bool autoMarkCaught;
  final bool trackEvolutions;
  final LivingDexEvolutionAction livingDexEvolutionAction;
  final bool detectShinies;
  final bool detectAlphas;
  final bool playAudioFeedback;
  final bool playHapticFeedback;
  final DesktopOverlayMode desktopOverlayMode;
  final String ocrLanguage;

  const ScannerSettings({
    this.autoMarkCaught = true,
    this.trackEvolutions = true,
    this.livingDexEvolutionAction = LivingDexEvolutionAction.askBeforeRemoving,
    this.detectShinies = true,
    this.detectAlphas = true,
    this.playAudioFeedback = true,
    this.playHapticFeedback = true,
    this.desktopOverlayMode = DesktopOverlayMode.floatingHud,
    this.ocrLanguage = 'auto',
  });

  factory ScannerSettings.defaults() => const ScannerSettings();

  ScannerSettings copyWith({
    bool? autoMarkCaught,
    bool? trackEvolutions,
    LivingDexEvolutionAction? livingDexEvolutionAction,
    bool? detectShinies,
    bool? detectAlphas,
    bool? playAudioFeedback,
    bool? playHapticFeedback,
    DesktopOverlayMode? desktopOverlayMode,
    String? ocrLanguage,
  }) {
    return ScannerSettings(
      autoMarkCaught: autoMarkCaught ?? this.autoMarkCaught,
      trackEvolutions: trackEvolutions ?? this.trackEvolutions,
      livingDexEvolutionAction:
          livingDexEvolutionAction ?? this.livingDexEvolutionAction,
      detectShinies: detectShinies ?? this.detectShinies,
      detectAlphas: detectAlphas ?? this.detectAlphas,
      playAudioFeedback: playAudioFeedback ?? this.playAudioFeedback,
      playHapticFeedback: playHapticFeedback ?? this.playHapticFeedback,
      desktopOverlayMode: desktopOverlayMode ?? this.desktopOverlayMode,
      ocrLanguage: ocrLanguage ?? this.ocrLanguage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'autoMarkCaught': autoMarkCaught,
      'trackEvolutions': trackEvolutions,
      'livingDexEvolutionAction': livingDexEvolutionAction.name,
      'detectShinies': detectShinies,
      'detectAlphas': detectAlphas,
      'playAudioFeedback': playAudioFeedback,
      'playHapticFeedback': playHapticFeedback,
      'desktopOverlayMode': desktopOverlayMode.name,
      'ocrLanguage': ocrLanguage,
    };
  }

  factory ScannerSettings.fromMap(Map<String, dynamic> map) {
    LivingDexEvolutionAction action = LivingDexEvolutionAction.askBeforeRemoving;
    final actionStr = map['livingDexEvolutionAction']?.toString();
    if (actionStr != null) {
      for (final a in LivingDexEvolutionAction.values) {
        if (a.name == actionStr) {
          action = a;
          break;
        }
      }
    }

    DesktopOverlayMode mode = DesktopOverlayMode.floatingHud;
    final modeStr = map['desktopOverlayMode']?.toString();
    if (modeStr != null) {
      for (final m in DesktopOverlayMode.values) {
        if (m.name == modeStr) {
          mode = m;
          break;
        }
      }
    }

    return ScannerSettings(
      autoMarkCaught: map['autoMarkCaught'] as bool? ?? true,
      trackEvolutions: map['trackEvolutions'] as bool? ?? true,
      livingDexEvolutionAction: action,
      detectShinies: map['detectShinies'] as bool? ?? true,
      detectAlphas: map['detectAlphas'] as bool? ?? true,
      playAudioFeedback: map['playAudioFeedback'] as bool? ?? true,
      playHapticFeedback: map['playHapticFeedback'] as bool? ?? true,
      desktopOverlayMode: mode,
      ocrLanguage: map['ocrLanguage']?.toString() ?? 'auto',
    );
  }
}
