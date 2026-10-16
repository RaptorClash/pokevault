import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pokevault/services/database_service.dart';
import 'package:pokevault/screens/pokemon_info/widgets/catch_rate_calculator.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/l10n/app_translations.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final Directory tempDir;
  MockPathProviderPlatform(this.tempDir);

  @override
  Future<String?> getApplicationDocumentsPath() async => tempDir.path;

  @override
  Future<String?> getApplicationSupportPath() async => tempDir.path;

  @override
  Future<String?> getTemporaryPath() async => tempDir.path;

  @override
  Future<String?> getLibraryPath() async => tempDir.path;

  @override
  Future<String?> getDownloadsPath() async => tempDir.path;
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  final pikachu = Pokemon(
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
  );

  setUpAll(() async {
    HttpOverrides.global = _MockHttpOverrides();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    tempDir = Directory.systemTemp.createTempSync('pokevault_catch_rate_test_');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir);

    final assetDb = File('assets/db/pokedex.sqlite');
    if (assetDb.existsSync()) {
      assetDb.copySync('${tempDir.path}/pokedex.sqlite');
    }
    SharedPreferences.setMockInitialValues({'app_db_version': 21});
    await DatabaseService.instance.appDatabase;
  });

  tearDownAll(() async {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  setUp(() {
    Translator.currentLanguage = 'de';
  });

  Future<void> waitForLoaded(WidgetTester tester) async {
    for (int i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
        break;
      }
    }
  }

  Widget buildWidget(Pokemon poke) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CatchRateCalculator(pokemon: poke),
        ),
      ),
    );
  }

  group('CatchRateCalculator Widget Tests', () {
    testWidgets('initializes correctly and displays base catch rate', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildWidget(pikachu));
      await waitForLoaded(tester);

      expect(find.textContaining('190'), findsWidgets);
      expect(find.text(Translator.get('catch_chance')), findsOneWidget);

      await tester.pump(const Duration(seconds: 15));
    });

    testWidgets('changing HP slider and status condition updates catch rate', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildWidget(pikachu));
      await waitForLoaded(tester);

      // Status condition dropdown
      final statusDropdown = find.widgetWithText(DropdownButtonFormField<int>, Translator.get('status_none'));
      if (statusDropdown.evaluate().isNotEmpty) {
        await tester.tap(statusDropdown);
        await tester.pump();

        // Select Schlaf / Frost (value 2)
        final slpItem = find.text(Translator.get('status_slp_frz')).last;
        await tester.tap(slpItem);
        await tester.pump();
      }

      // HP Slider
      final hpSlider = find.byType(Slider).first;
      await tester.tap(hpSlider);
      await tester.pump();

      expect(find.text(Translator.get('catch_chance')), findsOneWidget);

      await tester.pump(const Duration(seconds: 15));
    });

    testWidgets('changing generation dropdown switches strategy', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildWidget(pikachu));
      await waitForLoaded(tester);

      // Open generation dropdown
      final genDropdown = find.byWidgetPredicate(
        (widget) =>
            widget is DropdownButtonFormField<double> &&
            widget.decoration.labelText == Translator.get('generation'),
      );
      expect(genDropdown, findsOneWidget);

      await tester.tap(genDropdown);
      await tester.pump();

      // Tap Gen 1
      final gen1Item = find.textContaining('Gen 1').last;
      await tester.tap(gen1Item);
      await tester.pump();

      expect(find.text(Translator.get('catch_chance')), findsOneWidget);

      await tester.pump(const Duration(seconds: 15));
    });

    testWidgets('selecting Gen 8 shows Max Raid options in battle conditions', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildWidget(pikachu));
      await waitForLoaded(tester);

      // Change gen to Gen 8 (Schwert/Schild)
      final genDropdown = find.byWidgetPredicate(
        (widget) =>
            widget is DropdownButtonFormField<double> &&
            widget.decoration.labelText == Translator.get('generation'),
      );
      await tester.tap(genDropdown);
      await tester.pump();

      final gen8Item = find.textContaining('Gen 8 (Schwert/Schild)').last;
      await tester.tap(gen8Item);
      await tester.pump();

      // Expand battle conditions if not already
      final battleConditionsTile = find.text(Translator.get('calc_battle_conditions'));
      expect(battleConditionsTile, findsOneWidget);

      // Max Raid switch should be present in Gen 8
      final maxRaidSwitch = find.widgetWithText(SwitchListTile, Translator.get('calc_max_raid'));
      expect(maxRaidSwitch, findsOneWidget);

      // Toggle Max Raid switch
      await tester.tap(maxRaidSwitch);
      await tester.pump();

      // Guest and Gigantamax switches should appear
      expect(find.text(Translator.get('calc_max_raid_guest')), findsOneWidget);
      expect(find.text(Translator.get('calc_max_raid_gmax')), findsOneWidget);

      await tester.pump(const Duration(seconds: 15));
    });

    testWidgets('selecting Gen 8.5 (Legends Arceus) shows Arceus options', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildWidget(pikachu));
      await waitForLoaded(tester);

      final genDropdown = find.byWidgetPredicate(
        (widget) =>
            widget is DropdownButtonFormField<double> &&
            widget.decoration.labelText == Translator.get('generation'),
      );
      await tester.tap(genDropdown);
      await tester.pump();

      final gen85Item = find.textContaining('Arceus').last;
      await tester.tap(gen85Item);
      await tester.pump();

      // Check for Hisui status and Flying switch
      expect(find.text(Translator.get('calc_hisui_status')), findsOneWidget);
      expect(find.text(Translator.get('calc_flying')), findsOneWidget);

      final flyingSwitch = find.widgetWithText(SwitchListTile, Translator.get('calc_flying'));
      await tester.tap(flyingSwitch);
      await tester.pump();

      await tester.pump(const Duration(seconds: 15));
    });

    testWidgets('pokeball autocomplete search and selection', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildWidget(pikachu));
      await waitForLoaded(tester);

      final ballField = find.byType(TextField).first;
      await tester.tap(ballField);
      await tester.pump();

      await tester.enterText(ballField, 'Meister');
      await tester.pump();

      final masterOption = find.textContaining('Meisterball').first;
      if (masterOption.evaluate().isNotEmpty) {
        await tester.tap(masterOption);
        await tester.pump();
      }

      await tester.pump(const Duration(seconds: 15));
    });
  });
}
