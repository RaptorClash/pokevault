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
        const PokemonMatcherEntry(id: 554, name: 'Flampion', language: 'de'),
        const PokemonMatcherEntry(id: 554, name: 'Darumaka', language: 'en'),
        const PokemonMatcherEntry(id: 559, name: 'Zurrokex', language: 'de'),
        const PokemonMatcherEntry(id: 559, name: 'Scraggy', language: 'en'),
        const PokemonMatcherEntry(id: 560, name: 'Irokex', language: 'de'),
        const PokemonMatcherEntry(id: 560, name: 'Scrafty', language: 'en'),
        const PokemonMatcherEntry(id: 570, name: 'Zorua', language: 'de'),
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

    test('Matches Gen 5 pixel-font OCR glitches for Flampion from real WinRT logs', () {
      expect(matcher.match("F'lanpiorl")?.pokemonId, 554);
      expect(matcher.match("F'lanpign")?.pokemonId, 554);
      expect(matcher.match(".F'1anpipn")?.pokemonId, 554);
    });

    test('Smart-Search matchTopK and matchTokensFromLine resolve garbled Zurrokex Black log lines', () {
      final topK = matcher.matchTopK('Zr-rrokex', limit: 3);
      expect(topK, isNotEmpty);
      expect(topK.first.pokemonId, 559);
      expect(topK.first.canonicalName, 'Zurrokex');

      final lineMatches = matcher.matchTokensFromLine('Zr-rrokex wrde aefar«t!', limit: 3);
      expect(lineMatches, isNotEmpty);
      expect(lineMatches.first.pokemonId, 559);
      expect(lineMatches.first.canonicalName, 'Zurrokex');

      final noise = matcher.matchTokensFromLine('[110/601 melonDS 1.1 File System View Config Help 150/204');
      expect(noise, isEmpty);
    });

    test('matchAllFromText extracts up to 5 non-overlapping Pokemon from multi-encounter / HUD lines', () {
      final hordeMatcher = PokemonFuzzyMatcher.withEntries(const [
        PokemonMatcherEntry(id: 551, name: 'Ganovil', language: 'de'),
        PokemonMatcherEntry(id: 554, name: 'Flampion', language: 'de'),
        PokemonMatcherEntry(id: 559, name: 'Zurrokex', language: 'de'),
        PokemonMatcherEntry(id: 497, name: 'Serpiroyal', language: 'de'),
        PokemonMatcherEntry(id: 25, name: 'Pikachu', language: 'de'),
        PokemonMatcherEntry(id: 133, name: 'Evoli', language: 'de'),
      ]);

      final hudMatches = hordeMatcher.matchAllFromText(
        'Zurrokex Lv.16   Flampion Lv.16   Ganovil Lv.17',
      );
      expect(hudMatches.map((m) => m.pokemonId).toList(), [559, 554, 551]);

      final multiPhraseMatches = hordeMatcher.matchAllFromText(
        'Eine Gruppe wilder Zurrokex und Ganovil erscheint!',
      );
      expect(multiPhraseMatches.map((m) => m.pokemonId).toList(), [559, 551]);

      // Deduplicates repeated mentions of the same Pokemon
      final duplicateMentions = hordeMatcher.matchAllFromText(
        'Pikachu Lv.5   Pikachu Lv.5   Evoli Lv.6',
      );
      expect(duplicateMentions.map((m) => m.pokemonId).toList(), [25, 133]);

      // Rejects emulator chrome
      expect(
        hordeMatcher.matchAllFromText('[97/601 melonDS 1.1 File System View Config Help'),
        isEmpty,
      );
    });

    test('Zero-lag performance benchmark & Top-10 descending probability ranking across 2500 entries', () {
      final largeEntries = <PokemonMatcherEntry>[
        const PokemonMatcherEntry(id: 554, name: 'Flampion', language: 'de'),
        const PokemonMatcherEntry(id: 555, name: 'Flampivian', language: 'de'),
        const PokemonMatcherEntry(id: 136, name: 'Flamara', language: 'de'),
        const PokemonMatcherEntry(id: 500, name: 'Flambirex', language: 'de'),
        const PokemonMatcherEntry(id: 725, name: 'Flamiau', language: 'de'),
        const PokemonMatcherEntry(id: 669, name: 'Flabebe', language: 'de'),
        const PokemonMatcherEntry(id: 670, name: 'Floette', language: 'de'),
        const PokemonMatcherEntry(id: 671, name: 'Florges', language: 'de'),
        const PokemonMatcherEntry(id: 79, name: 'Flegmon', language: 'de'),
        const PokemonMatcherEntry(id: 255, name: 'Flemmli', language: 'de'),
        const PokemonMatcherEntry(id: 527, name: 'Fleknoil', language: 'de'),
        const PokemonMatcherEntry(id: 528, name: 'Fletiamo', language: 'de'),
        const PokemonMatcherEntry(id: 662, name: 'Dartignis', language: 'de'),
      ];
      for (int i = 1; i <= 2500; i++) {
        largeEntries.add(PokemonMatcherEntry(
          id: 1000 + i,
          name: 'MonSpecies${i}Alpha',
          language: 'de',
        ));
      }

      final largeMatcher = PokemonFuzzyMatcher.withEntries(largeEntries);

      // 1. Hot-path live-OCR threshold benchmark: 20 queries across 2513 entries
      final hotSw = Stopwatch()..start();
      for (int q = 0; q < 20; q++) {
        final best = largeMatcher.match("Fdlanp,io.n", threshold: 0.65);
        expect(best?.pokemonId, 554);
      }
      hotSw.stop();
      expect(hotSw.elapsedMilliseconds, lessThan(200));

      // 2. Top-10 descending probability ranking for Event Correction Dialog
      final topSw = Stopwatch()..start();
      final top10 = largeMatcher.matchTopK("Fdlanp,io.n", limit: 10, threshold: 0.15);
      topSw.stop();

      expect(top10, hasLength(10));
      expect(top10.first.pokemonId, 554);
      for (int i = 0; i < top10.length - 1; i++) {
        expect(top10[i].confidence, greaterThanOrEqualTo(top10[i + 1].confidence));
      }
      expect(topSw.elapsedMilliseconds, lessThan(100));
    });
  });
}
