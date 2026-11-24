import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pokevault/i18n/strings.g.dart';
import 'package:pokevault/widgets/dialogs/release_notes_markdown.dart';

void main() {
  group('ReleaseNotesMarkdown Tests', () {
    testWidgets('Renders filtered Markdown in light and dark themes without errors', (
      WidgetTester tester,
    ) async {
      LocaleSettings.setLocaleSync(AppLocale.de);

      const notes = '''
# Title
## 🇬🇧 English
- English item

## 🇩🇪 Deutsch
- **Deutsches Feature** mit `code`
> Zitat
''';

      for (final brightness in [Brightness.light, Brightness.dark]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: const Scaffold(
              body: ReleaseNotesMarkdown(releaseNotes: notes),
            ),
          ),
        );

        expect(find.byType(MarkdownBody), findsOneWidget);
        expect(find.textContaining('Deutsches Feature'), findsOneWidget);
        expect(find.textContaining('English item'), findsNothing);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('Handles empty release notes gracefully', (
      WidgetTester tester,
    ) async {
      LocaleSettings.setLocaleSync(AppLocale.en);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReleaseNotesMarkdown(releaseNotes: ''),
          ),
        ),
      );

      expect(find.byType(MarkdownBody), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
