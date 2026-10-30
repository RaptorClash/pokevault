import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/models/dex_view_models.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/services/shiny_lock_service.dart';

void main() {
  group('ShinyLockService Totem & Diancie Tests (TDD)', () {
    test('Totem Pokémon forms (Herrscher) are shiny-locked across all regions', () {
      final gumshoos = Pokemon(
        id: 735,
        nameDe: 'Manguspektor',
        nameEn: 'Gumshoos',
        hasGenderDifferences: false,
        genderRate: 4,
        captureRate: 127,
        evolutionChainId: 377,
        eggGroups: ['field'],
        weight: 14.2,
        speed: 45,
        forms: [
          PokemonForm(
            name: 'totem',
            formType: 'regional',
            minGen: 7,
            imageId: 735,
            types: ['normal'],
            exclusiveRegions: [],
          ),
        ],
      );

      final totemEntry = DexDisplayEntry(
        pokemon: gumshoos,
        uniqueId: '735_totem',
        displaySuffix: ' (Totem)',
        imageUrl: '',
        form: gumshoos.forms.first,
      );

      expect(ShinyLockService.isShinyLocked(totemEntry), isTrue);
      expect(ShinyLockService.isShinyLocked(totemEntry, dexRegion: 'updated_alola_regional'), isTrue);
      expect(ShinyLockService.isUniqueIdShinyLocked('735_totem'), isTrue);
      expect(ShinyLockService.isUniqueIdShinyLocked('105_alola_totem'), isTrue);
      expect(ShinyLockService.isUniqueIdShinyLocked('20_totem-alola'), isTrue);

      final reasonDe = ShinyLockService.getShinyLockReason(totemEntry, lang: 'de');
      expect(reasonDe.contains('Herrscher') || reasonDe.contains('Totem'), isTrue);
    });

    test('Diancie (#719) is shiny-locked in Pokemon Legends Z-A (lumiose)', () {
      final diancie = Pokemon(
        id: 719,
        nameDe: 'Diancie',
        nameEn: 'Diancie',
        hasGenderDifferences: false,
        genderRate: -1,
        captureRate: 3,
        evolutionChainId: 369,
        eggGroups: ['undiscovered'],
        weight: 8.8,
        speed: 50,
        forms: [
          PokemonForm(
            name: 'normal',
            formType: 'normal',
            minGen: 6,
            imageId: 719,
            types: ['rock', 'fairy'],
            exclusiveRegions: [],
          ),
        ],
      );

      final diancieEntry = DexDisplayEntry(
        pokemon: diancie,
        uniqueId: '719_normal',
        displaySuffix: '',
        imageUrl: '',
        form: diancie.forms.first,
      );

      expect(
        ShinyLockService.isShinyLocked(diancieEntry, dexRegion: 'lumiose_regional'),
        isTrue,
        reason: 'Diancie is a mythical event Pokemon and shiny locked in Legends Z-A',
      );
      expect(
        ShinyLockService.isShinyLocked(diancieEntry, dexRegion: 'lumiose_dimensions_regional'),
        isTrue,
      );
      expect(
        ShinyLockService.isUniqueIdShinyLocked('719_normal', dexRegion: 'lumiose_regional'),
        isTrue,
      );
    });
  });
}
