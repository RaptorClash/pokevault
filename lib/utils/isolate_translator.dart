import '../i18n/strings.g.dart';

/// Pure-Dart translation bridge for background isolates (compute()).
/// Does not depend on Flutter UI context, WidgetsBinding, or BuildContext.
class IsolateTranslator {
  final String language;
  final Translations _translations;

  IsolateTranslator([String language = 'de'])
      : language = language.toLowerCase(),
        _translations = (language.toLowerCase() == 'en' ? AppLocale.en : AppLocale.de).build();

  bool get isDe => language == 'de';

  /// Resolves any translation key.
  String get(String key, {String? fallback}) {
    if (key == 'box') return boxLabel;
    if (key == 'cat_gifts') return giftsLabel;
    if (key == 'cat_trades') return tradesLabel;
    if (key.startsWith('cat_')) {
      final catId = key.substring(4);
      final catName = getCategoryName(catId);
      if (catName != catId) return catName;
    }

    final normalized = key.replaceAll('-', '_');
    final val = _translations[key] ?? _translations[normalized];
    if (val != null) {
      return val.toString();
    }
    return fallback ?? key;
  }

  /// Resolves canonical region name (e.g. 'unova' -> 'Einall' / 'Unova').
  String getRegionName(String regionId) {
    if (regionId.isEmpty) return '';
    final clean = regionId.toLowerCase();
    final key = 'region_name_$clean';
    final translated = _translations[key]?.toString();
    if (translated != null && translated.isNotEmpty && translated != key) {
      return translated;
    }
    return regionId[0].toUpperCase() + regionId.substring(1);
  }

  /// Resolves localized form display name (e.g. 'primal' -> 'Protomorphose' / 'Primal').
  String getFormDisplayName(String form) {
    if (form.isEmpty) return '';
    final normalized = form.toLowerCase().replaceAll('-', '_');

    if (normalized == 'totem') {
      return isDe ? 'Herrscher' : 'Totem';
    }
    if (normalized == 'original_cap') {
      return 'Original-Cap';
    }
    if (normalized == 'poke_ball') {
      return 'Poké Ball';
    }

    final key = 'form_name_$normalized';
    final translated = _translations[key]?.toString();
    if (translated != null && translated.isNotEmpty && translated != key) {
      return translated;
    }

    return form[0].toUpperCase() + form.substring(1);
  }

  /// Returns fixed label for 'Box'.
  String getBoxLabel() => boxLabel;
  String get boxLabel => _translations['box']?.toString() ?? 'Box';

  /// Returns fixed label for forms ('Formen' in de / 'Forms' in en).
  String getFormsLabel() => formsLabel;
  String get formsLabel => isDe ? 'Formen' : 'Forms';

  /// Returns fixed label for trades ('Tausche' in de / 'Trades' in en).
  String getTradesLabel() => tradesLabel;
  String get tradesLabel => isDe ? 'Tausche' : 'Trades';

  /// Returns fixed label for gifts ('Geschenke' in de / 'Gifts' in en).
  String getGiftsLabel() => giftsLabel;
  String get giftsLabel => isDe ? 'Geschenke' : 'Gifts';

  /// Resolves category display name (e.g. 'trades' -> 'Tausche' / 'Trades').
  String getCategoryName(String catId) {
    switch (catId.toLowerCase()) {
      case 'trades':
        return tradesLabel;
      case 'gifts':
        return giftsLabel;
      case 'orre':
        return 'Colosseum & XD';
      case 'furfrou':
        return isDe ? 'Coiffwaff' : 'Furfrou';
      case 'silvally':
        return isDe ? 'Amigento' : 'Silvally';
      case 'arceus':
        return 'Arceus';
      case 'n_pokemon':
        return "N's Pokémon";
      case 'mega':
        return 'Mega';
      default:
        return catId;
    }
  }

  /// Formats standard sequential box title: e.g. "Box 1 (1-30)"
  String formatStandardBoxTitle(int boxIndex, int start, int end) {
    return '$boxLabel ${boxIndex + 1} ($start-$end)';
  }

  /// Formats form box title: e.g. "Box 5 (Formen)" or "Box 5 (Forms 1)"
  String formatFormBoxTitle(int boxNumber, int chunkIndex, int totalChunks) {
    final label = totalChunks == 1 ? formsLabel : '$formsLabel ${chunkIndex + 1}';
    return '$boxLabel $boxNumber ($label)';
  }

  /// Formats structured category box title according to region and category.
  String formatCategoryBoxTitle(
    String regionId,
    String catId, {
    int chunkIndex = 0,
    int totalChunks = 1,
  }) {
    final localizedRegion = getRegionName(regionId);
    final localizedCat = getCategoryName(catId);
    String baseTitle;

    if (catId == 'n_pokemon') {
      baseTitle = "N's Pokémon";
    } else if (catId == 'trades') {
      if (regionId.toLowerCase() == 'lumiose') {
        baseTitle = '$localizedRegion $tradesLabel (Z-A)';
      } else {
        baseTitle = '$localizedRegion $tradesLabel';
      }
    } else if (catId == 'gifts') {
      baseTitle = '$localizedRegion $giftsLabel';
    } else if (catId == 'orre') {
      baseTitle = '$localizedRegion Colosseum & XD $tradesLabel';
    } else if (catId == 'furfrou') {
      baseTitle = '$localizedRegion ${isDe ? 'Coiffwaff' : 'Furfrou'}';
    } else if (catId == 'arceus') {
      baseTitle = '$localizedRegion Arceus';
    } else if (catId == 'silvally') {
      baseTitle = '$localizedRegion ${isDe ? 'Amigento' : 'Silvally'}';
    } else {
      baseTitle = (catId == 'base') ? localizedRegion : '$localizedRegion $localizedCat';
    }

    return totalChunks == 1 ? baseTitle : '$baseTitle ${chunkIndex + 1}';
  }
}
