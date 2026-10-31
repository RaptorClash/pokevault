import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/i18n/strings.g.dart';
import 'package:pokevault/screens/dex/widgets/dex_filter_bar.dart';

void main() {
  setUpAll(() {
    LocaleSettings.setLocale(AppLocale.de);
  });

  Widget buildTestWidget({
    required TextEditingController controller,
    String searchQuery = '',
    String filter = 'all',
    ValueChanged<String>? onSearchChanged,
    VoidCallback? onClearSearch,
    VoidCallback? onSearchHelp,
    ValueChanged<String?>? onFilterChanged,
    double screenWidth = 400,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: Size(screenWidth, 600)),
        child: Scaffold(
          body: DexFilterBar(
            searchBarKey: const Key('_searchBarKey'),
            searchController: controller,
            searchQuery: searchQuery,
            filter: filter,
            onSearchChanged: onSearchChanged ?? (_) {},
            onClearSearch: onClearSearch ?? () {},
            onSearchHelp: onSearchHelp ?? () {},
            onFilterChanged: onFilterChanged ?? (_) {},
          ),
        ),
      ),
    );
  }

  group('DexFilterBar TDD Tests', () {
    testWidgets('Renders search field, clear button, help button, and filter dropdown', (tester) async {
      final controller = TextEditingController(text: 'Pikachu');
      bool cleared = false;
      bool helpOpened = false;

      await tester.pumpWidget(buildTestWidget(
        controller: controller,
        searchQuery: 'Pikachu',
        onClearSearch: () => cleared = true,
        onSearchHelp: () => helpOpened = true,
      ));

      expect(find.byKey(const Key('_searchBarKey')), findsOneWidget);
      expect(find.byIcon(Icons.clear), findsOneWidget);
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
      expect(find.byType(DropdownButton<String>), findsOneWidget);

      await tester.tap(find.byIcon(Icons.clear));
      expect(cleared, isTrue);

      await tester.tap(find.byIcon(Icons.help_outline));
      expect(helpOpened, isTrue);
    });

    testWidgets('Dispatches filter change callback', (tester) async {
      final controller = TextEditingController();
      String? selectedFilter;

      await tester.pumpWidget(buildTestWidget(
        controller: controller,
        filter: 'all',
        onFilterChanged: (val) => selectedFilter = val,
      ));

      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text(t.filter_caught).last);
      await tester.pumpAndSettle();

      expect(selectedFilter, 'caught');
    });

    testWidgets('Adversarial Viewport: Renders on 320px screen without overflow', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(buildTestWidget(
        controller: controller,
        screenWidth: 320,
      ));

      expect(tester.takeException(), isNull);
    });
  });
}
