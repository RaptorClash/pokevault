import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/utils/update_helper.dart';

void main() {
  group('UpdateHelper & UpdateInfo Tests', () {
    test('UpdateInfo Model speichert und mappt Daten korrekt', () {
      final info = UpdateInfo(
        version: 'v1.2.3',
        title: 'Neues Update',
        releaseNotes: 'Viele Fixes',
        downloadUrl: 'https://github.com/test.zip',
        extension: '.zip',
      );

      expect(info.version, equals('v1.2.3'));
      expect(info.title, equals('Neues Update'));
      expect(info.extension, equals('.zip'));
      expect(info.downloadUrl, equals('https://github.com/test.zip'));
    });
  });

  group('UpdateHelper.filterReleaseNotes Tests', () {
    const rawMultiLangNotes = '''
# PokéVault v1.5 Release Notes

## 🇬🇧 English

**New Features**
* **Catch Rate Calculator:** Great feature!
* **Route Tracker:** Directly in dex.

### Bug Fixes
* Fixed crash on start.

## 🇩🇪 Deutsch

**Neue Funktionen**
* **Fangraten-Rechner:** Tolles Feature!
* **Routen-Tracker:** Direkt im Pokédex.

### Fehlerbehebungen
* Absturz beim Start behoben.

**Full Changelog**: https://github.com/RaptorClash/pokevault/compare/v1.4.1...v1.5.0
''';

    test('gibt Originaltext zurück, wenn keine Sprach-Überschriften vorhanden sind', () {
      const plainNotes = 'Einfache Release Notes ohne Sprachsektionen.\n- Fix 1\n- Fix 2';
      expect(UpdateHelper.filterReleaseNotes(plainNotes, 'de'), equals(plainNotes));
      expect(UpdateHelper.filterReleaseNotes(plainNotes, 'en'), equals(plainNotes));
    });

    test('normalisiert CRLF (\\r\\n) zu LF (\\n), wenn keine Sprach-Überschriften vorhanden sind', () {
      const crlfPlainNotes = "Zeile 1\r\nZeile 2\r\nZeile 3";
      expect(UpdateHelper.filterReleaseNotes(crlfPlainNotes, 'de'), equals("Zeile 1\nZeile 2\nZeile 3"));
    });

    test('gibt leeren String zurück bei leerem Input', () {
      expect(UpdateHelper.filterReleaseNotes('', 'de'), equals(''));
      expect(UpdateHelper.filterReleaseNotes('   \n  ', 'de'), equals('   \n  '));
    });

    test('filtert deutsche Sektion heraus, wenn Sprache de ist', () {
      final filtered = UpdateHelper.filterReleaseNotes(rawMultiLangNotes, 'de');

      expect(filtered, contains('# PokéVault v1.5 Release Notes'));
      expect(filtered, contains('## 🇩🇪 Deutsch'));
      expect(filtered, contains('Fangraten-Rechner'));
      expect(filtered, contains('Fehlerbehebungen'));
      expect(filtered, contains('**Full Changelog**:'));

      // Darf keinen englischen Inhalt enthalten
      expect(filtered.contains('## 🇬🇧 English'), isFalse);
      expect(filtered.contains('Catch Rate Calculator'), isFalse);
    });

    test('filtert englische Sektion heraus, wenn Sprache en ist', () {
      final filtered = UpdateHelper.filterReleaseNotes(rawMultiLangNotes, 'en');

      expect(filtered, contains('# PokéVault v1.5 Release Notes'));
      expect(filtered, contains('## 🇬🇧 English'));
      expect(filtered, contains('Catch Rate Calculator'));
      expect(filtered, contains('Bug Fixes'));
      expect(filtered, contains('**Full Changelog**:'));

      // Darf keinen deutschen Inhalt enthalten
      expect(filtered.contains('## 🇩🇪 Deutsch'), isFalse);
      expect(filtered.contains('Fangraten-Rechner'), isFalse);
    });

    test('fällt auf Englisch zurück, wenn Zielsprache nicht in den Notes existiert (z. B. fr)', () {
      final filtered = UpdateHelper.filterReleaseNotes(rawMultiLangNotes, 'fr');

      expect(filtered, contains('## 🇬🇧 English'));
      expect(filtered, contains('Catch Rate Calculator'));
      expect(filtered.contains('## 🇩🇪 Deutsch'), isFalse);
    });

    test('fällt auf erste verfügbare Sektion zurück, wenn weder Ziel noch Englisch vorhanden ist', () {
      const germanOnlyNotes = '''
## 🇩🇪 Deutsch
Nur deutsche Notizen.
''';
      final filtered = UpdateHelper.filterReleaseNotes(germanOnlyNotes, 'es');
      expect(filtered, contains('## 🇩🇪 Deutsch'));
      expect(filtered, contains('Nur deutsche Notizen.'));
    });

    test('erkennt verschiedene Heading-Formate (German, Deutsch, [DE], [EN], Flaggen)', () {
      const altNotes = '''
# Info
## German
Deutscher Text.

## English
English text.
''';
      expect(UpdateHelper.filterReleaseNotes(altNotes, 'de'), contains('Deutscher Text.'));
      expect(UpdateHelper.filterReleaseNotes(altNotes, 'de').contains('English text.'), isFalse);
      expect(UpdateHelper.filterReleaseNotes(altNotes, 'en'), contains('English text.'));
      expect(UpdateHelper.filterReleaseNotes(altNotes, 'en').contains('Deutscher Text.'), isFalse);
    });

    test('funktioniert mit h1 Sprach-Headings (# 🇬🇧 English / # 🇩🇪 Deutsch)', () {
      const h1Notes = '''
# 🇬🇧 English
English details.

# 🇩🇪 Deutsch
Deutsche Details.
''';
      expect(UpdateHelper.filterReleaseNotes(h1Notes, 'de'), contains('Deutsche Details.'));
      expect(UpdateHelper.filterReleaseNotes(h1Notes, 'de').contains('English details.'), isFalse);
    });

    test('normalisiert Locale-Codes wie de_DE oder de-AT auf de', () {
      expect(UpdateHelper.filterReleaseNotes(rawMultiLangNotes, 'de_DE'), contains('Fangraten-Rechner'));
      expect(UpdateHelper.filterReleaseNotes(rawMultiLangNotes, 'de-AT'), contains('Fangraten-Rechner'));
      expect(UpdateHelper.filterReleaseNotes(rawMultiLangNotes, 'en_US'), contains('Catch Rate Calculator'));
    });

    test('entfernt Trennlinien (---) zwischen Sektionen am Ende der Sprachnotiz', () {
      const notesWithDivider = '''
# Notes
## 🇬🇧 English
English line.

---

## 🇩🇪 Deutsch
Deutsche Zeile.
''';
      final filteredEn = UpdateHelper.filterReleaseNotes(notesWithDivider, 'en');
      expect(filteredEn.trim().endsWith('---'), isFalse);
      expect(filteredEn, contains('English line.'));
    });

    test('erkennt spanische/französische Titel mit Präposition "de" nicht fälschlich als Deutsch', () {
      const multiLangWithSpanish = '''
# Notes
## 🇪🇸 Notas de la versión
Contenido en español.

## 🇩🇪 Deutsch
Deutscher Inhalt.
''';
      // Spanisch darf nicht als de geparst werden
      final filteredEs = UpdateHelper.filterReleaseNotes(multiLangWithSpanish, 'es');
      expect(filteredEs, contains('Contenido en español.'));

      final filteredDe = UpdateHelper.filterReleaseNotes(multiLangWithSpanish, 'de');
      expect(filteredDe, contains('Deutscher Inhalt.'));
      expect(filteredDe.contains('Contenido en español.'), isFalse);
    });

    test('funktioniert mit Windows CRLF (\\r\\n) Zeilenumbrüchen', () {
      const crlfNotes = "# Notes\r\n\r\n## 🇬🇧 English\r\nLine 1\r\n\r\n## 🇩🇪 Deutsch\r\nZeile 1\r\n";
      final filtered = UpdateHelper.filterReleaseNotes(crlfNotes, 'de');
      expect(filtered, contains('Zeile 1'));
      expect(filtered.contains('Line 1'), isFalse);
    });

    test('erkennt und filtert alle 13 Sprachen in aufklappbaren <details><summary>-Blöcken', () {
      const collapsibleNotes = '''
# PokéVault v1.7.0 Release Notes — "The Language Expansion"

<details>
<summary>🇬🇧 <b>English</b></summary>

**New Features**
* Great English feature.

</details>

<details>
<summary>🇩🇪 <b>Deutsch</b></summary>

**Neue Funktionen**
* Tolles deutsches Feature.

</details>

<details>
<summary>🇫🇷 <b>Français</b></summary>

**Nouvelles fonctionnalités**
* Fonctionnalité française.

</details>

<details>
<summary>🇯🇵 <b>日本語</b></summary>

**新機能**
* 日本語の機能。

</details>

<details>
<summary>🇰🇷 <b>한국어</b></summary>

**새로운 기능**
* 한국어 기능.

</details>

<details>
<summary>🇨🇳 <b>简体中文</b></summary>

**新功能**
* 简体中文功能。

</details>

<details>
<summary>🇹🇼 <b>繁體中文</b></summary>

**新功能**
* 繁體中文功能。

</details>

<details>
<summary>🇵🇹 <b>Português</b></summary>

**Novos Recursos**
* Recurso em português.

</details>

<details>
<summary>🇳🇱 <b>Nederlands</b></summary>

**Nieuwe functies**
* Nederlandse functie.

</details>

<details>
<summary>🇵🇱 <b>Polski</b></summary>

**Nowe funkcje**
* Polska funkcja.

</details>

<details>
<summary>🇷🇺 <b>Русский</b></summary>

**Новые возможности**
* Русская функция.

</details>
''';

      // Test German
      final filteredDe = UpdateHelper.filterReleaseNotes(collapsibleNotes, 'de');
      expect(filteredDe, contains('Tolles deutsches Feature.'));
      expect(filteredDe.contains('Great English feature.'), isFalse);
      expect(filteredDe.contains('<details>'), isFalse);
      expect(filteredDe.contains('</details>'), isFalse);
      expect(filteredDe.contains('<summary>'), isFalse);

      // Test Korean
      final filteredKo = UpdateHelper.filterReleaseNotes(collapsibleNotes, 'ko');
      expect(filteredKo, contains('한국어 기능.'));
      expect(filteredKo.contains('Tolles deutsches Feature.'), isFalse);
      expect(filteredKo.contains('<details>'), isFalse);

      // Test Russian
      final filteredRu = UpdateHelper.filterReleaseNotes(collapsibleNotes, 'ru');
      expect(filteredRu, contains('Русская функция.'));

      // Test Simplified Chinese
      final filteredZhHans = UpdateHelper.filterReleaseNotes(collapsibleNotes, 'zh-Hans');
      expect(filteredZhHans, contains('简体中文功能。'));

      // Test Traditional Chinese
      final filteredZhHant = UpdateHelper.filterReleaseNotes(collapsibleNotes, 'zh-Hant');
      expect(filteredZhHant, contains('繁體中文功能。'));

      // Test Portuguese
      final filteredPt = UpdateHelper.filterReleaseNotes(collapsibleNotes, 'pt');
      expect(filteredPt, contains('Recurso em português.'));

      // Test Dutch
      final filteredNl = UpdateHelper.filterReleaseNotes(collapsibleNotes, 'nl');
      expect(filteredNl, contains('Nederlandse functie.'));

      // Test Polish
      final filteredPl = UpdateHelper.filterReleaseNotes(collapsibleNotes, 'pl');
      expect(filteredPl, contains('Polska funkcja.'));
    });
  });
}
