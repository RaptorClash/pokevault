import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/screens/home/widgets/home_dex_tree_view.dart';

class MockDexProvider extends Mock implements DexProvider {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDexProvider mockDexProvider;

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
    caughtIds: ['1', '4'],
  );

  final folder1 = DexFolder(id: 'folder_1', title: 'Mein Ordner');

  setUp(() {
    mockDexProvider = MockDexProvider();

    when(() => mockDexProvider.isInitialized).thenReturn(true);
    when(() => mockDexProvider.isMigrating).thenReturn(false);
    when(() => mockDexProvider.userDexes).thenReturn([kantoDex]);
    when(() => mockDexProvider.folders).thenReturn([folder1]);
    when(() => mockDexProvider.structure).thenReturn({
      'root': ['dex_kanto', 'folder_1'],
    });
    when(() => mockDexProvider.allAvailableDexes).thenReturn({
      'kanto': [1, 4, 7],
    });
    when(() => mockDexProvider.allPokemon).thenReturn(<Pokemon>[]);
  });

  Widget buildTestWidget({
    String currentFolderId = 'root',
    String searchQuery = '',
    String currentSort = 'manual',
    Set<String> selectedItemIds = const {},
    ValueChanged<UserDex>? onOpenDex,
    ValueChanged<DexFolder>? onOpenFolder,
    ValueChanged<String>? onToggleSelect,
  }) {
    return ChangeNotifierProvider<DexProvider>.value(
      value: mockDexProvider,
      child: MaterialApp(
        home: Scaffold(
          body: HomeDexTreeView(
            currentFolderId: currentFolderId,
            searchQuery: searchQuery,
            currentSort: currentSort,
            selectedItemIds: selectedItemIds,
            onOpenDex: onOpenDex ?? (_) {},
            onOpenFolder: onOpenFolder ?? (_) {},
            onToggleSelect: onToggleSelect ?? (_) {},
            onCreateDexPressed: () {},
          ),
        ),
      ),
    );
  }

  group('HomeDexTreeView TDD Tests', () {
    testWidgets('Renders empty state when no dexes exist', (tester) async {
      when(() => mockDexProvider.userDexes).thenReturn([]);
      when(() => mockDexProvider.folders).thenReturn([]);
      when(() => mockDexProvider.structure).thenReturn({'root': []});

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('Noch kein Dex vorhanden'), findsOneWidget);
    });

    testWidgets('Renders DexCard and FolderCard items at root level', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Kanto Dex'), findsOneWidget);
      expect(find.text('Mein Ordner'), findsOneWidget);
    });

    testWidgets('Tapping DexCard calls onOpenDex callback', (tester) async {
      UserDex? openedDex;
      await tester.pumpWidget(buildTestWidget(
        onOpenDex: (dex) => openedDex = dex,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kanto Dex'));
      expect(openedDex, isNotNull);
      expect(openedDex!.title, equals('Kanto Dex'));
    });

    testWidgets('Long-pressing DexCard calls onToggleSelect callback', (tester) async {
      String? selectedId;
      await tester.pumpWidget(buildTestWidget(
        onToggleSelect: (id) => selectedId = id,
      ));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('Kanto Dex'));
      expect(selectedId, isNotNull);
    });

    testWidgets('Adversarial Viewport: Renders on 320px narrow screen without overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
