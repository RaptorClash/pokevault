import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/screens/home/widgets/home_dialogs.dart';
import 'package:pokevault/screens/home/edit_dex_dialog.dart';
import 'package:pokevault/l10n/app_translations.dart';
import '../../e2e/helpers/e2e_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDexProvider mockDexProvider;

  setUp(() {
    Translator.currentLanguage = 'de';
    mockDexProvider = MockDexProvider();
  });

  group('HomeDialogs Tests', () {
    testWidgets('showCreateFolderDialog creates folder on OK with text', (
      WidgetTester tester,
    ) async {
      when(() => mockDexProvider.createFolder(any(), any())).thenReturn(null);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => HomeDialogs.showCreateFolderDialog(
                  context,
                  mockDexProvider,
                  'root',
                ),
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Neuer Ordner'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Mein Ordner');
      await tester.pumpAndSettle();

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      verify(() => mockDexProvider.createFolder('Mein Ordner', 'root')).called(1);
    });

    testWidgets('showRenameFolderDialog renames folder on OK', (
      WidgetTester tester,
    ) async {
      when(() => mockDexProvider.renameFolder(any(), any())).thenReturn(null);
      final folder = DexFolder(id: 'folder_123', title: 'Alter Name');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => HomeDialogs.showRenameFolderDialog(
                  context,
                  mockDexProvider,
                  folder,
                ),
                child: const Text('Rename'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      expect(find.text('Ordner umbenennen'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Neuer Name');
      await tester.pumpAndSettle();

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      verify(() => mockDexProvider.renameFolder('folder_123', 'Neuer Name')).called(1);
    });

    testWidgets('confirmDeleteFolder calls non-recursive deleteFolder when unchecked', (
      WidgetTester tester,
    ) async {
      when(() => mockDexProvider.deleteFolder(any(), any())).thenAnswer((_) async {});
      final folder = DexFolder(id: 'folder_123', title: 'Ordner');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => HomeDialogs.confirmDeleteFolder(
                  context,
                  mockDexProvider,
                  folder,
                ),
                child: const Text('Delete'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Inhalt rekursiv löschen'), findsOneWidget);

      await tester.tap(find.text(Translator.get('delete')));
      await tester.pumpAndSettle();

      verify(() => mockDexProvider.deleteFolder('folder_123', false)).called(1);
    });

    testWidgets('confirmDeleteFolder calls recursive delete when checkbox is checked', (
      WidgetTester tester,
    ) async {
      when(() => mockDexProvider.structure).thenReturn({'root': [], 'folder_123': []});
      when(() => mockDexProvider.deleteFolder(any(), any())).thenAnswer((_) async {});
      final folder = DexFolder(id: 'folder_123', title: 'Ordner');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => HomeDialogs.confirmDeleteFolder(
                  context,
                  mockDexProvider,
                  folder,
                ),
                child: const Text('Delete'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Check recursive delete checkbox
      await tester.tap(find.text('Inhalt rekursiv löschen'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(Translator.get('delete')));
      await tester.pumpAndSettle();

      verify(() => mockDexProvider.deleteFolder('folder_123', true)).called(1);
    });

    testWidgets('confirmDeleteDex calls deleteDex on provider', (
      WidgetTester tester,
    ) async {
      when(() => mockDexProvider.deleteDex(any())).thenReturn(null);
      final dex = createTestUserDex(id: 'dex_del_1', title: 'Lösch Dex');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => HomeDialogs.confirmDeleteDex(
                  context,
                  mockDexProvider,
                  dex,
                ),
                child: const Text('Delete Dex'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Delete Dex'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(Translator.get('delete')));
      await tester.pumpAndSettle();

      verify(() => mockDexProvider.deleteDex('dex_del_1')).called(1);
    });
  });

  group('EditDexDialog Tests', () {
    testWidgets('Renders EditDexDialog and calls updateDex on save', (
      WidgetTester tester,
    ) async {
      when(() => mockDexProvider.updateDex(
            any(),
            any(),
            any(),
            any(),
            any(),
            any(),
            any(),
            any(),
          )).thenReturn(null);

      final dex = createTestUserDex(
        id: 'dex_edit_1',
        title: 'Mein Kanto Dex',
        region: 'kanto',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditDexDialog(provider: mockDexProvider, dex: dex),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(Translator.get('edit')), findsOneWidget);
      expect(find.text('Mein Kanto Dex'), findsOneWidget);

      // Change title
      final titleField = find.byType(TextField);
      await tester.enterText(titleField, 'Neuer Titel');
      await tester.pumpAndSettle();

      // Tap save
      final saveBtn = find.text(Translator.get('save'));
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      verify(() => mockDexProvider.updateDex(
            'dex_edit_1',
            'Neuer Titel',
            any(),
            any(),
            any(),
            any(),
            any(),
            any(),
          )).called(1);
    });
  });
}
