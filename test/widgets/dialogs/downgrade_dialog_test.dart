import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/widgets/dialogs/downgrade_dialog.dart';
import 'package:pokevault/utils/update_helper.dart';
import 'package:pokevault/l10n/app_translations.dart';

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
  });
}
