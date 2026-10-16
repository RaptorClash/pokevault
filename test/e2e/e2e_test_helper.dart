import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/dex_view_models.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/providers/settings_provider.dart';
import 'package:pokevault/providers/tutorial_provider.dart';
import 'package:pokevault/l10n/app_translations.dart';

class MockDexProvider extends Mock implements DexProvider {}
class MockSettingsProvider extends Mock implements SettingsProvider {}
class MockTutorialProvider extends Mock implements TutorialProvider {}

/// Helper to determine if a [ColorFilter] is a grayscale matrix filter.
/// In Pokevault, grayscale is applied via ColorFilter.matrix with luminance coefficients (0.2126, 0.7152, 0.0722).
bool isGrayscaleFilter(ColorFilter? filter) {
  if (filter == null) return false;
  final str = filter.toString();
  return str.contains('matrix') || str.contains('0.2126');
}

/// Checks whether a widget subtree (or the entire tree) contains any grayscale matrix ColorFiltered.
bool hasGrayscaleFilter(WidgetTester tester, [Finder? parentFinder]) {
  final finder = parentFinder != null
      ? find.descendant(of: parentFinder, matching: find.byType(ColorFiltered))
      : find.byType(ColorFiltered);
  final filteredWidgets = tester.widgetList<ColorFiltered>(finder);
  for (var cf in filteredWidgets) {
    if (isGrayscaleFilter(cf.colorFilter)) {
      return true;
    }
  }
  return false;
}

/// Finds the card InkWell containing the CachedNetworkImage with the given imageUrl.
Finder findCardForImageUrl(String imageUrl) {
  return find.ancestor(
    of: find.byWidgetPredicate((w) => w is CachedNetworkImage && w.imageUrl == imageUrl),
    matching: find.byType(InkWell),
  );
}

/// Helper to create a dummy Pokemon for testing.
Pokemon createTestPokemon({
  int id = 1,
  String nameDe = 'Bisasam',
  String nameEn = 'Bulbasaur',
  List<String> types = const ['grass', 'poison'],
}) {
  return Pokemon(
    id: id,
    nameDe: nameDe,
    nameEn: nameEn,
    hasGenderDifferences: false,
    genderRate: 1,
    captureRate: 45,
    evolutionChainId: 1,
    eggGroups: ['monster'],
    weight: 6.9,
    speed: 45,
    forms: [
      PokemonForm(
        name: 'normal',
        formType: 'normal',
        minGen: 1,
        imageId: id,
        types: types,
        exclusiveRegions: [],
      )
    ],
  );
}

/// Helper to create a DexDisplayEntry.
DexDisplayEntry createTestEntry({
  required Pokemon pokemon,
  required String uniqueId,
  String displaySuffix = '',
  String imageUrl = 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/1.png',
}) {
  return DexDisplayEntry(
    pokemon: pokemon,
    uniqueId: uniqueId,
    displaySuffix: displaySuffix,
    imageUrl: imageUrl,
  );
}

/// Helper to create BoxData.
BoxData createTestBoxData({
  required String title,
  required List<DexDisplayEntry> entries,
  int crossAxisCount = 5,
  String regionKey = 'custom',
}) {
  return BoxData(title, regionKey, entries, crossAxisCount);
}

/// Helper to create a CustomBoxState with custom parameters.
CustomBoxState createTestCustomBox({
  required String title,
  required List<String> pokemonIds,
  int columns = 5,
  int rows = 6,
  bool autoFlow = false,
  bool autoShift = true,
  bool strictLimits = true,
  bool patternAutoCreate = true,
  bool autoDeleteEmpty = true,
}) {
  final box = CustomBoxState(
    title: title,
    pokemonIds: List<String>.from(pokemonIds),
    columns: columns,
    rows: rows,
    autoFlow: autoFlow,
  );
  // Dynamically set extended properties if supported by the model
  try {
    (box as dynamic).autoShift = autoShift;
    (box as dynamic).strictLimits = strictLimits;
    (box as dynamic).patternAutoCreate = patternAutoCreate;
    (box as dynamic).autoDeleteEmpty = autoDeleteEmpty;
  } catch (_) {}
  return box;
}

/// Helper to create a UserDex.
UserDex createTestUserDex({
  String id = 'test_dex_1',
  String title = 'Test Dex',
  String region = 'kanto',
  List<CustomBoxState> customBoxes = const [],
  List<String> caughtIds = const [],
  List<String> shinyIds = const [],
  List<String> alphaIds = const [],
  List<String> ignoredIds = const [],
  String viewMode = 'box',
}) {
  return UserDex(
    id: id,
    title: title,
    region: region,
    includeGenders: false,
    includeRegional: false,
    includeMega: false,
    includeGMax: false,
    includeOther: false,
    isShinyDex: false,
    viewMode: viewMode,
    customBoxes: List<CustomBoxState>.from(customBoxes),
    caughtIds: List<String>.from(caughtIds),
    shinyIds: List<String>.from(shinyIds),
    alphaIds: List<String>.from(alphaIds),
    ignoredIds: List<String>.from(ignoredIds),
  );
}

/// Wraps a widget with the required MaterialApp and Provider tree for widget testing.
Widget wrapWithApp({
  required Widget child,
  MockDexProvider? mockDexProvider,
  MockSettingsProvider? mockSettingsProvider,
  MockTutorialProvider? mockTutorialProvider,
  String language = 'en',
}) {
  SharedPreferences.setMockInitialValues({});
  Translator.currentLanguage = language;

  final dexProvider = mockDexProvider ?? MockDexProvider();
  final settingsProvider = mockSettingsProvider ?? MockSettingsProvider();
  final tutorialProvider = mockTutorialProvider ?? MockTutorialProvider();

  when(() => settingsProvider.currentLanguage).thenReturn(language);
  when(() => tutorialProvider.hasSeenFeature(any())).thenReturn(true);

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<DexProvider>.value(value: dexProvider),
      ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
      ChangeNotifierProvider<TutorialProvider>.value(value: tutorialProvider),
    ],
    child: MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}
