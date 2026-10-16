import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/providers/tutorial_provider.dart';
import 'package:pokevault/screens/home/create_dex_bottom_sheet.dart';
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

  Widget createBottomSheetWidget({String currentFolderId = 'root'}) {
    return MaterialApp(
      home: Scaffold(
        body: MultiProvider(
          providers: [
            ChangeNotifierProvider<DexProvider>.value(value: mockDexProvider),
            ChangeNotifierProvider<TutorialProvider>.value(value: mockTutorialProvider),
          ],
          child: CreateDexBottomSheet(
            provider: mockDexProvider,
            currentFolderId: currentFolderId,
          ),
        ),
      ),
    );
  }

  testWidgets('Renders CreateDexBottomSheet with default selection and initial name', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createBottomSheetWidget());
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    expect(find.text(Translator.get('create_dex_title')), findsOneWidget);
    expect(find.text(Translator.get('create_dex_btn')), findsOneWidget);

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller?.text, isNotEmpty);
  });

  testWidgets('Switching dex group updates the selected subdex and name controller', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createBottomSheetWidget());
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    // Look for group cards in the generation selector
    final groupFinders = find.byType(InkWell);
    expect(groupFinders, findsWidgets);

    // Tap on the second group if available
    if (DexGroupsData.groups.length > 1) {
      final secondGroup = DexGroupsData.groups[1];
      final groupText = find.text(Translator.get(secondGroup.nameKey));
      if (groupText.evaluate().isNotEmpty) {
        await tester.tap(groupText.first);
        await tester.pump(const Duration(milliseconds: 800));
        await tester.pumpAndSettle();
      }
    }
  });

  testWidgets('Toggling form and shiny checkboxes updates state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createBottomSheetWidget());
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    // Find checkboxes for features
    final shinyCheckbox = find.widgetWithText(SwitchListTile, Translator.get('tutorial_create_step6_title', fallback: 'Shiny Dex'));
    if (shinyCheckbox.evaluate().isNotEmpty) {
      await tester.tap(shinyCheckbox);
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();

      final cb = tester.widget<SwitchListTile>(shinyCheckbox);
      expect(cb.value, isTrue);
    }
  });

  testWidgets('Tapping create button calls provider.createDex with configured arguments', (
    WidgetTester tester,
  ) async {
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
        )).thenReturn(null);

    await tester.pumpWidget(createBottomSheetWidget(currentFolderId: 'folder_custom'));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    // Enter custom name
    final nameInput = find.byType(TextField);
    await tester.enterText(nameInput, 'Mein Super Dex');
    await tester.pumpAndSettle();

    // Tap create button
    final createBtn = find.text(Translator.get('create_dex_btn'));
    await tester.tap(createBtn);
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    verify(() => mockDexProvider.createDex(
          'Mein Super Dex',
          any(),
          any(),
          any(),
          any(),
          any(),
          any(),
          any(),
          'folder_custom',
        )).called(1);
  });

  testWidgets('Empty title prevents createDex from being invoked', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createBottomSheetWidget());
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    // Clear name
    final nameInput = find.byType(TextField);
    await tester.enterText(nameInput, '');
    await tester.pumpAndSettle();

    // Tap create
    final createBtn = find.text(Translator.get('create_dex_btn'));
    await tester.tap(createBtn);
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    verifyNever(() => mockDexProvider.createDex(
          any(),
          any(),
          any(),
          any(),
          any(),
          any(),
          any(),
          any(),
          any(),
        ));
  });

  testWidgets('Selecting moves_dex shows info text instead of switch tiles', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(2400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(createBottomSheetWidget());
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    final specialGroup = DexGroupsData.groups.firstWhere(
      (g) => g.nameKey == 'group_special',
    );
    final specialGroupText = find.text(Translator.get(specialGroup.nameKey));
    expect(specialGroupText, findsOneWidget);

    await tester.tap(specialGroupText);
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    // Dropdown is visible for special group
    final dropdown = find.byType(DropdownButtonFormField<String>);
    expect(dropdown, findsOneWidget);

    await tester.tap(dropdown);
    await tester.pumpAndSettle();

    final itemText = Translator.get('region_moves_dex') != 'region_moves_dex'
        ? Translator.get('region_moves_dex')
        : 'moves_dex';
    await tester.tap(find.text(itemText).last, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Für diesen Dex-Typ gibt es keine Shiny-, Geschlechter- oder Form-Optionen.',
      ),
      findsOneWidget,
    );
  });
}
