import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/providers/tutorial_provider.dart';
import 'package:pokevault/screens/home/create_dex_bottom_sheet.dart';
import 'package:pokevault/screens/home/edit_dex_dialog.dart';
import 'package:pokevault/data/dex_groups_data.dart';
import 'package:pokevault/l10n/app_translations.dart';
import '../../e2e/helpers/e2e_test_helper.dart';

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

class _MockHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
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
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDexProvider mockDexProvider;
  late MockTutorialProvider mockTutorialProvider;

  setUpAll(() {
    HttpOverrides.global = _MockHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Translator.currentLanguage = 'de';
    mockDexProvider = MockDexProvider();
    mockTutorialProvider = MockTutorialProvider();

    when(() => mockTutorialProvider.hasSeenFeature(any())).thenReturn(true);
    when(() => mockTutorialProvider.getFeatureStep(any())).thenReturn(0);
  });

  Widget createWidgetUnderTest(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DexProvider>.value(value: mockDexProvider),
        ChangeNotifierProvider<TutorialProvider>.value(value: mockTutorialProvider),
      ],
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('CreateDexBottomSheet & EditDexDialog Glitch and Defaults UI Tests (TDD)', () {
    testWidgets('CreateDexBottomSheet defaults trades, gifts, and glitch switches to false', (tester) async {
      when(() => mockDexProvider.createDex(
        any(),
        any(),
        any(),
        any(),
        any(),
        any(),
        any(),
        any(),
        any(),
        includeTrades: any(named: 'includeTrades'),
        includeGifts: any(named: 'includeGifts'),
        includeGlitch: any(named: 'includeGlitch'),
      )).thenReturn(null);

      await tester.pumpWidget(
        createWidgetUnderTest(
          CreateDexBottomSheet(
            provider: mockDexProvider,
            currentFolderId: 'root',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final natGroup = DexGroupsData.groups.firstWhere((g) => g.nameKey == 'group_national');
      final groupFinder = find.text(Translator.get(natGroup.nameKey));
      if (groupFinder.evaluate().isNotEmpty) {
        await tester.tap(groupFinder.first);
        await tester.pumpAndSettle();
      }

      final tradesFinder = find.byKey(const Key('switch_include_trades'));
      final giftsFinder = find.byKey(const Key('switch_include_gifts'));
      final glitchFinder = find.byKey(const Key('switch_include_glitch'));

      expect(tradesFinder, findsOneWidget);
      expect(giftsFinder, findsOneWidget);
      expect(glitchFinder, findsOneWidget);

      final tradesSwitch = tester.widget<SwitchListTile>(tradesFinder);
      final giftsSwitch = tester.widget<SwitchListTile>(giftsFinder);
      final glitchSwitch = tester.widget<SwitchListTile>(glitchFinder);

      expect(tradesSwitch.value, isFalse, reason: 'Trades must be false by default');
      expect(giftsSwitch.value, isFalse, reason: 'Gifts must be false by default');
      expect(glitchSwitch.value, isFalse, reason: 'Glitch must be false by default');

      // Toggle glitch to true
      await tester.ensureVisible(glitchFinder);
      await tester.tap(glitchFinder);
      await tester.pumpAndSettle();

      final updatedGlitchSwitch = tester.widget<SwitchListTile>(glitchFinder);
      expect(updatedGlitchSwitch.value, isTrue);

      final createBtn = find.byType(ElevatedButton);
      await tester.ensureVisible(createBtn);
      await tester.tap(createBtn);
      await tester.pumpAndSettle();

      verify(() => mockDexProvider.createDex(
        any(),
        any(),
        any(),
        any(),
        any(),
        any(),
        any(),
        any(),
        any(),
        includeTrades: false,
        includeGifts: false,
        includeGlitch: true,
      )).called(1);
    });

    testWidgets('EditDexDialog renders glitch switch with dex value and calls updateDex', (tester) async {
      final testDex = UserDex(
        id: 'edit_dex_glitch',
        title: 'Edit Glitch Dex',
        region: 'kanto',
        includeGenders: false,
        includeRegional: false,
        includeMega: false,
        includeGMax: false,
        includeOther: false,
        includeTrades: false,
        includeGifts: false,
        includeGlitch: true,
        isShinyDex: false,
      );

      await tester.pumpWidget(
        createWidgetUnderTest(
          EditDexDialog(
            dex: testDex,
            provider: mockDexProvider,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final glitchFinder = find.byKey(const Key('edit_switch_include_glitch'));
      expect(glitchFinder, findsOneWidget);

      final glitchSwitch = tester.widget<SwitchListTile>(glitchFinder);
      expect(glitchSwitch.value, isTrue);

      // Toggle off
      await tester.tap(glitchFinder);
      await tester.pumpAndSettle();

      final saveBtn = find.widgetWithText(ElevatedButton, Translator.get('save'));
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      verify(() => mockDexProvider.updateDex(
        'edit_dex_glitch',
        'Edit Glitch Dex',
        false,
        false,
        false,
        false,
        false,
        false,
        includeTrades: false,
        includeGifts: false,
        includeGlitch: false,
      )).called(1);
    });
  });
}
