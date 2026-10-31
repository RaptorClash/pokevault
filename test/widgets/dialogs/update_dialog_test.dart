import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:pokevault/widgets/dialogs/update_dialog.dart';
import 'package:pokevault/utils/update_helper.dart';
import 'package:pokevault/i18n/strings.g.dart';
import 'package:pokevault/providers/dex_provider.dart';

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

class _MockHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() => Completer<HttpClientResponse>().future;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockDexProvider extends Mock implements DexProvider {}

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
      HttpOverrides.global = _MockHttpOverrides();
      LocaleSettings.setLocale(AppLocale.de);
    });

    tearDown(() {
      HttpOverrides.global = null;
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
    });

    testWidgets('Zeigt Backup-Button im Warnungs-Kasten an', (
      WidgetTester tester,
    ) async {
      final mockDexProvider = MockDexProvider();
      when(() => mockDexProvider.userDexes).thenReturn([]);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<DexProvider>.value(
            value: mockDexProvider,
            child: Scaffold(body: UpdateDialog(updateInfo: mockUpdate)),
          ),
        ),
      );

      final backupButton = find.text('Backup jetzt erstellen');
      expect(backupButton, findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);

      await tester.tap(backupButton);
      await tester.pumpAndSettle();

      expect(find.text('Backup erstellt ✓'), findsOneWidget);
    });

    testWidgets('Backup-Button setzt backupDone nicht wenn Provider fehlt', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: UpdateDialog(updateInfo: mockUpdate)),
        ),
      );

      final backupButton = find.text('Backup jetzt erstellen');
      expect(backupButton, findsOneWidget);

      await tester.tap(backupButton);
      await tester.pumpAndSettle();

      expect(find.text('Backup jetzt erstellen'), findsOneWidget);
      expect(find.text('Backup erstellt ✓'), findsNothing);
    });

    testWidgets('Rendert MarkdownBody und filtert Notizen nach aktiver Sprache (de)', (
      WidgetTester tester,
    ) async {
      LocaleSettings.setLocale(AppLocale.de);

      final multiLangUpdate = UpdateInfo(
        version: '2.0.0',
        title: 'Feature Update',
        releaseNotes: '''
# PokéVault Release Notes

## 🇬🇧 English
* English feature 1
* English feature 2

## 🇩🇪 Deutsch
* Deutsches Feature 1
* Deutsches Feature 2
''',
        downloadUrl: 'https://test.com/update.apk',
        extension: '.apk',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: UpdateDialog(updateInfo: multiLangUpdate)),
        ),
      );

      expect(find.byType(MarkdownBody), findsOneWidget);
      expect(find.textContaining('Deutsches Feature 1'), findsOneWidget);
      expect(find.textContaining('English feature 1'), findsNothing);
    });

    testWidgets('Rendert MarkdownBody und filtert Notizen nach aktiver Sprache (en)', (
      WidgetTester tester,
    ) async {
      LocaleSettings.setLocale(AppLocale.en);

      final multiLangUpdate = UpdateInfo(
        version: '2.0.0',
        title: 'Feature Update',
        releaseNotes: '''
# PokéVault Release Notes

## 🇬🇧 English
* English feature 1
* English feature 2

## 🇩🇪 Deutsch
* Deutsches Feature 1
* Deutsches Feature 2
''',
        downloadUrl: 'https://test.com/update.apk',
        extension: '.apk',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: UpdateDialog(updateInfo: multiLangUpdate)),
        ),
      );

      expect(find.byType(MarkdownBody), findsOneWidget);
      expect(find.textContaining('English feature 1'), findsOneWidget);
      expect(find.textContaining('Deutsches Feature 1'), findsNothing);
    });

    testWidgets('Behält Zeilenumbrüche in Release-Notes bei (softLineBreak)', (
      WidgetTester tester,
    ) async {
      final lineBreakUpdate = UpdateInfo(
        version: '1.4.0',
        title: 'V1.4.0',
        releaseNotes:
            'Added information for some gen1 and gen2 pokemon\n'
            'enhanced shiny breeding chain for gen2\n'
            'added native android and windows updater for app',
        downloadUrl: 'https://test.com/update.apk',
        extension: '.apk',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: UpdateDialog(updateInfo: lineBreakUpdate)),
        ),
      );

      final markdownFinder = find.byType(MarkdownBody);
      expect(markdownFinder, findsOneWidget);
      final markdownWidget = tester.widget<MarkdownBody>(markdownFinder);
      expect(markdownWidget.softLineBreak, isTrue);

      // Verify that newlines are preserved in the rendered text
      expect(
        find.textContaining(
          'Added information for some gen1 and gen2 pokemon\n'
          'enhanced shiny breeding chain for gen2\n'
          'added native android and windows updater for app',
        ),
        findsOneWidget,
      );

      // Make sure it is NOT collapsed to a single line without newlines
      expect(
        find.textContaining(
          'Added information for some gen1 and gen2 pokemon enhanced shiny breeding chain',
        ),
        findsNothing,
      );
    });

    testWidgets('Behält Zeilenumbrüche auch bei CRLF (\\r\\n) bei', (
      WidgetTester tester,
    ) async {
      final crlfUpdate = UpdateInfo(
        version: '1.4.0',
        title: 'V1.4.0',
        releaseNotes:
            "First line\r\n"
            "Second line\r\n"
            "Third line",
        downloadUrl: 'https://test.com/update.apk',
        extension: '.apk',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: UpdateDialog(updateInfo: crlfUpdate)),
        ),
      );

      expect(
        find.textContaining('First line\nSecond line\nThird line'),
        findsOneWidget,
      );
    });

    testWidgets('Rendert leere Release-Notes ohne Fehler', (
      WidgetTester tester,
    ) async {
      final emptyUpdate = UpdateInfo(
        version: '1.4.0',
        title: 'V1.4.0',
        releaseNotes: '',
        downloadUrl: 'https://test.com/update.apk',
        extension: '.apk',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: UpdateDialog(updateInfo: emptyUpdate)),
        ),
      );

      expect(find.byType(MarkdownBody), findsOneWidget);
    });

    testWidgets('Rendert Markdown-Listen mit softLineBreak korrekt', (
      WidgetTester tester,
    ) async {
      final listUpdate = UpdateInfo(
        version: '1.4.0',
        title: 'V1.4.0',
        releaseNotes:
            "- Erstes Feature\n"
            "- Zweites Feature\n"
            "- Drittes Feature",
        downloadUrl: 'https://test.com/update.apk',
        extension: '.apk',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: UpdateDialog(updateInfo: listUpdate)),
        ),
      );

      expect(find.textContaining('Erstes Feature'), findsOneWidget);
      expect(find.textContaining('Zweites Feature'), findsOneWidget);
      expect(find.textContaining('Drittes Feature'), findsOneWidget);
    });
  });
}
