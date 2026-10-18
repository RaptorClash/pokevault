import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:pokevault/widgets/dialogs/downgrade_dialog.dart';
import 'package:pokevault/utils/update_helper.dart';
import 'package:pokevault/l10n/app_translations.dart';
import 'package:pokevault/providers/dex_provider.dart';

class MockDexProvider extends Mock implements DexProvider {}

void main() {
  group('DowngradeDialog State-Maschine', () {
    final mockRelease = UpdateInfo(
      version: '1.0.0',
      title: 'Alte Version',
      releaseNotes: 'Das ist ein Downgrade.',
      downloadUrl: 'https://test.com',
      extension: '.apk',
    );

    testWidgets(
      'Durchläuft Info -> Backup -> Warnung beim Tippen der Buttons',
      (WidgetTester tester) async {
        Translator.currentLanguage = 'de';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: DowngradeDialog(releaseInfo: mockRelease)),
          ),
        );

        final executeButton = find.text('Downgrade ausführen');
        expect(executeButton, findsOneWidget);
        expect(find.text('Alte Version (1.0.0)'), findsOneWidget);

        await tester.tap(executeButton);
        await tester.pumpAndSettle();

        final skipBackupButton = find.text('Ohne Backup fortfahren');
        expect(skipBackupButton, findsOneWidget);

        await tester.tap(skipBackupButton);
        await tester.pumpAndSettle();

        expect(find.text('Letzte Warnung'), findsOneWidget);
        expect(find.text('Ja, Downgrade starten'), findsOneWidget);
      },
    );

    testWidgets(
      'Zurück-Knopf im Backup-Schritt navigiert zurück zum Info-Schritt',
      (WidgetTester tester) async {
        Translator.currentLanguage = 'de';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: DowngradeDialog(releaseInfo: mockRelease)),
          ),
        );

        // Gehe zu Backup
        await tester.tap(find.text('Downgrade ausführen'));
        await tester.pumpAndSettle();

        expect(find.text('Vorher Backup erstellen?'), findsOneWidget);
        final backButton = find.text('Zurück');
        expect(backButton, findsOneWidget);

        // Klicke Zurück
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        // Wieder auf Info-Screen
        expect(find.text('Alte Version (1.0.0)'), findsOneWidget);
        expect(find.text('Downgrade ausführen'), findsOneWidget);
      },
    );

    testWidgets(
      'Zurück-Knopf im FinalWarning-Schritt navigiert zurück zum Backup-Schritt',
      (WidgetTester tester) async {
        Translator.currentLanguage = 'de';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: DowngradeDialog(releaseInfo: mockRelease)),
          ),
        );

        await tester.tap(find.text('Downgrade ausführen'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Ohne Backup fortfahren'));
        await tester.pumpAndSettle();

        expect(find.text('Letzte Warnung'), findsOneWidget);
        final backButton = find.text('Zurück');
        expect(backButton, findsOneWidget);

        // Klicke Zurück
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        // Wieder auf Backup-Schritt
        expect(find.text('Vorher Backup erstellen?'), findsOneWidget);
        expect(find.text('Ohne Backup fortfahren'), findsOneWidget);
      },
    );

    testWidgets(
      'Release Notes im DowngradeDialog werden nach Sprache gefiltert',
      (WidgetTester tester) async {
        Translator.currentLanguage = 'de';

        final multiLangRelease = UpdateInfo(
          version: '1.0.0',
          title: 'Alte Version',
          releaseNotes: '''
## 🇬🇧 English
English notes for downgrade.

## 🇩🇪 Deutsch
Deutsche Notizen für Downgrade.
''',
          downloadUrl: 'https://test.com',
          extension: '.apk',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: DowngradeDialog(releaseInfo: multiLangRelease)),
          ),
        );

        expect(find.text('Deutsche Notizen für Downgrade.'), findsOneWidget);
        expect(find.text('English notes for downgrade.'), findsNothing);
      },
    );

    testWidgets(
      'Backup-Button im Backup-Schritt führt Backup aus und wechselt zu Letzte Warnung',
      (WidgetTester tester) async {
        Translator.currentLanguage = 'de';
        final mockDexProvider = MockDexProvider();
        when(() => mockDexProvider.userDexes).thenReturn([]);

        await tester.pumpWidget(
          MaterialApp(
            home: ChangeNotifierProvider<DexProvider>.value(
              value: mockDexProvider,
              child: Scaffold(body: DowngradeDialog(releaseInfo: mockRelease)),
            ),
          ),
        );

        await tester.tap(find.text('Downgrade ausführen'));
        await tester.pumpAndSettle();

        expect(find.text('Vorher Backup erstellen?'), findsOneWidget);
        final backupBtn = find.text('Backup erstellen');
        expect(backupBtn, findsOneWidget);

        await tester.tap(backupBtn);
        await tester.pumpAndSettle();

        expect(find.text('Letzte Warnung'), findsOneWidget);
      },
    );

    testWidgets(
      'Release Notes im DowngradeDialog behalten Zeilenumbrüche (softLineBreak)',
      (WidgetTester tester) async {
        final lineBreakRelease = UpdateInfo(
          version: '1.4.0',
          title: 'V1.4.0',
          releaseNotes:
              'Added information for some gen1 and gen2 pokemon\n'
              'enhanced shiny breeding chain for gen2\n'
              'added native android and windows updater for app',
          downloadUrl: 'https://test.com',
          extension: '.apk',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: DowngradeDialog(releaseInfo: lineBreakRelease)),
          ),
        );

        final markdownFinder = find.byType(MarkdownBody);
        expect(markdownFinder, findsOneWidget);
        final markdownWidget = tester.widget<MarkdownBody>(markdownFinder);
        expect(markdownWidget.softLineBreak, isTrue);

        expect(
          find.textContaining(
            'Added information for some gen1 and gen2 pokemon\n'
            'enhanced shiny breeding chain for gen2\n'
            'added native android and windows updater for app',
          ),
          findsOneWidget,
        );

        expect(
          find.textContaining(
            'Added information for some gen1 and gen2 pokemon enhanced shiny breeding chain',
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'Release Notes im DowngradeDialog mit CRLF (\\r\\n) behalten Zeilenumbrüche',
      (WidgetTester tester) async {
        final crlfRelease = UpdateInfo(
          version: '1.4.0',
          title: 'V1.4.0',
          releaseNotes:
              "Added information for some gen1 and gen2 pokemon\r\n"
              "enhanced shiny breeding chain for gen2\r\n"
              "added native android and windows updater for app",
          downloadUrl: 'https://test.com',
          extension: '.apk',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: DowngradeDialog(releaseInfo: crlfRelease)),
          ),
        );

        expect(
          find.textContaining(
            'Added information for some gen1 and gen2 pokemon\n'
            'enhanced shiny breeding chain for gen2\n'
            'added native android and windows updater for app',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Release Notes im DowngradeDialog rendert leere Notes ohne Fehler',
      (WidgetTester tester) async {
        final emptyRelease = UpdateInfo(
          version: '1.4.0',
          title: 'V1.4.0',
          releaseNotes: '',
          downloadUrl: 'https://test.com',
          extension: '.apk',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: DowngradeDialog(releaseInfo: emptyRelease)),
          ),
        );

        expect(find.byType(MarkdownBody), findsOneWidget);
      },
    );

    testWidgets(
      'Release Notes im DowngradeDialog rendert Listen mit softLineBreak korrekt',
      (WidgetTester tester) async {
        final listRelease = UpdateInfo(
          version: '1.4.0',
          title: 'V1.4.0',
          releaseNotes:
              "* Erstes Feature\n"
              "* Zweites Feature\n"
              "* Drittes Feature",
          downloadUrl: 'https://test.com',
          extension: '.apk',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: DowngradeDialog(releaseInfo: listRelease)),
          ),
        );

        expect(find.textContaining('Erstes Feature'), findsOneWidget);
        expect(find.textContaining('Zweites Feature'), findsOneWidget);
        expect(find.textContaining('Drittes Feature'), findsOneWidget);
      },
    );
  });
}
