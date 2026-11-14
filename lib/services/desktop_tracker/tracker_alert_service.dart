import 'dart:async';
import '../scanner_core/models/scanner_event.dart';

/// Configuration options for audio, visual and haptic feedback alerts.
class TrackerAlertSettings {
  final bool soundEnabled;
  final bool soundOnShiny;
  final bool soundOnAlpha;
  final bool soundOnNormal;
  final bool visualGlowEnabled;
  final bool hapticEnabled;

  const TrackerAlertSettings({
    this.soundEnabled = true,
    this.soundOnShiny = true,
    this.soundOnAlpha = true,
    this.soundOnNormal = false,
    this.visualGlowEnabled = true,
    this.hapticEnabled = true,
  });

  factory TrackerAlertSettings.defaults() {
    return const TrackerAlertSettings();
  }

  TrackerAlertSettings copyWith({
    bool? soundEnabled,
    bool? soundOnShiny,
    bool? soundOnAlpha,
    bool? soundOnNormal,
    bool? visualGlowEnabled,
    bool? hapticEnabled,
  }) {
    return TrackerAlertSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      soundOnShiny: soundOnShiny ?? this.soundOnShiny,
      soundOnAlpha: soundOnAlpha ?? this.soundOnAlpha,
      soundOnNormal: soundOnNormal ?? this.soundOnNormal,
      visualGlowEnabled: visualGlowEnabled ?? this.visualGlowEnabled,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'soundEnabled': soundEnabled,
      'soundOnShiny': soundOnShiny,
      'soundOnAlpha': soundOnAlpha,
      'soundOnNormal': soundOnNormal,
      'visualGlowEnabled': visualGlowEnabled,
      'hapticEnabled': hapticEnabled,
    };
  }

  factory TrackerAlertSettings.fromMap(Map<String, dynamic> map) {
    return TrackerAlertSettings(
      soundEnabled: map['soundEnabled'] as bool? ?? true,
      soundOnShiny: map['soundOnShiny'] as bool? ?? true,
      soundOnAlpha: map['soundOnAlpha'] as bool? ?? true,
      soundOnNormal: map['soundOnNormal'] as bool? ?? false,
      visualGlowEnabled: map['visualGlowEnabled'] as bool? ?? true,
      hapticEnabled: map['hapticEnabled'] as bool? ?? true,
    );
  }
}

/// Service managing optical, acoustic and haptic alert dispatching when scanner events occur.
class TrackerAlertService {
  TrackerAlertSettings _settings;
  final void Function(String soundType)? soundPlayer;
  final void Function(String alertType)? visualAlertHandler;

  final StreamController<String> _visualAlertController =
      StreamController<String>.broadcast();

  TrackerAlertService({
    TrackerAlertSettings? settings,
    this.soundPlayer,
    this.visualAlertHandler,
  }) : _settings = settings ?? const TrackerAlertSettings();

  TrackerAlertSettings get settings => _settings;

  Stream<String> get visualAlertStream => _visualAlertController.stream;

  void updateSettings(TrackerAlertSettings newSettings) {
    _settings = newSettings;
  }

  /// Dispatches audio and visual alerts according to the configured preferences.
  void handleEvent(ScannerEvent event) {
    if (event.isShiny) {
      _triggerAlert('shiny');
    } else if (event.isAlpha) {
      _triggerAlert('alpha');
    } else if (_settings.soundOnNormal) {
      _triggerAlert('normal');
    }
  }

  void _triggerAlert(String type) {
    // Optical alert
    if (_settings.visualGlowEnabled) {
      visualAlertHandler?.call(type);
      _visualAlertController.add(type);
    }

    // Sound alert
    if (_settings.soundEnabled) {
      if (type == 'shiny' && _settings.soundOnShiny) {
        soundPlayer?.call('shiny');
      } else if (type == 'alpha' && _settings.soundOnAlpha) {
        soundPlayer?.call('alpha');
      } else if (type == 'normal' && _settings.soundOnNormal) {
        soundPlayer?.call('normal');
      }
    }
  }

  void dispose() {
    _visualAlertController.close();
  }
}
