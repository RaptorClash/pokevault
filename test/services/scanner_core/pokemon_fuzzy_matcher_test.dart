import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/services/scanner_core/engine/pokemon_fuzzy_matcher.dart';

void main() {
  group('PokemonFuzzyMatcher Tests (TDD & Adversarial OCR Typo Handling)', () {
    late PokemonFuzzyMatcher matcher;

    setUp(() {
      // Seed with representative test dictionary across multiple languages
      matcher = PokemonFuzzyMatcher.withEntries([
        const PokemonMatcherEntry(id: 1, name: 'Bisasam', language: 'de'),
        const PokemonMatcherEntry(id: 1, name: 'Bulbasaur', language: 'en'),
        const PokemonMatcherEntry(id: 1, name: 'Bulbizarre', language: 'fr'),
        const PokemonMatcherEntry(id: 1, name: 'フシギダネ', language: 'ja'),
        const PokemonMatcherEntry(id: 4, name: 'Glumanda', language: 'de'),
        const PokemonMatcherEntry(id: 4, name: 'Charmander', language: 'en'),
        const PokemonMatcherEntry(id: 4, name: 'Salamèche', language: 'fr'),
        const PokemonMatcherEntry(id: 4, name: 'ヒトカゲ', language: 'ja'),
        const PokemonMatcherEntry(id: 5, name: 'Glutexo', language: 'de'),
        const PokemonMatcherEntry(id: 5, name: 'Charmeleon', language: 'en'),
        const PokemonMatcherEntry(id: 5, name: 'Reptincel', language: 'fr'),
        const PokemonMatcherEntry(id: 5, name: 'リザード', language: 'ja'),
        const PokemonMatcherEntry(id: 6, name: 'Glurak', language: 'de'),
        const PokemonMatcherEntry(id: 6, name: 'Charizard', language: 'en'),
        const PokemonMatcherEntry(id: 25, name: 'Pikachu', language: 'de'),
        const PokemonMatcherEntry(id: 25, name: 'Pikachu', language: 'en'),
        const PokemonMatcherEntry(id: 25, name: 'Pikachu', language: 'fr'),
        const PokemonMatcherEntry(id: 25, name: 'ピカチュウ', language: 'ja'),
        const PokemonMatcherEntry(id: 150, name: 'Mewtu', language: 'de'),
        const PokemonMatcherEntry(id: 150, name: 'Mewtwo', language: 'en'),
      ]);
    });

    test('Exact match lookup across languages', () {
      final mDe = matcher.match('Glumanda');
      expect(mDe, isNotNull);
      expect(mDe!.pokemonId, 4);
      expect(mDe.canonicalName, 'Glumanda');
      expect(mDe.confidence, 1.0);

      final mEn = matcher.match('Charmander');
      expect(mEn, isNotNull);
      expect(mEn!.pokemonId, 4);
      expect(mEn.canonicalName, 'Charmander');

      final mFr = matcher.match('Salamèche');
      expect(mFr, isNotNull);
      expect(mFr!.pokemonId, 4);

      final mJa = matcher.match('ヒトカゲ');
      expect(mJa, isNotNull);
      expect(mJa!.pokemonId, 4);
    });

    test('Case insensitivity and surrounding whitespace/punctuation', () {
      final res = matcher.match('   gLuMaNdA!  ');
      expect(res, isNotNull);
      expect(res!.pokemonId, 4);
      expect(res.confidence, 1.0);
    });

    test('Tolerates common OCR character substitutions (1/l, 4/A, 0/O, @/a)', () {
      // Glum4nda -> Glumanda
      final r1 = matcher.match('Glum4nda');
      expect(r1, isNotNull);
      expect(r1!.pokemonId, 4);
      expect(r1.confidence, greaterThanOrEqualTo(0.80));

      // Pik4chu -> Pikachu
      final r2 = matcher.match('Pik4chu');
      expect(r2, isNotNull);
      expect(r2!.pokemonId, 25);
      expect(r2.confidence, greaterThanOrEqualTo(0.80));

      // B1sas4m -> Bisasam
      final r3 = matcher.match('B1sas4m');
      expect(r3, isNotNull);
      expect(r3!.pokemonId, 1);

      // Mewtw0 -> Mewtwo
      final r4 = matcher.match('Mewtw0');
      expect(r4, isNotNull);
      expect(r4!.pokemonId, 150);
    });

    test('Rejects gibberish and low confidence words below threshold', () {
      expect(matcher.match(''), isNull);
      expect(matcher.match('XZYYQQWW'), isNull);
      expect(matcher.match('Supertrank'), isNull);
      expect(matcher.match('Hyperball'), isNull);
    });

    test('Matcher entries can be initialized dynamically from Pokemon model list', () {
      final dynamicMatcher = PokemonFuzzyMatcher.fromPokemonData([
        {
          'id': 4,
          'names': {'de': 'Glumanda', 'en': 'Charmander', 'fr': 'Salamèche'}
        },
        {
          'id': 25,
          'names': {'de': 'Pikachu', 'en': 'Pikachu'}
        }
      ]);

      expect(dynamicMatcher.match('Glumanda')?.pokemonId, 4);
      expect(dynamicMatcher.match('Charmander')?.pokemonId, 4);
      expect(dynamicMatcher.match('Pikachu')?.pokemonId, 25);
    });
  });
}
