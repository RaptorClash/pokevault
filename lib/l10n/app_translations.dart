import 'translations_de.dart';
import 'translations_en.dart';

class Translator {
  static String currentLanguage = 'de';

  static final Map<String, Map<String, String>> _translations = {
    'de': translationsDe,
    'en': translationsEn,
  };

  static String get(String key) {
    if (_translations[currentLanguage]?.containsKey(key) ?? false) {
      return _translations[currentLanguage]![key]!;
    }

    if (currentLanguage == 'de') {
      String translated = key;
      if (translated.startsWith('loc_')) {
        translated = translated.substring(4);
      }

      translated = translated.replaceAll('(Starter)', '(Starter)');
      translated = translated.replaceAll('(Gift)', '(Geschenk)');
      translated = translated.replaceAll('(Trade)', '(Tausch)');
      translated = translated.replaceAll('(Fly)', '(Fliegen)');
      translated = translated.replaceAll('(Surf)', '(Surfer)');
      translated = translated.replaceAll('(Old Rod)', '(Angel)');
      translated = translated.replaceAll('(Good Rod)', '(Profiangel)');
      translated = translated.replaceAll('(Super Rod)', '(Superangel)');
      translated = translated.replaceAll('(Fossil)', '(Fossil)');
      translated = translated.replaceAll('(Egg)', '(Ei)');

      // Entwicklungen & Items
      translated = translated.replaceAll('Water Stone', 'Wasserstein');
      translated = translated.replaceAll('Fire Stone', 'Feuerstein');
      translated = translated.replaceAll('Thunder Stone', 'Donnerstein');
      translated = translated.replaceAll('Leaf Stone', 'Blattstein');
      translated = translated.replaceAll('Moon Stone', 'Mondstein');
      translated = translated.replaceAll('Sun Stone', 'Sonnenstein');

      translated = translated.replaceAll('Trade', 'Tausch');
      translated = translated.replaceAll('Friendship', 'Zuneigung');
      translated = translated.replaceAll('Day', 'Tag');
      translated = translated.replaceAll('Night', 'Nacht');
      translated = translated.replaceAll('Atk', 'Angriff');
      translated = translated.replaceAll('Def', 'Vert.');
      translated = translated.replaceAll('w/', 'mit');

      if (translated.contains('Max Den')) {
        translated = translated.replaceAll('Max Den', 'Dyna-Nest');
      }

      if (translated.startsWith('Friend Safari')) {
        translated = translated.replaceFirst('Friend Safari', 'Kontaktsafari');
        translated = translated.replaceAll('Grass', 'Pflanze');
        translated = translated.replaceAll('Fire', 'Feuer');
        translated = translated.replaceAll('Water', 'Wasser');
        translated = translated.replaceAll('Bug', 'Käfer');
        translated = translated.replaceAll('Poison', 'Gift');
        translated = translated.replaceAll('Flying', 'Flug');
        translated = translated.replaceAll('Ground', 'Boden');
        translated = translated.replaceAll('Fairy', 'Fee');
        translated = translated.replaceAll('Electric', 'Elektro');
        translated = translated.replaceAll('Fighting', 'Kampf');
        translated = translated.replaceAll('Rock', 'Gestein');
        translated = translated.replaceAll('Ice', 'Eis');
        translated = translated.replaceAll('Psychic', 'Psycho');
        translated = translated.replaceAll('Steel', 'Stahl');
        translated = translated.replaceAll('Dragon', 'Drache');
        translated = translated.replaceAll('Normal', 'Normal');
        translated = translated.replaceAll('Ghost', 'Geist');
        translated = translated.replaceAll('Dark', 'Unlicht');
      }

      translated = translated.replaceAll(RegExp(r'\b1f\b'), 'EG');
      translated = translated.replaceAll(RegExp(r'\b2f\b'), '1. OG');
      translated = translated.replaceAll(RegExp(r'\b3f\b'), '2. OG');
      translated = translated.replaceAll(RegExp(r'\b4f\b'), '3. OG');
      translated = translated.replaceAll(RegExp(r'\b5f\b'), '4. OG');
      translated = translated.replaceAll(RegExp(r'\b6f\b'), '5. OG');
      translated = translated.replaceAll(RegExp(r'\b7f\b'), '6. OG');
      translated = translated.replaceAll(RegExp(r'\bB1f\b'), 'U1');
      translated = translated.replaceAll(RegExp(r'\bB2f\b'), 'U2');
      translated = translated.replaceAll(RegExp(r'\bB3f\b'), 'U3');
      translated = translated.replaceAll(RegExp(r'\bB4f\b'), 'U4');

      baseLocationTranslationsDe.forEach((eng, ger) {
        if (translated.contains(eng)) {
          translated = translated.replaceAll(eng, ger);
        }
      });

      return translated;
    }

    if (key.startsWith('loc_')) {
      return key.substring(4);
    }

    return key;
  }
}