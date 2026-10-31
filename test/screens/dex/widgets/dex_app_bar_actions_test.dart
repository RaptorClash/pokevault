import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/i18n/strings.g.dart';
import 'package:pokevault/screens/dex/widgets/dex_app_bar_actions.dart';

void main() {
  setUpAll(() {
    LocaleSettings.setLocale(AppLocale.de);
  });

  Widget buildTestWidget({
    bool isEditMode = false,
    int selectedCount = 0,
    bool isBoxView = false,
    VoidCallback? onDeleteSelected,
    VoidCallback? onAddPokemon,
    VoidCallback? onSaveEditMode,
    VoidCallback? onToggleEditMode,
    VoidCallback? onOpenStats,
    VoidCallback? onToggleView,
    VoidCallback? onOpenSortSettings,
    VoidCallback? onOpenIgnoredList,
    VoidCallback? onOpenBoxSettings,
    VoidCallback? onDeleteDex,
    double screenWidth = 800,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: Size(screenWidth, 600)),
        child: Scaffold(
          appBar: AppBar(
            actions: [
              DexAppBarActions(
                isEditMode: isEditMode,
                selectedCount: selectedCount,
                isBoxView: isBoxView,
                onDeleteSelected: onDeleteSelected ?? () {},
                onAddPokemon: onAddPokemon ?? () {},
                onSaveEditMode: onSaveEditMode ?? () {},
                onToggleEditMode: onToggleEditMode ?? () {},
                onOpenStats: onOpenStats ?? () {},
                onToggleView: onToggleView ?? () {},
                onOpenSortSettings: onOpenSortSettings ?? () {},
                onOpenIgnoredList: onOpenIgnoredList ?? () {},
                onOpenBoxSettings: onOpenBoxSettings ?? () {},
                onDeleteDex: onDeleteDex ?? () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  group('DexAppBarActions TDD Tests', () {
    testWidgets('Renders normal mode actions and dispatches clicks', (tester) async {
      bool statsClicked = false;
      bool viewToggled = false;
      bool editToggled = false;

      await tester.pumpWidget(buildTestWidget(
        isEditMode: false,
        isBoxView: false,
        onOpenStats: () => statsClicked = true,
        onToggleView: () => viewToggled = true,
        onToggleEditMode: () => editToggled = true,
      ));

      expect(find.byIcon(Icons.bar_chart), findsOneWidget);
      expect(find.byIcon(Icons.checklist), findsOneWidget);
      expect(find.byType(PopupMenuButton<String>), findsOneWidget);

      await tester.tap(find.byIcon(Icons.bar_chart));
      expect(statsClicked, isTrue);

      await tester.tap(find.byIcon(Icons.checklist));
      expect(editToggled, isTrue);

      // Open popup menu to find toggle view item
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.grid_view), findsOneWidget);
      await tester.tap(find.byIcon(Icons.grid_view));
      await tester.pumpAndSettle();
      expect(viewToggled, isTrue);
    });

    testWidgets('Renders edit mode actions and dispatches clicks', (tester) async {
      bool deleteClicked = false;
      bool addClicked = false;
      bool saveClicked = false;

      await tester.pumpWidget(buildTestWidget(
        isEditMode: true,
        selectedCount: 3,
        onDeleteSelected: () => deleteClicked = true,
        onAddPokemon: () => addClicked = true,
        onSaveEditMode: () => saveClicked = true,
      ));

      expect(find.byIcon(Icons.delete), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete));
      expect(deleteClicked, isTrue);

      await tester.tap(find.byIcon(Icons.add));
      expect(addClicked, isTrue);

      await tester.tap(find.byIcon(Icons.check));
      expect(saveClicked, isTrue);
    });

    testWidgets('Does not show delete icon in edit mode when selectedCount is 0', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        isEditMode: true,
        selectedCount: 0,
      ));

      expect(find.byIcon(Icons.delete), findsNothing);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('Adversarial Viewport: Renders on 320px narrow screen without overflow', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        isEditMode: false,
        screenWidth: 320,
      ));

      expect(tester.takeException(), isNull);
    });
  });
}
