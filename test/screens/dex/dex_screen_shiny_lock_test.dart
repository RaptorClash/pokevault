import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokevault/models/dex_view_models.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/providers/settings_provider.dart';
import 'package:pokevault/screens/dex/dex_list_view.dart';
import 'package:pokevault/screens/dex/dex_box_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pokevault/i18n/strings.g.dart';

class MockDexProvider extends Mock implements DexProvider {}
class MockSettingsProvider extends Mock implements SettingsProvider {}

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

class _MockHttpClient extends Fake implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _MockHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  static const List<int> _kTransparentImage = <int>[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
    0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
    0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
    0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
    0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
    0x60, 0x82,
  ];

  @override
  int get statusCode => HttpStatus.ok;

  @override
  int get contentLength => _kTransparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_kTransparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDexProvider mockDexProvider;
  late MockSettingsProvider mockSettingsProvider;

  late Pokemon victini;
  late Pokemon pikachu;
  late Pokemon purrloin;
  late Pokemon unown;
  late DexDisplayEntry victiniEntry;
  late DexDisplayEntry pikachuEntry;
  late DexDisplayEntry nPurrloinEntry;
  late DexDisplayEntry unownNEntry;

  setUpAll(() {
    HttpOverrides.global = _MockHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LocaleSettings.setLocale(AppLocale.de);
    mockDexProvider = MockDexProvider();
    mockSettingsProvider = MockSettingsProvider();
    when(() => mockSettingsProvider.currentLanguage).thenReturn('de');

    victini = Pokemon(
      id: 494,
      nameDe: 'Victini',
      nameEn: 'Victini',
      hasGenderDifferences: false,
      genderRate: -1,
      captureRate: 3,
      evolutionChainId: 253,
      eggGroups: ['no-eggs'],
      weight: 4.0,
      speed: 100,
      forms: [
        PokemonForm(
          name: 'normal',
          formType: 'normal',
          minGen: 5,
          imageId: 494,
          types: ['psychic', 'fire'],
          exclusiveRegions: [],
        ),
      ],
    );

    pikachu = Pokemon(
      id: 25,
      nameDe: 'Pikachu',
      nameEn: 'Pikachu',
      hasGenderDifferences: true,
      genderRate: 4,
      captureRate: 190,
      evolutionChainId: 10,
      eggGroups: ['field', 'fairy'],
      weight: 6.0,
      speed: 90,
      forms: [
        PokemonForm(
          name: 'normal',
          formType: 'normal',
          minGen: 1,
          imageId: 25,
          types: ['electric'],
          exclusiveRegions: [],
        ),
      ],
    );

    victiniEntry = DexDisplayEntry(
      pokemon: victini,
      uniqueId: '494_normal',
      displaySuffix: '',
      imageUrl: 'https://example.com/494.png',
      form: victini.forms.first,
    );

    pikachuEntry = DexDisplayEntry(
      pokemon: pikachu,
      uniqueId: '25_normal',
      displaySuffix: '',
      imageUrl: 'https://example.com/25.png',
      form: pikachu.forms.first,
    );

    purrloin = Pokemon(
      id: 509,
      nameDe: 'Felilou',
      nameEn: 'Purrloin',
      hasGenderDifferences: false,
      genderRate: 4,
      captureRate: 255,
      evolutionChainId: 260,
      eggGroups: ['field'],
      weight: 10.1,
      speed: 66,
      forms: [
        PokemonForm(
          name: 'normal',
          formType: 'normal',
          minGen: 5,
          imageId: 509,
          types: ['dark'],
          exclusiveRegions: [],
        ),
      ],
    );

    nPurrloinEntry = DexDisplayEntry(
      pokemon: purrloin,
      uniqueId: '509_special_325_n_unova_normal',
      displaySuffix: " (N's Pokémon)",
      imageUrl: 'https://example.com/509.png',
      form: purrloin.forms.first,
    );

    unown = Pokemon(
      id: 201,
      nameDe: 'Icognito',
      nameEn: 'Unown',
      hasGenderDifferences: false,
      genderRate: -1,
      captureRate: 225,
      evolutionChainId: 99,
      eggGroups: ['no-eggs'],
      weight: 5.0,
      speed: 48,
      forms: [
        PokemonForm(
          name: 'n',
          formType: 'unown',
          minGen: 2,
          imageId: 201,
          types: ['psychic'],
          exclusiveRegions: [],
        ),
      ],
    );

    unownNEntry = DexDisplayEntry(
      pokemon: unown,
      uniqueId: '201_n',
      displaySuffix: ' (N)',
      imageUrl: 'https://example.com/201.png',
      form: unown.forms.first,
    );
  });

  Widget buildTestApp(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DexProvider>.value(value: mockDexProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: mockSettingsProvider),
      ],
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('Dex Screens Shiny Lock Badges & Interactions (TDD)', () {
    testWidgets('DexListView renders shiny lock badge for shiny locked entry', (tester) async {
      final dex = UserDex(
        id: 'test_dex_normal',
        title: 'National Dex',
        region: 'national_overall',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
      );

      await tester.pumpWidget(
        buildTestApp(
          DexListView(
            displayList: [victiniEntry, pikachuEntry],
            liveDex: dex,
            provider: mockDexProvider,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Victini is shiny locked -> lock badge rendered
      expect(find.byKey(const Key('shiny_lock_badge_494_normal')), findsOneWidget);

      // Pikachu is not shiny locked -> no badge
      expect(find.byKey(const Key('shiny_lock_badge_25_normal')), findsNothing);
    });

    testWidgets('DexListView in Shiny Dex prevents tapping shiny locked Pokemon', (tester) async {
      final shinyDex = UserDex(
        id: 'test_dex_shiny',
        title: 'Shiny National Dex',
        region: 'national_overall',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: true,
      );

      await tester.pumpWidget(
        buildTestApp(
          DexListView(
            displayList: [victiniEntry, pikachuEntry],
            liveDex: shinyDex,
            provider: mockDexProvider,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Victini in Shiny Dex -> provider.togglePokemon should NOT be called
      await tester.tap(find.text('Victini'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verifyNever(() => mockDexProvider.togglePokemon(any(), any(), targetState: any(named: 'targetState')));

      // Tap Pikachu in Shiny Dex -> provider.togglePokemon SHOULD be called
      when(() => mockDexProvider.togglePokemon(any(), any(), targetState: any(named: 'targetState')))
          .thenReturn(null);

      await tester.tap(find.text('Pikachu'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockDexProvider.togglePokemon('test_dex_shiny', '25_normal')).called(1);
    });

    testWidgets('DexBoxView renders lock badge on shiny locked cards', (tester) async {
      final dex = UserDex(
        id: 'box_dex_1',
        title: 'Box Dex',
        region: 'national_overall',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        isShinyDex: false,
        customBoxes: [
          CustomBoxState(
            title: 'Box 1',
            pokemonIds: ['494_normal', '25_normal'],
          ),
        ],
      );

      final boxData = BoxData(
        'Box 1',
        'national_overall',
        [victiniEntry, pikachuEntry],
        6,
      );

      await tester.pumpWidget(
        buildTestApp(
          DexBoxView(
            boxes: [boxData],
            liveDex: dex,
            provider: mockDexProvider,
            pageController: PageController(),
            separateForms: false,
            highlightedIds: const {},
            isSearchActive: false,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('box_shiny_lock_badge_494_normal')), findsOneWidget);
      expect(find.byKey(const Key('box_shiny_lock_badge_25_normal')), findsNothing);
    });

    testWidgets("DexListView renders shiny lock badge for N's Pokémon and prevents tapping in Shiny Dex", (tester) async {
      final shinyDex = UserDex(
        id: 'test_dex_shiny_n',
        title: 'Shiny Dex',
        region: 'national_overall',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: true,
        isShinyDex: true,
      );

      await tester.pumpWidget(
        buildTestApp(
          DexListView(
            displayList: [nPurrloinEntry, pikachuEntry],
            liveDex: shinyDex,
            provider: mockDexProvider,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // N's Pokémon has lock badge
      expect(find.byKey(const Key('shiny_lock_badge_509_special_325_n_unova_normal')), findsOneWidget);

      // Tapping N's Pokémon in Shiny Dex does NOT toggle
      await tester.tap(find.textContaining('Felilou'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verifyNever(() => mockDexProvider.togglePokemon(any(), any(), targetState: any(named: 'targetState')));
    });

    testWidgets("DexBoxView renders lock badge on N's Pokémon and prevents tapping in Shiny Dex", (tester) async {
      final shinyDex = UserDex(
        id: 'box_dex_shiny_n',
        title: 'Shiny Box Dex',
        region: 'national_overall',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: true,
        isShinyDex: true,
        customBoxes: [
          CustomBoxState(
            title: 'Box 1',
            pokemonIds: ['509_special_325_n_unova_normal', '25_normal'],
          ),
        ],
      );

      final boxData = BoxData(
        'Box 1',
        'national_overall',
        [nPurrloinEntry, pikachuEntry],
        6,
      );

      await tester.pumpWidget(
        buildTestApp(
          DexBoxView(
            boxes: [boxData],
            liveDex: shinyDex,
            provider: mockDexProvider,
            pageController: PageController(),
            separateForms: false,
            highlightedIds: const {},
            isSearchActive: false,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('box_shiny_lock_badge_509_special_325_n_unova_normal')), findsOneWidget);

      // Tapping N's Pokémon in Shiny Dex does NOT toggle
      await tester.tap(find.byKey(const Key('box_shiny_lock_badge_509_special_325_n_unova_normal')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verifyNever(() => mockDexProvider.togglePokemon(any(), any(), targetState: any(named: 'targetState')));
    });

    testWidgets('DexListView does NOT lock Unown Form N and allows toggling in Shiny Dex', (tester) async {
      final shinyDex = UserDex(
        id: 'test_dex_shiny_unown',
        title: 'Shiny Dex',
        region: 'national_overall',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: true,
        isShinyDex: true,
      );

      when(() => mockDexProvider.togglePokemon(any(), any(), targetState: any(named: 'targetState')))
          .thenReturn(null);

      await tester.pumpWidget(
        buildTestApp(
          DexListView(
            displayList: [unownNEntry],
            liveDex: shinyDex,
            provider: mockDexProvider,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // No lock badge on Unown N
      expect(find.byKey(const Key('shiny_lock_badge_201_n')), findsNothing);

      // Tapping Unown N in Shiny Dex DOES toggle
      await tester.tap(find.textContaining('Icognito'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockDexProvider.togglePokemon('test_dex_shiny_unown', '201_n')).called(1);
    });

    testWidgets('DexBoxView does NOT lock Unown Form N and allows toggling in Shiny Dex', (tester) async {
      final shinyDex = UserDex(
        id: 'box_dex_shiny_unown',
        title: 'Shiny Box Dex',
        region: 'national_overall',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: true,
        isShinyDex: true,
        customBoxes: [
          CustomBoxState(
            title: 'Box 1',
            pokemonIds: ['201_n'],
          ),
        ],
      );

      when(() => mockDexProvider.togglePokemon(any(), any(), targetState: any(named: 'targetState')))
          .thenReturn(null);

      final boxData = BoxData(
        'Box 1',
        'national_overall',
        [unownNEntry],
        6,
      );

      await tester.pumpWidget(
        buildTestApp(
          DexBoxView(
            boxes: [boxData],
            liveDex: shinyDex,
            provider: mockDexProvider,
            pageController: PageController(),
            separateForms: false,
            highlightedIds: const {},
            isSearchActive: false,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // No lock badge on Unown N
      expect(find.byKey(const Key('box_shiny_lock_badge_201_n')), findsNothing);

      // Tapping Unown N card in Shiny Dex DOES toggle
      final cardInkWell = find.ancestor(
        of: find.byType(CachedNetworkImage),
        matching: find.byType(InkWell),
      ).first;
      await tester.tap(cardInkWell);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockDexProvider.togglePokemon('box_dex_shiny_unown', '201_n')).called(1);
    });

    testWidgets('DexListView renders shiny lock badge for Cosplay Pikachu & Starter forms and prevents toggle in Shiny Dex', (tester) async {
      final cosplayForm = PokemonForm(
        name: 'cosplay',
        formType: 'cosplay',
        minGen: 6,
        imageId: 25,
        types: ['electric'],
        exclusiveRegions: [],
      );
      final cosplayEntry = DexDisplayEntry(
        pokemon: pikachu,
        uniqueId: '25_cosplay',
        displaySuffix: ' (Cosplay)',
        imageUrl: 'https://example.com/25_cosplay.png',
        form: cosplayForm,
      );

      final starterForm = PokemonForm(
        name: 'starter',
        formType: 'starter',
        minGen: 7,
        imageId: 25,
        types: ['electric'],
        exclusiveRegions: [],
      );
      final starterPikachuEntry = DexDisplayEntry(
        pokemon: pikachu,
        uniqueId: '25_starter',
        displaySuffix: ' (Starter)',
        imageUrl: 'https://example.com/25_starter.png',
        form: starterForm,
      );

      final shinyDex = UserDex(
        id: 'test_dex_shiny_cosplay',
        title: 'Shiny Dex',
        region: 'national_overall',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: true,
        isShinyDex: true,
      );

      when(() => mockDexProvider.togglePokemon(any(), any(), targetState: any(named: 'targetState')))
          .thenReturn(null);

      await tester.pumpWidget(
        buildTestApp(
          DexListView(
            displayList: [cosplayEntry, starterPikachuEntry],
            liveDex: shinyDex,
            provider: mockDexProvider,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Both should have shiny lock badge rendered
      expect(find.byKey(const Key('shiny_lock_badge_25_cosplay')), findsOneWidget);
      expect(find.byKey(const Key('shiny_lock_badge_25_starter')), findsOneWidget);

      // Tapping in Shiny Dex should NOT toggle
      await tester.tap(find.textContaining('Cosplay'));
      await tester.pump();
      await tester.tap(find.textContaining('Starter'));
      await tester.pump();

      verifyNever(() => mockDexProvider.togglePokemon('test_dex_shiny_cosplay', '25_cosplay'));
      verifyNever(() => mockDexProvider.togglePokemon('test_dex_shiny_cosplay', '25_starter'));
    });

    testWidgets('DexBoxView renders lock badge on Cosplay Pikachu & Starter forms and prevents toggle in Shiny Dex', (tester) async {
      final cosplayForm = PokemonForm(
        name: 'cosplay',
        formType: 'cosplay',
        minGen: 6,
        imageId: 25,
        types: ['electric'],
        exclusiveRegions: [],
      );
      final cosplayEntry = DexDisplayEntry(
        pokemon: pikachu,
        uniqueId: '25_cosplay',
        displaySuffix: ' (Cosplay)',
        imageUrl: 'https://example.com/25_cosplay.png',
        form: cosplayForm,
      );

      final shinyDex = UserDex(
        id: 'box_dex_shiny_cosplay',
        title: 'Shiny Box Dex',
        region: 'national_overall',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: true,
        isShinyDex: true,
        customBoxes: [
          CustomBoxState(
            title: 'Box 1',
            pokemonIds: ['25_cosplay'],
          ),
        ],
      );

      when(() => mockDexProvider.togglePokemon(any(), any(), targetState: any(named: 'targetState')))
          .thenReturn(null);

      final boxData = BoxData(
        'Box 1',
        'national_overall',
        [cosplayEntry],
        6,
      );

      await tester.pumpWidget(
        buildTestApp(
          DexBoxView(
            boxes: [boxData],
            liveDex: shinyDex,
            provider: mockDexProvider,
            pageController: PageController(),
            separateForms: false,
            highlightedIds: const {},
            isSearchActive: false,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('box_shiny_lock_badge_25_cosplay')), findsOneWidget);

      final cardInkWell = find.ancestor(
        of: find.byType(CachedNetworkImage),
        matching: find.byType(InkWell),
      ).first;
      await tester.tap(cardInkWell);
      await tester.pump();

      verifyNever(() => mockDexProvider.togglePokemon('box_dex_shiny_cosplay', '25_cosplay'));
    });
  });
}
