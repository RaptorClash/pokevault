import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokevault/l10n/app_translations.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/shiny_hunt.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/providers/shiny_hunt_provider.dart';
import 'package:pokevault/screens/shiny_hunt/dialogs/shiny_catch_dialog.dart';
import 'package:pokevault/services/database_service.dart';

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
  final Map<String, ShinyHunt> hunts = {};

  @override
  Future<List<ShinyHunt>> getAllShinyHunts({bool includeDeleted = false}) async =>
      hunts.values.where((h) => includeDeleted || h.deletedAt == 0).toList();

  @override
  Future<ShinyHunt?> getShinyHunt(String id) async => hunts[id];

  @override
  Future<void> saveShinyHunt(ShinyHunt hunt) async {
    hunts[hunt.id] = hunt;
  }

  @override
  Future<Map<String, String>> getBallUrls() async => {
        'poke_ball': 'https://example.com/poke_ball.png',
        'great_ball': 'https://example.com/great_ball.png',
        'ultra_ball': 'https://example.com/ultra_ball.png',
        'luxury_ball': 'https://example.com/luxury_ball.png',
        'love_ball': 'https://example.com/love_ball.png',
      };

  @override
  Future<Map<String, List<String>>?> getMatchingBalls(String targetUniqueId) async {
    if (targetUniqueId == '487_normal' || targetUniqueId == '487') {
      return {
        'normal': ['luxury_ball', 'ultra_ball'],
        'shiny': ['luxury_ball'],
      };
    }
    return null;
  }
}

class FakeDexProvider extends ChangeNotifier implements DexProvider {
  final List<UserDex> _userDexes;

  FakeDexProvider({List<UserDex>? userDexes}) : _userDexes = userDexes ?? [];

  @override
  List<UserDex> get userDexes => _userDexes;

  @override
  List<Pokemon> get allPokemon => [];

  @override
  Future<void> markPokemonCaughtAndShiny(String dexId, String uniqueId) async {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeDatabaseService fakeDb;
  late ShinyHuntProvider huntProvider;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({'app_db_version': 21});
    HttpOverrides.global = _MockHttpOverrides();
  });

  setUp(() async {
    Translator.currentLanguage = 'de';
    fakeDb = FakeDatabaseService();
    huntProvider = ShinyHuntProvider(
      databaseService: fakeDb,
      enableTimer: false,
    );
    await huntProvider.initialized;
  });

  Widget buildTestDialog(Widget dialog, {FakeDexProvider? customDexProvider}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ShinyHuntProvider>.value(value: huntProvider),
        ChangeNotifierProvider<DexProvider>.value(
          value: customDexProvider ?? FakeDexProvider(),
        ),
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

  group('ShinyCatchDialog Tests', () {
    testWidgets('Matching balls are highlighted and sorted to top with raw ID fallback', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final now = DateTime.now();
      final hunt = ShinyHunt(
        id: 'hunt-giratina-1',
        title: 'Giratina Hunt',
        pokemonId: 487,
        pokemonName: 'Giratina',
        game: 'Diamant / Perl / Platin',
        generation: 4.0,
        method: 'Standard Wild / Soft Reset',
        baseOdds: 8192.0,
        currentEncounters: 1250,
        targetDexId: 'dex-sinnoh',
        targetUniqueId: null, // Null targetUniqueId triggers 487_normal fallback
        createdAt: now,
        updatedAt: now,
      );
      await huntProvider.createHunt(hunt);

      await tester.pumpWidget(
        buildTestDialog(
          ShinyCatchDialog(
            hunt: hunt,
            databaseService: fakeDb,
          ),
          customDexProvider: FakeDexProvider(
            userDexes: [
              UserDex(
                id: 'dex-sinnoh',
                title: 'Sinnoh Dex',
                region: 'sinnoh',
                includeGenders: false,
                includeRegional: false,
                includeMega: false,
                includeGMax: false,
                includeOther: false,
                isShinyDex: false,
              ),
            ],
          ),
        ),
      );
      await pumpView(tester);

      // Verify matching ball icon (star) is displayed for luxury_ball
      expect(find.byIcon(Icons.star), findsWidgets);

      // Verify single dex checkbox is rendered for linked target dex
      expect(
        find.text('In "Sinnoh Dex" als gefangen & Shiny markieren'),
        findsOneWidget,
      );
      // Ensure duplicate dropdown is NOT rendered
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);

      // Verify localized tooltip for ball
      final luxuryTooltip = find.byTooltip('Luxusball ✨ (Matching Ball)');
      expect(luxuryTooltip, findsOneWidget);

      // Verify love ball tooltip is localized (not raw 'love_ball')
      final loveTooltip = find.byTooltip('Sympaball');
      expect(loveTooltip, findsOneWidget);
    });

    testWidgets('Confirming catch archives and completes the hunt', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final now = DateTime.now();
      final hunt = ShinyHunt(
        id: 'hunt-giratina-catch',
        title: 'Giratina Hunt',
        pokemonId: 487,
        pokemonName: 'Giratina',
        game: 'Diamant / Perl / Platin',
        generation: 4.0,
        method: 'Standard Wild / Soft Reset',
        baseOdds: 8192.0,
        currentEncounters: 3500,
        targetDexId: null,
        targetUniqueId: null,
        createdAt: now,
        updatedAt: now,
      );
      await huntProvider.createHunt(hunt);

      bool? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await showDialog<bool>(
                    context: ctx,
                    builder: (_) => MultiProvider(
                      providers: [
                        ChangeNotifierProvider<ShinyHuntProvider>.value(value: huntProvider),
                        ChangeNotifierProvider<DexProvider>.value(value: FakeDexProvider()),
                      ],
                      child: ShinyCatchDialog(
                        hunt: hunt,
                        databaseService: fakeDb,
                      ),
                    ),
                  );
                },
                child: const Text('Open Catch Dialog'),
              ),
            ),
          ),
        ),
      );
      await pumpView(tester);

      await tester.tap(find.text('Open Catch Dialog'));
      await pumpView(tester);

      // Enter notes
      final notesField = find.byType(TextFormField).last;
      await tester.enterText(notesField, 'Caught on SR 3500!');
      await pumpView(tester);

      // Click "Fang eintragen" (confirm button)
      final confirmBtn = find.byIcon(Icons.check_circle);
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await pumpView(tester);

      // Dialog closed and returned true
      expect(dialogResult, isTrue);

      // Hunt is completed in provider
      final updatedHunt = huntProvider.getHuntById('hunt-giratina-catch');
      expect(updatedHunt, isNotNull);
      expect(updatedHunt!.isCompleted, isTrue);
      expect(updatedHunt.status, equals('completed'));
      expect(updatedHunt.ballUsed, isNotNull);
      expect(updatedHunt.notes, equals('Caught on SR 3500!'));
    });
  });
}
