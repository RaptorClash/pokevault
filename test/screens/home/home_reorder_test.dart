import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokevault/screens/home/home_screen.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/providers/tutorial_provider.dart';
import 'package:pokevault/providers/settings_provider.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/l10n/app_translations.dart';
import 'package:pokevault/widgets/tutorial/tutorial_overlay.dart';

class FakeDexProvider extends ChangeNotifier implements DexProvider {
  @override
  bool get isInitialized => true;
  @override
  bool get isMigrating => false;
  @override
  List<UserDex> userDexes = [];
  @override
  List<DexFolder> folders = [];
  @override
  Map<String, List<String>> structure = {};
  @override
  Map<String, List<int>> allAvailableDexes = {};
  @override
  List<Pokemon> allPokemon = [];

  int reorderCallCount = 0;
  String? lastFolderId;
  int? lastOldIndex;
  int? lastNewIndex;

  @override
  void reorderItem(String folderId, int oldIndex, int newIndex) {
    reorderCallCount++;
    lastFolderId = folderId;
    lastOldIndex = oldIndex;
    lastNewIndex = newIndex;
    final list = structure[folderId]!;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockTutorialProvider extends Mock implements TutorialProvider {}
class MockSettingsProvider extends Mock implements SettingsProvider {}

void main() {
  group('HomeScreen Reorder Tests', () {
    late FakeDexProvider fakeDexProvider;
    late MockTutorialProvider mockTutorialProvider;
    late MockSettingsProvider mockSettingsProvider;

    final kantoDex = UserDex(
      id: 'dex_kanto',
      title: 'Kanto Dex',
      region: 'kanto',
      includeGenders: false,
      includeRegional: false,
      includeMega: false,
      includeGMax: false,
      includeOther: false,
      isShinyDex: false,
      caughtIds: ['1'],
    );

    final johtoDex = UserDex(
      id: 'dex_johto',
      title: 'Johto Living Dex',
      region: 'johto',
      includeGenders: false,
      includeRegional: false,
      includeMega: false,
      includeGMax: false,
      includeOther: false,
      isShinyDex: false,
      caughtIds: ['152'],
    );

    final folder1 = DexFolder(id: 'folder_1', title: 'Mein Ordner');

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      Translator.currentLanguage = 'de';

      fakeDexProvider = FakeDexProvider();
      fakeDexProvider.userDexes = [kantoDex, johtoDex];
      fakeDexProvider.folders = [folder1];
      fakeDexProvider.structure = {
        'root': ['folder_1', 'dex_kanto', 'dex_johto'],
      };

      mockTutorialProvider = MockTutorialProvider();
      mockSettingsProvider = MockSettingsProvider();
      TutorialOverlay.resetShowing();

      when(() => mockTutorialProvider.hasSeenFeature(any())).thenReturn(true);
      when(() => mockTutorialProvider.getFeatureStep(any())).thenReturn(0);
      when(() => mockTutorialProvider.shouldShowV16UpdatePrompt).thenReturn(false);
      when(() => mockTutorialProvider.isDeltaTourActive).thenReturn(false);

      when(() => mockSettingsProvider.autoSyncEnabled).thenReturn(false);
      when(() => mockSettingsProvider.googleClientId).thenReturn('');
      when(() => mockSettingsProvider.googleClientSecret).thenReturn('');
    });

    Widget buildHomeScreen() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<DexProvider>.value(value: fakeDexProvider),
          ChangeNotifierProvider<TutorialProvider>.value(value: mockTutorialProvider),
          ChangeNotifierProvider<SettingsProvider>.value(value: mockSettingsProvider),
        ],
        child: const MaterialApp(
          home: HomeScreen(currentFolderId: 'root'),
        ),
      );
    }

    testWidgets('Drag and drop folder moves folder down past dexes', (WidgetTester tester) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      expect(find.byType(ReorderableListView), findsOneWidget);
      expect(find.byIcon(Icons.drag_indicator), findsNWidgets(3));

      // Drag folder_1 (index 0) down below dex_johto (index 2)
      final firstHandle = find.byIcon(Icons.drag_indicator).first;
      
      // Simulate drag
      await tester.drag(firstHandle, const Offset(0, 300));
      await tester.pumpAndSettle();

      expect(fakeDexProvider.reorderCallCount, 1);
      expect(fakeDexProvider.lastFolderId, 'root');
      expect(fakeDexProvider.lastOldIndex, 0);
      expect(fakeDexProvider.lastNewIndex, 2);
      expect(fakeDexProvider.structure['root'], ['dex_kanto', 'dex_johto', 'folder_1']);
    });

    testWidgets('Drag and drop dex moves dex up past folder', (WidgetTester tester) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      // Drag dex_johto (index 2) up above folder_1 (index 0)
      final lastHandle = find.byIcon(Icons.drag_indicator).last;

      await tester.drag(lastHandle, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(fakeDexProvider.reorderCallCount, 1);
      expect(fakeDexProvider.lastFolderId, 'root');
      expect(fakeDexProvider.lastOldIndex, 2);
      expect(fakeDexProvider.lastNewIndex, 0);
      expect(fakeDexProvider.structure['root'], ['dex_johto', 'folder_1', 'dex_kanto']);
    });

    testWidgets('Holding drag handle does not trigger selection mode or expansion', (WidgetTester tester) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      final firstHandle = find.byIcon(Icons.drag_indicator).first;
      // Long press on folder drag handle
      await tester.longPress(firstHandle);
      await tester.pumpAndSettle();

      // Selection mode should NOT be active!
      expect(find.text('1 ausgewählt'), findsNothing);
      expect(find.byType(ReorderableListView), findsOneWidget);
    });

    testWidgets('Holding drag handle on DexCard does not trigger selection mode or open dex', (WidgetTester tester) async {
      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      // Index 1 is Kanto Dex
      final dexHandle = find.byIcon(Icons.drag_indicator).at(1);
      await tester.longPress(dexHandle);
      await tester.pumpAndSettle();

      // Selection mode should NOT be active
      expect(find.text('1 ausgewählt'), findsNothing);
      expect(find.byType(ReorderableListView), findsOneWidget);
    });

    testWidgets('Dragging folder past another folder works in both directions', (WidgetTester tester) async {
      final folder2 = DexFolder(id: 'folder_2', title: 'Zweiter Ordner');
      fakeDexProvider.folders = [folder1, folder2];
      fakeDexProvider.structure = {
        'root': ['folder_1', 'folder_2', 'dex_kanto'],
      };

      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      // Drag folder_1 (index 0) down past folder_2 (index 1)
      final firstHandle = find.byIcon(Icons.drag_indicator).first;
      await tester.drag(firstHandle, const Offset(0, 60));
      await tester.pumpAndSettle();

      expect(fakeDexProvider.reorderCallCount, 1);
      expect(fakeDexProvider.lastOldIndex, 0);
      expect(fakeDexProvider.lastNewIndex, 1);
      expect(fakeDexProvider.structure['root'], ['folder_2', 'folder_1', 'dex_kanto']);

      // Now drag folder_1 (now index 1) up past folder_2 (index 0)
      final secondHandle = find.byIcon(Icons.drag_indicator).at(1);
      await tester.drag(secondHandle, const Offset(0, -60));
      await tester.pumpAndSettle();

      expect(fakeDexProvider.reorderCallCount, 2);
      expect(fakeDexProvider.lastOldIndex, 1);
      expect(fakeDexProvider.lastNewIndex, 0);
      expect(fakeDexProvider.structure['root'], ['folder_1', 'folder_2', 'dex_kanto']);
    });

    testWidgets('Dragging dex down past another dex works', (WidgetTester tester) async {
      fakeDexProvider.structure = {
        'root': ['dex_kanto', 'dex_johto'],
      };

      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      final firstHandle = find.byIcon(Icons.drag_indicator).first;
      await tester.drag(firstHandle, const Offset(0, 60));
      await tester.pumpAndSettle();

      expect(fakeDexProvider.reorderCallCount, 1);
      expect(fakeDexProvider.lastOldIndex, 0);
      expect(fakeDexProvider.lastNewIndex, 1);
      expect(fakeDexProvider.structure['root'], ['dex_johto', 'dex_kanto']);
    });

    testWidgets('Dragging dex down past folder works', (WidgetTester tester) async {
      fakeDexProvider.structure = {
        'root': ['dex_kanto', 'folder_1', 'dex_johto'],
      };

      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      // Drag dex_kanto (index 0) down past folder_1 (index 1)
      final firstHandle = find.byIcon(Icons.drag_indicator).first;
      await tester.drag(firstHandle, const Offset(0, 60));
      await tester.pumpAndSettle();

      expect(fakeDexProvider.reorderCallCount, 1);
      expect(fakeDexProvider.lastOldIndex, 0);
      expect(fakeDexProvider.lastNewIndex, 1);
      expect(fakeDexProvider.structure['root'], ['folder_1', 'dex_kanto', 'dex_johto']);
    });

    testWidgets('Reordering works inside a subfolder', (WidgetTester tester) async {
      final subDex1 = UserDex(id: 'dex_sub1', title: 'Sub Dex 1', region: 'kanto', includeGenders: false, includeRegional: false, includeMega: false, includeGMax: false, includeOther: false, isShinyDex: false, caughtIds: []);
      final subDex2 = UserDex(id: 'dex_sub2', title: 'Sub Dex 2', region: 'kanto', includeGenders: false, includeRegional: false, includeMega: false, includeGMax: false, includeOther: false, isShinyDex: false, caughtIds: []);
      fakeDexProvider.userDexes = [kantoDex, johtoDex, subDex1, subDex2];
      fakeDexProvider.structure = {
        'root': ['folder_1'],
        'folder_1': ['dex_sub1', 'dex_sub2'],
      };

      Widget buildSubFolderHomeScreen() {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider<DexProvider>.value(value: fakeDexProvider),
            ChangeNotifierProvider<TutorialProvider>.value(value: mockTutorialProvider),
            ChangeNotifierProvider<SettingsProvider>.value(value: mockSettingsProvider),
          ],
          child: const MaterialApp(
            home: HomeScreen(currentFolderId: 'folder_1'),
          ),
        );
      }

      await tester.pumpWidget(buildSubFolderHomeScreen());
      await tester.pumpAndSettle();

      expect(find.byType(ReorderableListView), findsOneWidget);
      expect(find.byIcon(Icons.drag_indicator), findsNWidgets(2));

      // Drag subDex1 down past subDex2 inside folder_1
      final firstHandle = find.byIcon(Icons.drag_indicator).first;
      await tester.drag(firstHandle, const Offset(0, 60));
      await tester.pumpAndSettle();

      expect(fakeDexProvider.reorderCallCount, 1);
      expect(fakeDexProvider.lastFolderId, 'folder_1');
      expect(fakeDexProvider.lastOldIndex, 0);
      expect(fakeDexProvider.lastNewIndex, 1);
      expect(fakeDexProvider.structure['folder_1'], ['dex_sub2', 'dex_sub1']);
    });

    testWidgets('Reordering works even if structure contains orphaned IDs', (WidgetTester tester) async {
      fakeDexProvider.structure = {
        'root': ['orphaned_id', 'folder_1', 'dex_kanto'],
      };

      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      expect(find.byType(ReorderableListView), findsOneWidget);
      expect(find.byIcon(Icons.drag_indicator), findsNWidgets(2));

      // Drag folder_1 (visible index 0) down past dex_kanto (visible index 1)
      final firstHandle = find.byIcon(Icons.drag_indicator).first;
      await tester.drag(firstHandle, const Offset(0, 250));
      await tester.pumpAndSettle();

      expect(fakeDexProvider.reorderCallCount, 1);
      expect(fakeDexProvider.structure['root'], containsAllInOrder(['dex_kanto', 'folder_1']));
    });

    testWidgets('Drag and drop expanded folder moves entire folder and its children down past dexes', (WidgetTester tester) async {
      final subDex1 = UserDex(id: 'dex_sub1', title: 'Sub Dex 1', region: 'kanto', includeGenders: false, includeRegional: false, includeMega: false, includeGMax: false, includeOther: false, isShinyDex: false, caughtIds: []);
      fakeDexProvider.userDexes = [kantoDex, johtoDex, subDex1];
      fakeDexProvider.folders = [folder1];
      fakeDexProvider.structure = {
        'root': ['folder_1', 'dex_kanto', 'dex_johto'],
        'folder_1': ['dex_sub1'],
      };

      await tester.pumpWidget(buildHomeScreen());
      await tester.pumpAndSettle();

      // Tap on folder title to expand it
      await tester.tap(find.text('Mein Ordner'));
      await tester.pumpAndSettle();

      // Verify subDex1 is visible inside the expanded folder
      expect(find.text('Sub Dex 1'), findsOneWidget);

      // Drag the expanded folder down past dex_johto
      final firstHandle = find.byIcon(Icons.drag_indicator).first;
      await tester.drag(firstHandle, const Offset(0, 500));
      await tester.pumpAndSettle();

      expect(fakeDexProvider.reorderCallCount, 1);
      expect(fakeDexProvider.lastOldIndex, 0);
      expect(fakeDexProvider.lastNewIndex, 2);
      expect(fakeDexProvider.structure['root'], ['dex_kanto', 'dex_johto', 'folder_1']);
    });
  });
}


