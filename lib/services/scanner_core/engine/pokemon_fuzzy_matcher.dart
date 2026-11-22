import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';

import 'ocr_noise_stop_words.dart';

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
  static const int _maxCacheEntries = 256;

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
  final Set<String> _availableLanguages = {};
  String? _activeLanguage;
  final LinkedHashMap<String, List<FuzzyMatchResult>> _topKCache =
      LinkedHashMap<String, List<FuzzyMatchResult>>();
  final LinkedHashMap<String, List<({FuzzyMatchResult match, int count})>>
      _matchAllCache =
      LinkedHashMap<String, List<({FuzzyMatchResult match, int count})>>();

  /// Active Pokémon dictionary language filter (`null` = search all languages).
  String? get activeLanguage => _activeLanguage;

  static String? _normalizeLangCode(String? raw) {
    if (raw == null) return null;
    final lower = raw.trim().toLowerCase();
    if (lower.isEmpty || lower == 'auto' || lower == 'all') return null;
    if (lower.startsWith('zh')) {
      return (lower.contains('hant') ||
              lower.contains('tw') ||
              lower.contains('hk'))
          ? 'zh-hant'
          : 'zh-hans';
    }
    return lower.split(RegExp(r'[-_]')).first;
  }

  /// Restricts dictionary matching to [languageCode] (or `null` / `'auto'` for all languages).
  void setActiveLanguage(String? languageCode) {
    final next = _normalizeLangCode(languageCode);
    if (next == _activeLanguage) return;
    _activeLanguage = next;
    clearCache();
  }

  bool _isLanguageAllowed(String entryLanguage) {
    final active = _activeLanguage;
    if (active == null || !_availableLanguages.contains(active)) return true;
    return _normalizeLangCode(entryLanguage) == active;
  }

  /// Number of entries currently held across the LRU query caches.
  int get debugCacheSize => _topKCache.length + _matchAllCache.length;

  /// Clears all cached query results.
  void clearCache() {
    _topKCache.clear();
    _matchAllCache.clear();
  }

  static V? _lruGet<V>(LinkedHashMap<String, V> cache, String key) {
    final hit = cache.remove(key);
    if (hit != null) {
      cache[key] = hit;
    }
    return hit;
  }

  static void _lruPut<V>(LinkedHashMap<String, V> cache, String key, V value) {
    cache.remove(key);
    if (cache.length >= _maxCacheEntries) {
      cache.remove(cache.keys.first);
    }
    cache[key] = value;
  }

  PokemonFuzzyMatcher.withEntries(List<PokemonMatcherEntry> entries)
      : _entries = entries {
    for (final e in _entries) {
      final normLang = _normalizeLangCode(e.language);
      if (normLang != null) {
        _availableLanguages.add(normLang);
      }
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
    if (normKey.isEmpty || OcrNoiseStopWords.all.contains(normKey)) {
      return const [];
    }
    if (!_letterRegExp.hasMatch(normKey)) return const [];

    final cacheKey =
        '${_activeLanguage ?? 'all'}|$normKey|$limit|${threshold.toStringAsFixed(2)}';
    final cached = _lruGet(_topKCache, cacheKey);
    if (cached != null) return cached;

    final byPokemonId = <int, FuzzyMatchResult>{};

    void recordCandidate(PokemonMatcherEntry entry, double score) {
      if (!_isLanguageAllowed(entry.language)) return;
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
      final exactOut = List<FuzzyMatchResult>.unmodifiable([sorted.first]);
      _lruPut(_topKCache, cacheKey, exactOut);
      return exactOut;
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

      // Short 2-4 char OCR garbage (e.g. "ikon") requires stricter fuzzy confidence in live scan
      final shortTokenMinFloor = (threshold >= 0.55 && normKey.length <= 4)
          ? (normKey.length <= 3 ? 0.92 : 0.84)
          : threshold;

      // Dynamic Top-K floor tightening once `limit` candidates have been seen
      double currentKthFloor = math.max(threshold, shortTokenMinFloor);
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

      final activeLang = _activeLanguage;
      final filterByLang =
          activeLang != null && _availableLanguages.contains(activeLang);

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
          if (filterByLang &&
              _normalizeLangCode(pEntry.entry.language) != activeLang) {
            continue;
          }
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
    final result = List<FuzzyMatchResult>.unmodifiable(ranked.take(limit));
    _lruPut(_topKCache, cacheKey, result);
    return result;
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
      if (norm.length < minTokenLen || OcrNoiseStopWords.all.contains(norm)) {
        continue;
      }

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
    return matchAllWithCounts(
      text,
      maxPokemon: maxPokemon,
      threshold: threshold,
    ).map((e) => e.match).toList(growable: false);
  }

  /// Extracts up to [maxPokemon] unique Pokémon species in appearance order along
  /// with how many times each species appeared in [text] (e.g. Horde/Double Grass).
  List<({FuzzyMatchResult match, int count})> matchAllWithCounts(
    String text, {
    int maxPokemon = 5,
    double threshold = 0.78,
  }) {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty || maxPokemon <= 0) return const [];

    final cacheKey =
        '${_activeLanguage ?? 'all'}|$trimmedText|$maxPokemon|${threshold.toStringAsFixed(2)}';
    final cached = _lruGet(_matchAllCache, cacheKey);
    if (cached != null) return cached;

    // Separate glued gender/level/HP markers before whitespace tokenization
    // so e.g. "Sleima♀Lv17" or "Zubat♂Lv.15" cleanly isolates "Sleima" / "Zubat".
    final normalizedInput = text
        .replaceAll(RegExp(r'[♂♀]'), ' ')
        .replaceAll(
          RegExp(r'(?<=[A-Za-zÀ-ÿ])(?:Lv|Lvl|Level)\.?\s*\d*', caseSensitive: false),
          ' ',
        )
        .replaceAll(
          RegExp(r'\b(?:KP|HP)\s*\d*(?:/\d+)?\b', caseSensitive: false),
          ' ',
        );

    final rawTokens = normalizedInput.trim().split(RegExp(r'\s+'));
    final cleanTokens = <String>[];
    for (final raw in rawTokens) {
      var token = raw.replaceAll(RegExp(r'Lv\.?\d*$', caseSensitive: false), '');
      final cleaned = _cleanQuery(token);
      if (cleaned.isEmpty) continue;
      if (RegExp(r'^[\d/.,:\-\[\]()]+$').hasMatch(cleaned)) continue;
      final norm = _normalizeKey(cleaned);
      final minTokenLen = _cjkRegExp.hasMatch(cleaned) ? 2 : 3;
      if (norm.length < minTokenLen || OcrNoiseStopWords.all.contains(norm)) {
        continue;
      }
      if (_letterRegExp.allMatches(cleaned).length < minTokenLen) continue;
      cleanTokens.add(cleaned);
    }

    final cjkCandidates = _extractCjkExactCandidates(text);
    if (cleanTokens.isEmpty && cjkCandidates.isEmpty) return const [];

    final orderedIds = <int>[];
    final bestById = <int, FuzzyMatchResult>{};
    final countsById = <int, int>{};

    void recordHit(FuzzyMatchResult hit) {
      final existing = bestById[hit.pokemonId];
      if (existing == null) {
        if (orderedIds.length >= maxPokemon) return;
        orderedIds.add(hit.pokemonId);
        bestById[hit.pokemonId] = hit;
        countsById[hit.pokemonId] = 1;
      } else {
        if (hit.confidence > existing.confidence) {
          bestById[hit.pokemonId] = hit;
        }
        countsById[hit.pokemonId] = (countsById[hit.pokemonId] ?? 1) + 1;
      }
    }

    for (final cjkHit in cjkCandidates) {
      recordHit(cjkHit);
    }

    int i = 0;
    while (i < cleanTokens.length) {
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
        recordHit(bigramMatch);
        i += 2;
      } else if (singleMatch != null) {
        recordHit(singleMatch);
        i += 1;
      } else {
        i += 1;
      }
    }

    final result = List<({FuzzyMatchResult match, int count})>.unmodifiable([
      for (final id in orderedIds)
        (match: bestById[id]!, count: countsById[id] ?? 1),
    ]);
    _lruPut(_matchAllCache, cacheKey, result);
    return result;
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
          if (OcrNoiseStopWords.all.contains(sub)) continue;
          final entries = _exactMap[sub];
          if (entries != null && entries.isNotEmpty) {
            for (final e in entries) {
              if (_isLanguageAllowed(e.language)) {
                hit = e;
                hitLen = len;
                break;
              }
            }
            if (hit != null) break;
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
    final twoAsZ = oneAsL.startsWith('2') ? 'z${oneAsL.substring(1)}' : oneAsL;
    final digraphFixed = oneAsL
        .replaceAll('rn', 'm')
        .replaceAll('rl', 'n')
        .replaceAll('ri', 'n')
        .replaceAll('np', 'mp')
        .replaceAll('cl', 'd');
    return {base, oneAsL, twoAsZ, digraphFixed}.toList(growable: false);
  }

  static String _substituteOcrGlitches(String s, {bool oneAsL = false}) {
    return s
        .replaceAll('4', 'a')
        .replaceAll('@', 'a')
        .replaceAll('0', 'o')
        .replaceAll('1', oneAsL ? 'l' : 'i')
        .replaceAll('|', oneAsL ? 'l' : 'i')
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
