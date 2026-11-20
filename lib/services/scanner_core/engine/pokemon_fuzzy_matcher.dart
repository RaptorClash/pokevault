import 'dart:math' as math;
import 'dart:typed_data';

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

/// Robust, fault-tolerant Pokémon name resolver with OCR typo tolerance and Smart-Search.
class PokemonFuzzyMatcher {
  static const Set<String> _noiseStopWords = {
    // Emulator chrome & window titles
    'melonds',
    'desmume',
    'mgba',
    'vbam',
    'retroarch',
    'dolphin',
    'citra',
    'azahar',
    'ryujinx',
    'yuzu',
    'file',
    'system',
    'view',
    'config',
    'help',
    'tools',
    'emulation',
    'options',
    'option',
    'debug',
    'fps',
    // Common dialogue words & OCR garblings of German/English catch phrases
    'klasse',
    'super',
    'prima',
    'gotcha',
    'hurra',
    'wurde',
    'wrde',
    'worden',
    'gefangen',
    'aefart',
    'aefar',
    'gefan',
    'erscheint',
    'erscheinen',
    'erschin',
    'gruppe',
    'wildes',
    'wilde',
    'wild',
    'ein',
    'eine',
    'einer',
    'und',
    'der',
    'die',
    'das',
    'so',
    'soll',
    'tun',
    'gib',
    'einen',
    'spitzname',
    'spitznamen',
    'nickname',
    'will',
    'hat',
    'sich',
    'zu',
    'entwickelt',
    'was',
    'were',
    'been',
    'caught',
    'appeared',
    'evolved',
    'into',
    'sauvage',
    'apparaît',
    'apparait',
    'capture',
    'capturé',
    'attrapé',
    'salvaje',
    'apareció',
    'atrapado',
    'selvatico',
    'apparso',
    'catturato',
    'chromatique',
    'variocolor',
    'cromatico',
    'やせいの',
    'とびだしてきた',
    'つかまえた',
    '야생의',
    '나타났다',
    '잡았다',
    '野生的',
    '出现了',
    '出現了',
    '收服了',
    'beutel',
    'flucht',
    'tasche',
    'speichern',
    'gespeichert',
    'bericht',
    'pokemon',
    'pokémon',
    'pokmon',
    'kp',
    'hp',
    'lv',
    'lvl',
    'level',
  };

  static final RegExp _letterRegExp = RegExp(
    r'[A-Za-zÀ-ÿ\u3040-\u30FF\u4E00-\u9FFF\uAC00-\uD7AF]',
  );

  static final RegExp _cjkRegExp = RegExp(
    r'[\u3040-\u30FF\u4E00-\u9FFF\uAC00-\uD7AF]',
  );

  static final RegExp _cjkRunRegExp = RegExp(
    r'[\u3040-\u30FF\u4E00-\u9FFF\uAC00-\uD7AF]{2,}',
  );

  final List<PokemonMatcherEntry> _entries;
  final Map<String, List<PokemonMatcherEntry>> _exactMap = {};
  final List<_PreparedEntry> _prepared = [];

  PokemonFuzzyMatcher.withEntries(List<PokemonMatcherEntry> entries)
      : _entries = entries {
    for (final e in _entries) {
      final key = _normalizeKey(e.name);
      if (key.isEmpty) continue;
      _exactMap.putIfAbsent(key, () => []).add(e);
      final tri = _packedTrigrams('  $key ');
      _prepared.add(
        _PreparedEntry(
          entry: e,
          normKey: key,
          codeUnits: Uint16List.fromList(key.codeUnits),
          trigrams: tri,
        ),
      );
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
    final results = matchTopK(query, limit: 1, threshold: threshold);
    return results.isEmpty ? null : results.first;
  }

  /// Returns up to [limit] deduplicated Pokémon matches ranked by descending confidence
  /// using exact lookup, pixel-font glitch variants, Damerau-Levenshtein distance, and Trigram Dice.
  List<FuzzyMatchResult> matchTopK(
    String query, {
    int limit = 3,
    double threshold = 0.65,
  }) {
    if (limit <= 0) return const [];
    final cleaned = _cleanQuery(query);
    if (cleaned.isEmpty) return const [];

    final normKey = _normalizeKey(cleaned);
    if (normKey.isEmpty || _noiseStopWords.contains(normKey)) {
      return const [];
    }
    if (!_letterRegExp.hasMatch(normKey)) return const [];

    final byPokemonId = <int, FuzzyMatchResult>{};

    void recordCandidate(PokemonMatcherEntry entry, double score) {
      final rounded = (score.clamp(0.0, 1.0) * 100).round() / 100.0;
      if (rounded < threshold) return;
      final existing = byPokemonId[entry.id];
      if (existing == null || rounded > existing.confidence) {
        byPokemonId[entry.id] = FuzzyMatchResult(
          pokemonId: entry.id,
          canonicalName: entry.name,
          matchedLanguage: entry.language,
          confidence: rounded,
        );
      }
    }

    // 1. Exact match check
    if (_exactMap.containsKey(normKey)) {
      for (final m in _exactMap[normKey]!) {
        recordCandidate(m, 1.0);
      }
    }

    // 2. OCR normalized exact check across common pixel-font glyph confusions
    final variants = _ocrVariants(normKey);
    for (final variant in variants) {
      final exactVariant = _exactMap[variant];
      if (exactVariant != null) {
        for (final m in exactVariant) {
          recordCandidate(m, 0.92);
        }
      }
    }

    // Fast exit if an exact match is found and limit == 1
    if (limit == 1 && byPokemonId.isNotEmpty) {
      final sorted = byPokemonId.values.toList()
        ..sort((a, b) => b.confidence.compareTo(a.confidence));
      return [sorted.first];
    }

    // Avoid matching tiny 1-2 char fragments fuzzily unless exact
    if (normKey.length >= 2) {
      final allQueries = <String>{normKey, ...variants}.toList(growable: false);
      final preparedQueries = allQueries
          .where((q) => q.isNotEmpty)
          .map(
            (q) => _QueryProfile(
              norm: q,
              codeUnits: Uint16List.fromList(q.codeUnits),
              trigrams: _packedTrigrams('  $q '),
            ),
          )
          .toList(growable: false);

      // Shared rolling DP scratchpad + O(1)-reset multiset overlap counters (zero per-entry allocations)
      var scratchRow0 = Int32List(64);
      var scratchRow1 = Int32List(64);
      var scratchRow2 = Int32List(64);
      final qEpoch = Int32List(128);
      final qAvail = Int32List(128);
      final eSeenEpoch = Int32List(128);
      final eRem = Int32List(128);
      int qId = 0;
      int entryId = 0;

      // Dynamic Top-K floor tightening once `limit` candidates have been seen
      double currentKthFloor = threshold;
      void refreshKthFloor() {
        if (byPokemonId.length < limit) return;
        final scores = byPokemonId.values.map((r) => r.confidence).toList()
          ..sort((a, b) => b.compareTo(a));
        final kth = scores[limit - 1];
        if (kth > currentKthFloor) {
          currentKthFloor = kth;
        }
      }
      refreshKthFloor();

      for (final pq in preparedQueries) {
        final qUnits = pq.codeUnits;
        final qLen = pq.norm.length;
        qId++;
        int qNonAscii = 0;
        for (int k = 0; k < qUnits.length; k++) {
          final cu = qUnits[k];
          if (cu < 128) {
            if (qEpoch[cu] != qId) {
              qEpoch[cu] = qId;
              qAvail[cu] = 1;
            } else {
              qAvail[cu]++;
            }
          } else {
            qNonAscii++;
          }
        }

        for (final pEntry in _prepared) {
          final entryLen = pEntry.normKey.length;
          final existingBest = byPokemonId[pEntry.entry.id]?.confidence ?? 0.0;
          if (existingBest >= 1.0) continue;

          final effectiveMin = existingBest > currentKthFloor
              ? existingBest
              : currentKthFloor;

          final maxLen = qLen > entryLen ? qLen : entryLen;
          final minLen = qLen < entryLen ? qLen : entryLen;
          if (maxLen > 0 && minLen / maxLen < 0.45) continue;

          // Exact O(1)-reset character-multiset upper bound (valid under Damerau-Levenshtein)
          entryId++;
          int shared = qNonAscii;
          final eUnits = pEntry.codeUnits;
          for (int k = 0; k < eUnits.length; k++) {
            final cu = eUnits[k];
            if (cu < 128) {
              if (qEpoch[cu] == qId) {
                if (eSeenEpoch[cu] != entryId) {
                  eSeenEpoch[cu] = entryId;
                  eRem[cu] = qAvail[cu];
                }
                if (eRem[cu] > 0) {
                  eRem[cu]--;
                  shared++;
                }
              }
            } else {
              shared++;
            }
          }
          if (shared > minLen) shared = minLen;
          final lenDiff = maxLen - minLen;
          final multisetDiff = maxLen - shared;
          final distLower = lenDiff > multisetDiff ? lenDiff : multisetDiff;
          final damUpper = maxLen == 0 ? 1.0 : 1.0 - (distLower / maxLen);

          // Skip even trigram calculation if max possible score with Dice=1.0 is below floor
          final maxPossibleWithPerfectDice =
              damUpper > (damUpper * 0.72 + 0.28)
                  ? damUpper
                  : (damUpper * 0.72 + 0.28);
          if (maxPossibleWithPerfectDice + 0.005 < effectiveMin) continue;

          final diceSim = pq.norm == pEntry.normKey
              ? 1.0
              : _trigramDiceFast(pq.trigrams, pEntry.trigrams);
          final weightedUpper = (damUpper * 0.72) + (diceSim * 0.28);
          final combinedUpper = damUpper > weightedUpper ? damUpper : weightedUpper;
          if (combinedUpper + 0.005 < effectiveMin) continue;

          final minDamFromWeighted = (effectiveMin - (diceSim * 0.28)) / 0.72;
          final minDamRequired =
              effectiveMin < minDamFromWeighted ? effectiveMin : minDamFromWeighted;
          final maxAllowedDist = minDamRequired <= 0.0
              ? maxLen
              : ((1.0 - minDamRequired) * maxLen).ceil() + 1;

          if (entryLen + 1 > scratchRow0.length) {
            final nextCap = entryLen + 16;
            scratchRow0 = Int32List(nextCap);
            scratchRow1 = Int32List(nextCap);
            scratchRow2 = Int32List(nextCap);
          }

          final dist = _damerauLevenshteinFast(
            qUnits,
            eUnits,
            scratchRow0,
            scratchRow1,
            scratchRow2,
            maxAllowedDist: maxAllowedDist,
          );
          if (dist > maxAllowedDist) continue;

          final damSim = maxLen == 0 ? 1.0 : 1.0 - (dist / maxLen);
          final combined = math.max(damSim, (damSim * 0.72) + (diceSim * 0.28));
          if (combined >= effectiveMin) {
            recordCandidate(pEntry.entry, combined);
            refreshKthFloor();
          }
        }
      }
    }

    final ranked = byPokemonId.values.toList()
      ..sort((a, b) {
        final cmp = b.confidence.compareTo(a.confidence);
        if (cmp != 0) return cmp;
        return a.pokemonId.compareTo(b.pokemonId);
      });
    return ranked.take(limit).toList(growable: false);
  }

  /// Extracts individual tokens (and adjacent token bigrams) from an OCR [line],
  /// filters emulator UI / dialogue stop-words, and returns ranked Top-[limit] matches.
  List<FuzzyMatchResult> matchTokensFromLine(
    String line, {
    int limit = 3,
    double threshold = 0.72,
  }) {
    if (line.trim().isEmpty || limit <= 0) return const [];

    final rawTokens = line.trim().split(RegExp(r'\s+'));
    final cleanTokens = <String>[];

    for (final raw in rawTokens) {
      final cleaned = _cleanQuery(raw);
      if (cleaned.isEmpty) continue;
      // Ignore counters like "110/601", "150/204", versions like "1.1"
      if (RegExp(r'^[\d/.,:\-\[\]()]+$').hasMatch(cleaned)) continue;

      final norm = _normalizeKey(cleaned);
      final minTokenLen = _cjkRegExp.hasMatch(cleaned) ? 2 : 3;
      if (norm.length < minTokenLen || _noiseStopWords.contains(norm)) continue;

      // Require at least 3 alphabetic characters (or 2 for CJK) per token
      final letterCount = _letterRegExp.allMatches(cleaned).length;
      if (letterCount < minTokenLen) continue;

      cleanTokens.add(cleaned);
    }

    final cjkCandidates = _extractCjkExactCandidates(line);
    if (cleanTokens.isEmpty && cjkCandidates.isEmpty) return const [];

    final probeStrings = <String>[...cleanTokens];
    for (int i = 0; i < cleanTokens.length - 1; i++) {
      probeStrings.add('${cleanTokens[i]} ${cleanTokens[i + 1]}');
    }

    final merged = <int, FuzzyMatchResult>{};
    for (final cand in cjkCandidates) {
      final existing = merged[cand.pokemonId];
      if (existing == null || cand.confidence > existing.confidence) {
        merged[cand.pokemonId] = cand;
      }
    }
    for (final probe in probeStrings) {
      final candidates = matchTopK(probe, limit: limit, threshold: threshold);
      for (final cand in candidates) {
        final existing = merged[cand.pokemonId];
        if (existing == null || cand.confidence > existing.confidence) {
          merged[cand.pokemonId] = cand;
        }
      }
    }

    final sorted = merged.values.toList()
      ..sort((a, b) {
        final cmp = b.confidence.compareTo(a.confidence);
        if (cmp != 0) return cmp;
        return a.pokemonId.compareTo(b.pokemonId);
      });
    return sorted.take(limit).toList(growable: false);
  }

  /// Extracts up to [maxPokemon] non-overlapping Pokémon from multi-encounter dialogue
  /// or opponent HUD lines while preserving appearance order and deduplicating species IDs.
  List<FuzzyMatchResult> matchAllFromText(
    String text, {
    int maxPokemon = 5,
    double threshold = 0.78,
  }) {
    if (text.trim().isEmpty || maxPokemon <= 0) return const [];

    final rawTokens = text.trim().split(RegExp(r'\s+'));
    final cleanTokens = <String>[];
    for (final raw in rawTokens) {
      // Strip trailing level markers attached without space like "ZurrokexLv16" -> "Zurrokex"
      var token = raw.replaceAll(RegExp(r'Lv\.?\d*$', caseSensitive: false), '');
      final cleaned = _cleanQuery(token);
      if (cleaned.isEmpty) continue;
      if (RegExp(r'^[\d/.,:\-\[\]()]+$').hasMatch(cleaned)) continue;
      final norm = _normalizeKey(cleaned);
      final minTokenLen = _cjkRegExp.hasMatch(cleaned) ? 2 : 3;
      if (norm.length < minTokenLen || _noiseStopWords.contains(norm)) continue;
      if (_letterRegExp.allMatches(cleaned).length < minTokenLen) continue;
      cleanTokens.add(cleaned);
    }

    final cjkCandidates = _extractCjkExactCandidates(text);
    if (cleanTokens.isEmpty && cjkCandidates.isEmpty) return const [];

    final seenIds = <int>{};
    final orderedResults = <FuzzyMatchResult>[];

    for (final cjkHit in cjkCandidates) {
      if (orderedResults.length >= maxPokemon) break;
      if (seenIds.add(cjkHit.pokemonId)) {
        orderedResults.add(cjkHit);
      }
    }

    int i = 0;
    while (i < cleanTokens.length && orderedResults.length < maxPokemon) {
      final singleMatch = matchTopK(
        cleanTokens[i],
        limit: 1,
        threshold: threshold,
      ).firstOrNull;

      FuzzyMatchResult? bigramMatch;
      if (i + 1 < cleanTokens.length) {
        bigramMatch = matchTopK(
          '${cleanTokens[i]} ${cleanTokens[i + 1]}',
          limit: 1,
          threshold: threshold,
        ).firstOrNull;
      }

      if (bigramMatch != null &&
          (singleMatch == null ||
              bigramMatch.confidence > singleMatch.confidence + 0.03)) {
        if (seenIds.add(bigramMatch.pokemonId)) {
          orderedResults.add(bigramMatch);
        }
        i += 2;
      } else if (singleMatch != null) {
        if (seenIds.add(singleMatch.pokemonId)) {
          orderedResults.add(singleMatch);
        }
        i += 1;
      } else {
        i += 1;
      }
    }

    return List.unmodifiable(orderedResults);
  }

  /// Extracts non-overlapping CJK Pokémon names in appearance order from unspaced runs
  /// using longest-match-first lookup against [_exactMap].
  List<FuzzyMatchResult> _extractCjkExactCandidates(String input) {
    if (!_cjkRegExp.hasMatch(input)) return const [];
    final results = <FuzzyMatchResult>[];
    final seenIds = <int>{};

    for (final runMatch in _cjkRunRegExp.allMatches(input)) {
      final run = runMatch.group(0)!;
      int pos = 0;
      while (pos <= run.length - 2) {
        final maxSpan = math.min(8, run.length - pos);
        PokemonMatcherEntry? hit;
        int hitLen = 0;
        for (int len = maxSpan; len >= 2; len--) {
          final sub = run.substring(pos, pos + len);
          if (_noiseStopWords.contains(sub)) continue;
          final entries = _exactMap[sub];
          if (entries != null && entries.isNotEmpty) {
            hit = entries.first;
            hitLen = len;
            break;
          }
        }
        if (hit != null) {
          if (seenIds.add(hit.id)) {
            results.add(
              FuzzyMatchResult(
                pokemonId: hit.id,
                canonicalName: hit.name,
                matchedLanguage: hit.language,
                confidence: 1.0,
              ),
            );
          }
          pos += hitLen;
        } else {
          pos += 1;
        }
      }
    }
    return results;
  }

  static String _cleanQuery(String raw) {
    return raw
        .replaceAll(RegExp(r'''[!?,.:;"'`’•·_«»‹›\[\]\(\)]+'''), '')
        .trim();
  }

  static String _normalizeKey(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'[\s\-–—]+'), '');
  }

  static List<String> _ocrVariants(String s) {
    final base = _substituteOcrGlitches(s, oneAsL: false);
    final oneAsL = _substituteOcrGlitches(s, oneAsL: true);
    final digraphFixed = oneAsL
        .replaceAll('rn', 'm')
        .replaceAll('rl', 'n')
        .replaceAll('ri', 'n')
        .replaceAll('np', 'mp')
        .replaceAll('cl', 'd');
    return {base, oneAsL, digraphFixed}.toList(growable: false);
  }

  static String _substituteOcrGlitches(String s, {bool oneAsL = false}) {
    return s
        .replaceAll('4', 'a')
        .replaceAll('@', 'a')
        .replaceAll('0', 'o')
        .replaceAll('1', oneAsL ? 'l' : 'i')
        .replaceAll('vv', 'w')
        .replaceAll(r'$', 's');
  }

  /// Allocation-free rolling Optimal String Alignment (Damerau-Levenshtein)
  /// with optional [maxAllowedDist] early-abort pruning.
  static int _damerauLevenshteinFast(
    Uint16List a,
    Uint16List b,
    Int32List row0,
    Int32List row1,
    Int32List row2, {
    int? maxAllowedDist,
  }) {
    final la = a.length;
    final lb = b.length;
    if (la == 0) return lb;
    if (lb == 0) return la;

    for (int j = 0; j <= lb; j++) {
      row1[j] = j;
    }

    var prevPrev = row0;
    var prev = row1;
    var curr = row2;

    for (int i = 1; i <= la; i++) {
      curr[0] = i;
      int rowMin = i;
      final ai = a[i - 1];
      final aiPrev = i > 1 ? a[i - 2] : 0;

      for (int j = 1; j <= lb; j++) {
        final bj = b[j - 1];
        final cost = ai == bj ? 0 : 1;
        int best = prev[j] + 1;
        final ins = curr[j - 1] + 1;
        if (ins < best) best = ins;
        final sub = prev[j - 1] + cost;
        if (sub < best) best = sub;

        if (i > 1 && j > 1 && ai == b[j - 2] && aiPrev == bj) {
          final trans = prevPrev[j - 2] + 1;
          if (trans < best) best = trans;
        }
        curr[j] = best;
        if (best < rowMin) rowMin = best;
      }

      if (maxAllowedDist != null && rowMin > maxAllowedDist) {
        return maxAllowedDist + 1;
      }

      final tmp = prevPrev;
      prevPrev = prev;
      prev = curr;
      curr = tmp;
    }
    return prev[lb];
  }

  static double _trigramDiceFast(Int64List a, Int64List b) {
    final lenA = a.length;
    final lenB = b.length;
    if (lenA == 0 || lenB == 0) return 0.0;

    int i = 0;
    int j = 0;
    int intersection = 0;
    while (i < lenA && j < lenB) {
      final va = a[i];
      final vb = b[j];
      if (va == vb) {
        intersection++;
        i++;
        j++;
      } else if (va < vb) {
        i++;
      } else {
        j++;
      }
    }
    return (2.0 * intersection) / (lenA + lenB);
  }

  static Int64List _packedTrigrams(String padded) {
    final count = padded.length - 2;
    if (count <= 0) return Int64List(0);
    final result = Int64List(count);
    for (int i = 0; i < count; i++) {
      result[i] = ((padded.codeUnitAt(i) & 0xFFFF) << 32) |
          ((padded.codeUnitAt(i + 1) & 0xFFFF) << 16) |
          (padded.codeUnitAt(i + 2) & 0xFFFF);
    }
    result.sort();
    return result;
  }
}

class _PreparedEntry {
  final PokemonMatcherEntry entry;
  final String normKey;
  final Uint16List codeUnits;
  final Int64List trigrams;

  const _PreparedEntry({
    required this.entry,
    required this.normKey,
    required this.codeUnits,
    required this.trigrams,
  });
}

class _QueryProfile {
  final String norm;
  final Uint16List codeUnits;
  final Int64List trigrams;

  const _QueryProfile({
    required this.norm,
    required this.codeUnits,
    required this.trigrams,
  });
}
