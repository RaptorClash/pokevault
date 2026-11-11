import 'dart:math' as math;

/// Single Pokémon name entry in the fuzzy matcher dictionary.
class PokemonMatcherEntry {
  final int id;
  final String name;
  final String language;

  const PokemonMatcherEntry({
    required this.id,
    required this.name,
    required this.language,
  });
}

/// Result returned when a name is matched by [PokemonFuzzyMatcher].
class FuzzyMatchResult {
  final int pokemonId;
  final String canonicalName;
  final String matchedLanguage;
  final double confidence;

  const FuzzyMatchResult({
    required this.pokemonId,
    required this.canonicalName,
    required this.matchedLanguage,
    required this.confidence,
  });
}

/// Robust, fault-tolerant Pokémon name resolver with OCR typo tolerance.
class PokemonFuzzyMatcher {
  final List<PokemonMatcherEntry> _entries;
  final Map<String, List<PokemonMatcherEntry>> _exactMap = {};

  PokemonFuzzyMatcher.withEntries(List<PokemonMatcherEntry> entries)
      : _entries = entries {
    for (final e in _entries) {
      final key = _normalizeKey(e.name);
      _exactMap.putIfAbsent(key, () => []).add(e);
    }
  }

  factory PokemonFuzzyMatcher.fromPokemonData(
    List<Map<String, dynamic>> pokemonList,
  ) {
    final entries = <PokemonMatcherEntry>[];
    for (final item in pokemonList) {
      final id = (item['id'] as num?)?.toInt() ?? 0;
      if (id <= 0) continue;

      final names = item['names'];
      if (names is Map) {
        for (final entry in names.entries) {
          final lang = entry.key.toString().toLowerCase();
          final name = entry.value?.toString().trim();
          if (name != null && name.isNotEmpty) {
            entries.add(PokemonMatcherEntry(id: id, name: name, language: lang));
          }
        }
      }

      final nameDe = item['name_de']?.toString().trim();
      if (nameDe != null && nameDe.isNotEmpty && nameDe != 'Unknown') {
        entries.add(PokemonMatcherEntry(id: id, name: nameDe, language: 'de'));
      }

      final nameEn = item['name_en']?.toString().trim();
      if (nameEn != null && nameEn.isNotEmpty && nameEn != 'Unknown') {
        entries.add(PokemonMatcherEntry(id: id, name: nameEn, language: 'en'));
      }
    }
    return PokemonFuzzyMatcher.withEntries(entries);
  }

  /// Finds the best matching Pokémon entry for [query] if confidence >= [threshold].
  FuzzyMatchResult? match(String query, {double threshold = 0.75}) {
    final cleaned = _cleanQuery(query);
    if (cleaned.isEmpty) return null;

    final normKey = _normalizeKey(cleaned);

    // 1. Exact match check
    if (_exactMap.containsKey(normKey)) {
      final match = _exactMap[normKey]!.first;
      return FuzzyMatchResult(
        pokemonId: match.id,
        canonicalName: match.name,
        matchedLanguage: match.language,
        confidence: 1.0,
      );
    }

    // 2. OCR normalized match (handle '4' -> 'a', '1' -> 'i', '0' -> 'o', '@' -> 'a')
    final ocrSubstituted = _substituteOcrGlitches(normKey);
    if (_exactMap.containsKey(ocrSubstituted)) {
      final match = _exactMap[ocrSubstituted]!.first;
      return FuzzyMatchResult(
        pokemonId: match.id,
        canonicalName: match.name,
        matchedLanguage: match.language,
        confidence: 0.90,
      );
    }

    // 3. Levenshtein fuzzy distance scan
    FuzzyMatchResult? bestResult;
    double highestScore = 0.0;

    for (final entry in _entries) {
      final entryNorm = _normalizeKey(entry.name);
      final score = _calculateSimilarity(normKey, entryNorm);
      final ocrScore = _calculateSimilarity(ocrSubstituted, entryNorm);
      final effectiveScore = math.max(score, ocrScore);

      if (effectiveScore > highestScore && effectiveScore >= threshold) {
        highestScore = effectiveScore;
        bestResult = FuzzyMatchResult(
          pokemonId: entry.id,
          canonicalName: entry.name,
          matchedLanguage: entry.language,
          confidence: (effectiveScore * 100).round() / 100.0,
        );
      }
    }

    return bestResult;
  }

  static String _cleanQuery(String raw) {
    return raw
        .replaceAll(RegExp(r'[!?,.:;"]+'), '')
        .trim();
  }

  static String _normalizeKey(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'\s+'), '');
  }

  static String _substituteOcrGlitches(String s) {
    return s
        .replaceAll('4', 'a')
        .replaceAll('@', 'a')
        .replaceAll('0', 'o')
        .replaceAll('1', 'i')
        .replaceAll('vv', 'w')
        .replaceAll(r'$', 's');
  }

  static double _calculateSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final dist = _levenshtein(s1, s2);
    final maxLen = math.max(s1.length, s2.length);
    return 1.0 - (dist / maxLen);
  }

  static int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    List<int> v0 = List<int>.generate(b.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(b.length + 1, 0);

    for (int i = 0; i < a.length; i++) {
      v1[0] = i + 1;

      for (int j = 0; j < b.length; j++) {
        final cost = a[i] == b[j] ? 0 : 1;
        v1[j + 1] = math.min(
          v1[j] + 1,
          math.min(v0[j + 1] + 1, v0[j] + cost),
        );
      }

      for (int j = 0; j < v0.length; j++) {
        v0[j] = v1[j];
      }
    }

    return v1[b.length];
  }
}
