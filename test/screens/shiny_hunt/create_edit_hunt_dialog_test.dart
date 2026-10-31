import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:pokevault/i18n/strings.g.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/shiny_hunt.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/providers/shiny_hunt_provider.dart';
import 'package:pokevault/screens/shiny_hunt/dialogs/create_edit_hunt_dialog.dart';
import 'package:pokevault/services/database_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
// ignore: depend_on_referenced_packages
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

class MockWakelockPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements WakelockPlusPlatformInterface {
  bool _enabled = false;
  @override
  Future<void> toggle({required bool enable}) async {
    _enabled = enable;
  }
  @override
  Future<bool> get enabled async => _enabled;
  @override
  bool get isMock => true;
}

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

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;

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
}

final Uint8List _kTransparentImage = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
]);

class FakeDatabaseService extends Fake implements DatabaseService {
  final Map<String, ShinyHunt> _hunts = {};

  @override
  Future<List<ShinyHunt>> getAllShinyHunts({bool includeDeleted = false}) async =>
      _hunts.values.where((h) => includeDeleted || h.deletedAt == 0).toList();

  @override
  Future<ShinyHunt?> getShinyHunt(String id) async => _hunts[id];

  @override
  Future<void> saveShinyHunt(ShinyHunt hunt) async {
    _hunts[hunt.id] = hunt;
  }

  @override
  Future<List<String>> getShinyCategories(int pokemonId) async {
    if (pokemonId == 487) {
      return ['legendary_mythical'];
    }
    return [];
  }

  @override
  Future<Map<String, Map<String, List<String>>>> getEncounters(int pokemonId) async => {};
}

class FakeDexProvider extends ChangeNotifier implements DexProvider {
  @override
  List<Pokemon> get allPokemon => [
        Pokemon(
          id: 487,
          nameDe: 'Giratina',
          nameEn: 'Giratina',
          hasGenderDifferences: false,
          genderRate: -1,
          captureRate: 3,
          evolutionChainId: 250,
          eggGroups: ['undiscovered'],
          weight: 750.0,
          speed: 90,
          forms: [],
        ),
        Pokemon(
          id: 172,
          nameDe: 'Pichu',
          nameEn: 'Pichu',
          hasGenderDifferences: false,
          genderRate: 4,
          captureRate: 190,
          evolutionChainId: 10,
          eggGroups: ['undiscovered'],
          weight: 2.0,
          speed: 60,
          forms: [],
        ),
        Pokemon(
          id: 152,
          nameDe: 'Endivie',
          nameEn: 'Chikorita',
          hasGenderDifferences: false,
          genderRate: 1,
          captureRate: 45,
          evolutionChainId: 70,
          eggGroups: ['Monster', 'Grass'],
          weight: 6.4,
          speed: 45,
          forms: [],
        ),
        Pokemon(
          id: 25,
          nameDe: 'Pikachu',
          nameEn: 'Pikachu',
          hasGenderDifferences: true,
          genderRate: 4,
          captureRate: 190,
          evolutionChainId: 10,
          eggGroups: ['Field', 'Fairy'],
          weight: 6.0,
          speed: 90,
          forms: [],
        ),
        Pokemon(
          id: 92,
          nameDe: 'Nebulak',
          nameEn: 'Gastly',
          hasGenderDifferences: false,
          genderRate: 4,
          captureRate: 190,
          evolutionChainId: 42,
          eggGroups: ['Amorphous'],
          weight: 0.1,
          speed: 80,
          forms: [],
        ),
      ];

  @override
  List<UserDex> get userDexes => [];

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeDatabaseService fakeDb;
  late ShinyHuntProvider huntProvider;
  late FakeDexProvider dexProvider;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({'app_db_version': 21});
    HttpOverrides.global = _MockHttpOverrides();
    WakelockPlusPlatformInterface.instance = MockWakelockPlatform();
    wakelockPlusPlatformInstance = MockWakelockPlatform();
  });

  setUp(() async {
    LocaleSettings.setLocale(AppLocale.de);
    fakeDb = FakeDatabaseService();
    huntProvider = ShinyHuntProvider(
      databaseService: fakeDb,
      enableTimer: false,
    );
    await huntProvider.initialized;
    dexProvider = FakeDexProvider();
  });

  Widget buildTestDialog(Widget dialog) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ShinyHuntProvider>.value(value: huntProvider),
        ChangeNotifierProvider<DexProvider>.value(value: dexProvider),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: dialog,
        ),
      ),
    );
  }

  Future<void> pumpView(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('CreateEditHuntDialog Tests', () {
    testWidgets('Giratina (#487) excludes Gen 1-3 games and restricts methods to SR / Custom', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestDialog(
          const CreateEditHuntDialog(
            initialPokemonId: 487,
            initialPokemonName: 'Giratina',
          ),
        ),
      );
      await pumpView(tester);

      // Find Game dropdown by key
      final gameDropdown = find.byWidgetPredicate(
        (w) => w is DropdownButtonFormField<String> && (w.key?.toString().contains('game') ?? false),
      );
      expect(gameDropdown, findsOneWidget);

      // Tap game dropdown to open menu
      await tester.tap(gameDropdown);
      await pumpView(tester);

      // Verify Gen 1-3 games are NOT in the dropdown
      expect(find.text('Gen 1: Rot / Blau / Gelb'), findsNothing);
      expect(find.text('Gen 2: Gold / Silber / Kristall'), findsNothing);
      expect(find.text('Gen 3: Rubin / Saphir / Smaragd'), findsNothing);
      expect(find.text('Gen 3: Feuerrot / Blattgrün'), findsNothing);

      // Verify Gen 4+ games ARE present
      expect(find.text('Gen 4: Diamant / Perl / Platin'), findsWidgets);

      // Select Gen 4
      await tester.tap(find.text('Gen 4: Diamant / Perl / Platin').last);
      await pumpView(tester);

      // Tap Method dropdown
      final methodDropdown = find.byWidgetPredicate(
        (w) => w is DropdownButtonFormField<String> && (w.key?.toString().contains('method') ?? false),
      );
      expect(methodDropdown, findsOneWidget);

      await tester.tap(methodDropdown);
      await pumpView(tester);

      // Giratina in Gen 4: ONLY Soft Reset / Wild and Custom are permitted
      expect(find.text('Standard Wild / Soft Reset'), findsWidgets);
      expect(find.text('Benutzerdefiniert / Eigene Odds'), findsWidgets);

      // Ensure disallowed methods are absent
      expect(find.text('Masuda-Methode'), findsNothing);
      expect(find.text('Poké-Radar (Kette 40+)'), findsNothing);
      expect(find.text('Cute Charm Glitch'), findsNothing);
      expect(find.text('HGSS Starter Soft Reset'), findsNothing);
    });

    testWidgets('Baby Pokémon Pichu (#172) in Gen 2 allows Odd Egg and breeding', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestDialog(
          const CreateEditHuntDialog(
            initialPokemonId: 172,
            initialPokemonName: 'Pichu',
            initialGame: 'Gold / Silber / Kristall',
            initialGeneration: 2.0,
          ),
        ),
      );
      await pumpView(tester);

      final methodDropdown = find.byWidgetPredicate(
        (w) => w is DropdownButtonFormField<String> && (w.key?.toString().contains('method') ?? false),
      );
      expect(methodDropdown, findsOneWidget);

      await tester.tap(methodDropdown);
      await pumpView(tester);

      // Odd Egg and Masuda/Breeding should be present
      expect(find.text('Kurioses Ei / Odd Egg (Kristall)'), findsWidgets);
      expect(find.text('Shiny-Zucht / Ditto-Glitch'), findsWidgets);
    });

    testWidgets('Starter Endivie (#152) in Gen 4 HGSS shows HGSS Starter method', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestDialog(
          const CreateEditHuntDialog(
            initialPokemonId: 152,
            initialPokemonName: 'Endivie',
            initialGame: 'HeartGold / SoulSilver',
            initialGeneration: 4.0,
          ),
        ),
      );
      await pumpView(tester);

      final methodDropdown = find.byWidgetPredicate(
        (w) => w is DropdownButtonFormField<String> && (w.key?.toString().contains('method') ?? false),
      );
      expect(methodDropdown, findsOneWidget);

      await tester.tap(methodDropdown);
      await pumpView(tester);

      expect(find.text('HGSS Starter Soft Reset'), findsWidgets);
    });

    testWidgets('Submitting dialog pops and returns the created ShinyHunt', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      ShinyHunt? returnedHunt;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ShinyHuntProvider>.value(value: huntProvider),
            ChangeNotifierProvider<DexProvider>.value(value: dexProvider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () async {
                    returnedHunt = await showDialog<ShinyHunt?>(
                      context: ctx,
                      builder: (_) => const CreateEditHuntDialog(
                        initialPokemonId: 25,
                        initialPokemonName: 'Pikachu',
                        initialGame: 'Karmesin / Purpur',
                        initialGeneration: 9.0,
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );
      await pumpView(tester);

      // Open the dialog
      await tester.tap(find.text('Open Dialog'));
      await pumpView(tester);

      // Press Starten button
      final startBtn = find.widgetWithText(ElevatedButton, 'Starten');
      expect(startBtn, findsOneWidget);
      await tester.tap(startBtn);
      await pumpView(tester);

      // Dialog should be closed and returnedHunt populated
      expect(returnedHunt, isNotNull);
      expect(returnedHunt!.pokemonId, equals(25));
      expect(returnedHunt!.pokemonName, equals('Pikachu'));
      expect(returnedHunt!.game, equals('Karmesin / Purpur'));
    });

    testWidgets('Shows Pokémon-Turm / Silph Scope method for Gastly in Gen 1', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestDialog(
          const CreateEditHuntDialog(
            initialPokemonId: 92,
            initialPokemonName: 'Nebulak',
            initialGame: 'Rot / Blau / Gelb',
            initialGeneration: 1.0,
          ),
        ),
      );
      await pumpView(tester);

      final methodDropdown = find.byWidgetPredicate(
        (w) => w is DropdownButtonFormField<String> && (w.key?.toString().contains('method') ?? false),
      );
      expect(methodDropdown, findsOneWidget);

      await tester.tap(methodDropdown);
      await pumpView(tester);

      expect(find.text('Pokémon-Turm / Silph Scope'), findsWidgets);
    });

    testWidgets('Does not show Pokémon-Turm / Silph Scope method for Pikachu in Gen 1', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestDialog(
          const CreateEditHuntDialog(
            initialPokemonId: 25,
            initialPokemonName: 'Pikachu',
            initialGame: 'Rot / Blau / Gelb',
            initialGeneration: 1.0,
          ),
        ),
      );
      await pumpView(tester);

      final methodDropdown = find.byWidgetPredicate(
        (w) => w is DropdownButtonFormField<String> && (w.key?.toString().contains('method') ?? false),
      );
      expect(methodDropdown, findsOneWidget);

      await tester.tap(methodDropdown);
      await pumpView(tester);

      expect(find.text('Pokémon-Turm / Silph Scope'), findsNothing);
    });

    testWidgets('Defaults to Pokémon-Turm / Silph Scope for Gastly in Gen 1', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      ShinyHunt? returnedHunt;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ShinyHuntProvider>.value(value: huntProvider),
            ChangeNotifierProvider<DexProvider>.value(value: dexProvider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () async {
                    returnedHunt = await showDialog<ShinyHunt?>(
                      context: ctx,
                      builder: (_) => const CreateEditHuntDialog(
                        initialPokemonId: 92,
                        initialPokemonName: 'Nebulak',
                        initialGame: 'Rot / Blau / Gelb',
                        initialGeneration: 1.0,
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );
      await pumpView(tester);

      await tester.tap(find.text('Open Dialog'));
      await pumpView(tester);

      final startBtn = find.widgetWithText(ElevatedButton, 'Starten');
      expect(startBtn, findsOneWidget);
      await tester.tap(startBtn);
      await pumpView(tester);

      expect(returnedHunt, isNotNull);
      expect(returnedHunt!.method, equals('Pokémon-Turm / Silph Scope'));
      expect(returnedHunt!.baseOdds, equals(8192.0));
      expect(returnedHunt!.game, equals('Rot / Blau / Gelb'));
      expect(returnedHunt!.generation, equals(1.0));
    });
  });
}
