import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/dex_card_models.dart';

void main() {
  group('DexCardModels Unit Tests', () {
    test('DexCardStyle enum values', () {
      expect(DexCardStyle.values.length, 4);
      expect(DexCardStyle.values, contains(DexCardStyle.analyst));
      expect(DexCardStyle.values, contains(DexCardStyle.certificate));
      expect(DexCardStyle.values, contains(DexCardStyle.mosaic));
      expect(DexCardStyle.values, contains(DexCardStyle.minimalist));
    });

    test('DexCardRatio aspects and ratios', () {
      expect(DexCardRatio.landscape16_9.aspectRatio, closeTo(16.0 / 9.0, 0.001));
      expect(DexCardRatio.square1_1.aspectRatio, 1.0);
      expect(DexCardRatio.portrait9_16.aspectRatio, closeTo(9.0 / 16.0, 0.001));

      expect(DexCardRatio.landscape16_9.labelDe, '16:9 Querformat');
      expect(DexCardRatio.square1_1.labelDe, '1:1 Quadrat');
      expect(DexCardRatio.portrait9_16.labelDe, '9:16 Story');
    });

    test('DexCardPokemonWatermark initialization', () {
      const wm = DexCardPokemonWatermark(
        pokemonId: 6,
        name: 'Glurak',
        imageUrl: 'https://example.com/charizard.png',
        formName: 'mega-x',
        isShiny: true,
      );

      expect(wm.pokemonId, 6);
      expect(wm.name, 'Glurak');
      expect(wm.imageUrl, 'https://example.com/charizard.png');
      expect(wm.formName, 'mega-x');
      expect(wm.isShiny, isTrue);
    });

    test('DexCardConfig defaults and constraints', () {
      final config = DexCardConfig();

      expect(config.style, DexCardStyle.analyst);
      expect(config.ratio, DexCardRatio.landscape16_9);
      expect(config.watermarkPokemon, isNull);
      expect(config.watermarkOpacity, closeTo(0.18, 0.001));
      expect(config.showTypes, isTrue);
      expect(config.typeDisplayLimit, 18);
      expect(config.showGenerations, isTrue);
      expect(config.showVariants, isTrue);
      expect(config.showSpecialCollections, isTrue);
      expect(config.showBoxStats, isTrue);
      expect(config.showWatermarkLogo, isTrue);
      expect(config.showDate, isTrue);
      expect(config.customTrainerNote, isNull);
      expect(config.hasWatermark, isFalse);
    });

    test('DexCardConfig clamps opacity between 0.0 and 0.5', () {
      final clampedLow = DexCardConfig(watermarkOpacity: -0.2);
      expect(clampedLow.watermarkOpacity, 0.0);

      final clampedHigh = DexCardConfig(watermarkOpacity: 0.95);
      expect(clampedHigh.watermarkOpacity, 0.5);

      final valid = DexCardConfig(watermarkOpacity: 0.25);
      expect(valid.watermarkOpacity, 0.25);
    });

    test('DexCardConfig hasWatermark logic', () {
      const wm = DexCardPokemonWatermark(
        pokemonId: 25,
        name: 'Pikachu',
        imageUrl: 'https://example.com/pikachu.png',
      );

      final configWithWatermark = DexCardConfig(
        watermarkPokemon: wm,
        watermarkOpacity: 0.2,
      );
      expect(configWithWatermark.hasWatermark, isTrue);

      final configZeroOpacity = DexCardConfig(
        watermarkPokemon: wm,
        watermarkOpacity: 0.0,
      );
      expect(configZeroOpacity.hasWatermark, isFalse);

      final configNullPokemon = DexCardConfig(
        watermarkPokemon: null,
        watermarkOpacity: 0.2,
      );
      expect(configNullPokemon.hasWatermark, isFalse);
    });

    test('DexCardConfig copyWith updates specified fields', () {
      final initial = DexCardConfig();
      const wm = DexCardPokemonWatermark(
        pokemonId: 150,
        name: 'Mewtu',
        imageUrl: 'https://example.com/mewtwo.png',
      );

      final updated = initial.copyWith(
        style: DexCardStyle.certificate,
        ratio: DexCardRatio.square1_1,
        watermarkPokemon: wm,
        watermarkOpacity: 0.35,
        showTypes: false,
        showVariants: false,
        showSpecialCollections: false,
        showBoxStats: false,
        showWatermarkLogo: false,
        customTrainerNote: 'OT: Ash #12345',
      );

      expect(updated.style, DexCardStyle.certificate);
      expect(updated.ratio, DexCardRatio.square1_1);
      expect(updated.watermarkPokemon, wm);
      expect(updated.watermarkOpacity, 0.35);
      expect(updated.showTypes, isFalse);
      expect(updated.showVariants, isFalse);
      expect(updated.showSpecialCollections, isFalse);
      expect(updated.showBoxStats, isFalse);
      expect(updated.showWatermarkLogo, isFalse);
      expect(updated.customTrainerNote, 'OT: Ash #12345');
      expect(updated.showGenerations, isTrue); // unchanged
    });

    test('DexCardConfig copyWith clearWatermark resets watermarkPokemon to null', () {
      const wm = DexCardPokemonWatermark(
        pokemonId: 150,
        name: 'Mewtu',
        imageUrl: 'https://example.com/mewtwo.png',
      );
      final initial = DexCardConfig(watermarkPokemon: wm);
      expect(initial.hasWatermark, isTrue);

      final cleared = initial.copyWith(clearWatermark: true);
      expect(cleared.watermarkPokemon, isNull);
      expect(cleared.hasWatermark, isFalse);
    });

    test('DexCardConfig copyWith clearCustomTrainerNote resets customTrainerNote to null', () {
      final initial = DexCardConfig(customTrainerNote: 'Trainer Marvin');
      expect(initial.customTrainerNote, 'Trainer Marvin');

      final cleared = initial.copyWith(clearCustomTrainerNote: true);
      expect(cleared.customTrainerNote, isNull);
    });

    test('DexCardConfig showOnlyStartedGenerations defaults to false and can be copied', () {
      final config = DexCardConfig();
      expect(config.showOnlyStartedGenerations, isFalse);

      final updated = config.copyWith(showOnlyStartedGenerations: true);
      expect(updated.showOnlyStartedGenerations, isTrue);
    });

    test('DexCardConfig typeDisplayLimit defaults to 18 and can be copied', () {
      final config = DexCardConfig();
      expect(config.typeDisplayLimit, 18);

      final updated6 = config.copyWith(typeDisplayLimit: 6);
      expect(updated6.typeDisplayLimit, 6);

      final updated12 = config.copyWith(typeDisplayLimit: 12);
      expect(updated12.typeDisplayLimit, 12);
    });

    test('DexCardConfig clamps typeDisplayLimit between 1 and 18', () {
      final clampedLow = DexCardConfig(typeDisplayLimit: 0);
      expect(clampedLow.typeDisplayLimit, 1);

      final clampedHigh = DexCardConfig(typeDisplayLimit: 50);
      expect(clampedHigh.typeDisplayLimit, 18);
    });

    test('DexMosaicMode enum values and labels', () {
      expect(DexMosaicMode.values.length, 2);
      expect(DexMosaicMode.values, contains(DexMosaicMode.pokemon));
      expect(DexMosaicMode.values, contains(DexMosaicMode.boxes));

      expect(DexMosaicMode.pokemon.labelDe, 'Kachel pro Pokémon');
      expect(DexMosaicMode.pokemon.labelEn, 'Tile per Pokémon');
      expect(DexMosaicMode.boxes.labelDe, 'Kachel pro PC-Box');
      expect(DexMosaicMode.boxes.labelEn, 'Tile per PC Box');
    });

    test('DexCardConfig mosaicMode defaults to pokemon and can be copied', () {
      final config = DexCardConfig();
      expect(config.mosaicMode, DexMosaicMode.pokemon);

      final updatedBoxes = config.copyWith(mosaicMode: DexMosaicMode.boxes);
      expect(updatedBoxes.mosaicMode, DexMosaicMode.boxes);

      final updatedPokemon = updatedBoxes.copyWith(mosaicMode: DexMosaicMode.pokemon);
      expect(updatedPokemon.mosaicMode, DexMosaicMode.pokemon);
    });

    test('DexCardConfig supports value equality and hashCode', () {
      final now = DateTime(2026, 10, 21, 12, 0);
      final config1 = DexCardConfig(
        style: DexCardStyle.analyst,
        ratio: DexCardRatio.landscape16_9,
        typeDisplayLimit: 12,
        mosaicMode: DexMosaicMode.pokemon,
        completionDate: now,
      );
      final config2 = DexCardConfig(
        style: DexCardStyle.analyst,
        ratio: DexCardRatio.landscape16_9,
        typeDisplayLimit: 12,
        mosaicMode: DexMosaicMode.pokemon,
        completionDate: now,
      );
      final configDiffLimit = config1.copyWith(typeDisplayLimit: 6);
      final configDiffMosaic = config1.copyWith(mosaicMode: DexMosaicMode.boxes);

      expect(config1, equals(config2));
      expect(config1.hashCode, equals(config2.hashCode));
      expect(config1 == configDiffLimit, isFalse);
      expect(config1 == configDiffMosaic, isFalse);
    });
  });
}
