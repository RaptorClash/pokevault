import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pokevault/screens/pokemon_info/dialogs/ignore_pokemon_dialog.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/models/dex_view_models.dart';
import 'package:pokevault/models/pokemon.dart';

class FakeDexProvider extends ChangeNotifier implements DexProvider {
  bool ignorePokemonCalled = false;
  String? ignoredDexId;
  String? ignoredUniqueId;

  @override
  void ignorePokemon(String dexId, String uniqueId) {
    ignorePokemonCalled = true;
    ignoredDexId = dexId;
    ignoredUniqueId = uniqueId;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final dummyPokemon = Pokemon(
    id: 1,
    nameDe: 'Bisasam',
    nameEn: 'Bulbasaur',
    hasGenderDifferences: false,
    genderRate: -1,
    captureRate: 45,
    evolutionChainId: 1,
    eggGroups: [],
    weight: 6.9,
    speed: 45,
    forms: [],
  );

  final dummyEntry = DexDisplayEntry(
    pokemon: dummyPokemon,
    uniqueId: 'bulbasaur_normal',
    displaySuffix: '',
    imageUrl: 'assets/pokemon/1.png',
  );

  const testDexId = 'mein_test_dex';

  Widget createTestApp(FakeDexProvider provider) {
    return MultiProvider(
      providers: [ChangeNotifierProvider<DexProvider>.value(value: provider)],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                IgnorePokemonDialog.show(
                  context,
                  provider: provider,
                  entry: dummyEntry,
                  dexId: testDexId,
                  showTutorial: false,
                );
              },
              child: const Text('Dialog Öffnen'),
            ),
          ),
        ),
      ),
    );
  }

  group('IgnorePokemonDialog Tests', () {
    testWidgets(
      'Klick auf Abbrechen schließt den Dialog, ohne Methode aufzurufen',
      (WidgetTester tester) async {
        final fakeProvider = FakeDexProvider();

        await tester.pumpWidget(createTestApp(fakeProvider));

        await tester.tap(find.text('Dialog Öffnen'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);

        final cancelButton = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextButton),
        );
        await tester.tap(cancelButton);
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(fakeProvider.ignorePokemonCalled, isFalse);
      },
    );

    testWidgets(
      'Klick auf Entfernen ruft ignorePokemon auf und schließt Dialog',
      (WidgetTester tester) async {
        final fakeProvider = FakeDexProvider();

        await tester.pumpWidget(createTestApp(fakeProvider));

        await tester.tap(find.text('Dialog Öffnen'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);

        final confirmButton = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(ElevatedButton),
        );
        await tester.tap(confirmButton);
        await tester.pumpAndSettle();

        expect(fakeProvider.ignorePokemonCalled, isTrue);
        expect(fakeProvider.ignoredDexId, testDexId);
        expect(fakeProvider.ignoredUniqueId, dummyEntry.uniqueId);

        expect(find.byType(AlertDialog), findsNothing);
      },
    );
  });
}
