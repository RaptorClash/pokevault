import 'package:flutter/material.dart';

/// The 4 design styles available for the Living Dex Completion Card.
enum DexCardStyle {
  /// Infographic dashboard with circular progress gauge, KPI cards for Shinies/Alphas/Boxes,
  /// generation breakdown bars, and type coverage pills.
  analyst,

  /// Official diploma layout with golden frame, 4-pillar stat table, Champion seal, and timestamp.
  certificate,

  /// Visual grid heatmap showing every slot in the dex (green=caught, gold=shiny, dark=missing).
  mosaic,

  /// Modern typography-focused glassmorphism layout with huge percentage and clean stat row.
  minimalist,
}

/// The aspect ratios supported by the Living Dex Completion Card.
enum DexCardRatio {
  /// 16:9 Landscape - Perfect for desktop, Reddit, Twitter/X, and landscape exports.
  landscape16_9,

  /// 1:1 Square - Ideal for Instagram, Discord, and square avatars.
  square1_1,

  /// 9:16 Portrait / Story - Optimized for WhatsApp status, Instagram Stories, TikTok, mobile wallpapers.
  portrait9_16;

  /// Numeric aspect ratio (width / height).
  double get aspectRatio => switch (this) {
        DexCardRatio.landscape16_9 => 16.0 / 9.0,
        DexCardRatio.square1_1 => 1.0,
        DexCardRatio.portrait9_16 => 9.0 / 16.0,
      };

  /// Target export canvas dimensions (pixels) for high-resolution PNG generation.
  Size get exportDimensions => switch (this) {
        DexCardRatio.landscape16_9 => const Size(1920, 1080),
        DexCardRatio.square1_1 => const Size(1200, 1200),
        DexCardRatio.portrait9_16 => const Size(1080, 1920),
      };

  /// German label for UI display.
  String get labelDe => switch (this) {
        DexCardRatio.landscape16_9 => '16:9 Querformat',
        DexCardRatio.square1_1 => '1:1 Quadrat',
        DexCardRatio.portrait9_16 => '9:16 Story',
      };

  /// English label for UI display.
  String get labelEn => switch (this) {
        DexCardRatio.landscape16_9 => '16:9 Landscape',
        DexCardRatio.square1_1 => '1:1 Square',
        DexCardRatio.portrait9_16 => '9:16 Story',
      };
}

/// Represents the selected Pokémon used as a subtle background watermark artwork.
class DexCardPokemonWatermark {
  final int pokemonId;
  final String name;
  final String imageUrl;
  final String? formName;
  final bool isShiny;

  const DexCardPokemonWatermark({
    required this.pokemonId,
    required this.name,
    required this.imageUrl,
    this.formName,
    this.isShiny = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DexCardPokemonWatermark &&
          runtimeType == other.runtimeType &&
          pokemonId == other.pokemonId &&
          name == other.name &&
          imageUrl == other.imageUrl &&
          formName == other.formName &&
          isShiny == other.isShiny;

  @override
  int get hashCode => Object.hash(pokemonId, name, imageUrl, formName, isShiny);
}

/// The display mode for the Living Dex Mosaic card style.
enum DexMosaicMode {
  /// Each tile represents one individual Pokémon in the dex.
  pokemon,

  /// Each tile represents one PC box (30 Pokémon each or custom boxes).
  boxes;

  /// German label for UI display.
  String get labelDe => switch (this) {
        DexMosaicMode.pokemon => 'Kachel pro Pokémon',
        DexMosaicMode.boxes => 'Kachel pro PC-Box',
      };

  /// English label for UI display.
  String get labelEn => switch (this) {
        DexMosaicMode.pokemon => 'Tile per Pokémon',
        DexMosaicMode.boxes => 'Tile per PC Box',
      };
}

/// Configuration payload specifying user choices for card layout, format, and watermark.
class DexCardConfig {
  final DexCardStyle style;
  final DexCardRatio ratio;
  final DexCardPokemonWatermark? watermarkPokemon;
  final double watermarkOpacity;
  final bool showTypes;
  final int typeDisplayLimit;
  final bool showGenerations;
  final bool showOnlyStartedGenerations;
  final bool showVariants;
  final bool showSpecialCollections;
  final bool showBoxStats;
  final bool showWatermarkLogo;
  final bool showDate;
  final DexMosaicMode mosaicMode;
  final String? customTrainerNote;
  final DateTime completionDate;

  DexCardConfig({
    this.style = DexCardStyle.analyst,
    this.ratio = DexCardRatio.landscape16_9,
    this.watermarkPokemon,
    double watermarkOpacity = 0.18,
    this.showTypes = true,
    int typeDisplayLimit = 18,
    this.showGenerations = true,
    this.showOnlyStartedGenerations = false,
    this.showVariants = true,
    this.showSpecialCollections = true,
    this.showBoxStats = true,
    this.showWatermarkLogo = true,
    this.showDate = true,
    this.mosaicMode = DexMosaicMode.pokemon,
    this.customTrainerNote,
    DateTime? completionDate,
  })  : typeDisplayLimit = typeDisplayLimit.clamp(1, 18),
        watermarkOpacity = watermarkOpacity.clamp(0.0, 0.5),
        completionDate = completionDate ?? DateTime.now();

  /// Whether a background watermark Pokémon is active and has non-zero opacity.
  bool get hasWatermark => watermarkPokemon != null && watermarkOpacity > 0.0;

  /// Creates a copy of this configuration with the specified fields replaced.
  DexCardConfig copyWith({
    DexCardStyle? style,
    DexCardRatio? ratio,
    DexCardPokemonWatermark? watermarkPokemon,
    bool clearWatermark = false,
    double? watermarkOpacity,
    bool? showTypes,
    int? typeDisplayLimit,
    bool? showGenerations,
    bool? showOnlyStartedGenerations,
    bool? showVariants,
    bool? showSpecialCollections,
    bool? showBoxStats,
    bool? showWatermarkLogo,
    bool? showDate,
    DexMosaicMode? mosaicMode,
    String? customTrainerNote,
    bool clearCustomTrainerNote = false,
    DateTime? completionDate,
  }) {
    return DexCardConfig(
      style: style ?? this.style,
      ratio: ratio ?? this.ratio,
      watermarkPokemon:
          clearWatermark ? null : (watermarkPokemon ?? this.watermarkPokemon),
      watermarkOpacity: watermarkOpacity ?? this.watermarkOpacity,
      showTypes: showTypes ?? this.showTypes,
      typeDisplayLimit: typeDisplayLimit ?? this.typeDisplayLimit,
      showGenerations: showGenerations ?? this.showGenerations,
      showOnlyStartedGenerations:
          showOnlyStartedGenerations ?? this.showOnlyStartedGenerations,
      showVariants: showVariants ?? this.showVariants,
      showSpecialCollections:
          showSpecialCollections ?? this.showSpecialCollections,
      showBoxStats: showBoxStats ?? this.showBoxStats,
      showWatermarkLogo: showWatermarkLogo ?? this.showWatermarkLogo,
      showDate: showDate ?? this.showDate,
      mosaicMode: mosaicMode ?? this.mosaicMode,
      customTrainerNote: clearCustomTrainerNote
          ? null
          : (customTrainerNote ?? this.customTrainerNote),
      completionDate: completionDate ?? this.completionDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DexCardConfig &&
          runtimeType == other.runtimeType &&
          style == other.style &&
          ratio == other.ratio &&
          watermarkPokemon == other.watermarkPokemon &&
          watermarkOpacity == other.watermarkOpacity &&
          showTypes == other.showTypes &&
          typeDisplayLimit == other.typeDisplayLimit &&
          showGenerations == other.showGenerations &&
          showOnlyStartedGenerations == other.showOnlyStartedGenerations &&
          showVariants == other.showVariants &&
          showSpecialCollections == other.showSpecialCollections &&
          showBoxStats == other.showBoxStats &&
          showWatermarkLogo == other.showWatermarkLogo &&
          showDate == other.showDate &&
          mosaicMode == other.mosaicMode &&
          customTrainerNote == other.customTrainerNote &&
          completionDate == other.completionDate;

  @override
  int get hashCode => Object.hash(
        style,
        ratio,
        watermarkPokemon,
        watermarkOpacity,
        showTypes,
        typeDisplayLimit,
        showGenerations,
        showOnlyStartedGenerations,
        showVariants,
        showSpecialCollections,
        showBoxStats,
        showWatermarkLogo,
        showDate,
        mosaicMode,
        customTrainerNote,
        completionDate,
      );
}
