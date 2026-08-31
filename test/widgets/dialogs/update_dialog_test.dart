import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/widgets/dialogs/update_dialog.dart';
import 'package:pokevault/utils/update_helper.dart';
import 'package:pokevault/l10n/app_translations.dart';

void main() {
  group('UpdateDialog UI Tests', () {
    final mockUpdate = UpdateInfo(
      version: '2.0.0',
      title: 'Mega Update',
      releaseNotes: 'Neue Features!',
      downloadUrl: 'https://test.com/update.apk',
      extension: '.apk',
    );

    setUp(() {
      Translator.currentLanguage = 'de';
    });

    testWidgets('Zeigt Versionsinfos und Buttons im Initialzustand', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: UpdateDialog(updateInfo: mockUpdate)),
        ),
      );

      expect(find.text('Mega Update (2.0.0)'), findsOneWidget);
      expect(find.text('Neue Features!'), findsOneWidget);

      expect(find.byType(TextButton), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);

      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('Ladebalken erscheint beim Klick auf Download', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: UpdateDialog(updateInfo: mockUpdate)),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      expect(find.byType(TextButton), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);

      for (int i = 0; i < 4; i++) {
        await tester.pump(const Duration(seconds: 2));
      }
    });
  });
}
