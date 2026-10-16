import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/widgets/dialogs/update_dialog.dart';
import 'package:pokevault/utils/update_helper.dart';
import 'package:pokevault/l10n/app_translations.dart';

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
      Translator.currentLanguage = 'de';
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
  });
}
