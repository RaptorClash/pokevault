import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokevault/models/tutorial_step.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/providers/tutorial_provider.dart';
import 'package:pokevault/screens/home/create_dex_bottom_sheet.dart';
import 'package:pokevault/widgets/tutorial/tutorial_overlay.dart';
import 'package:pokevault/l10n/app_translations.dart';

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

class MockDexProvider extends Mock implements DexProvider {}
class MockTutorialProvider extends Mock implements TutorialProvider {}

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

  group('CreateDexBottomSheet Glitch Pokémon Tutorial Step (TDD)', () {
    testWidgets('Tutorial contains glitch pokemon step between gifts and forms expansion', (
      WidgetTester tester,
    ) async {
      TutorialFeature? capturedFeature;

      when(() => mockTutorialProvider.hasSeenFeature('create_dex_sheet')).thenReturn(false);
      when(() => mockTutorialProvider.getFeatureStep('create_dex_sheet')).thenReturn(0);
      when(() => mockTutorialProvider.markFeatureAsSeen('create_dex_sheet')).thenAnswer((_) async {});
      when(() => mockTutorialProvider.updateFatureStep('create_dex_sheet', any())).thenAnswer((_) async {});

      await tester.pumpWidget(createBottomSheetWidget());
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 200));

      final tutorialOverlayFinder = find.byType(TutorialOverlay);
      expect(tutorialOverlayFinder, findsOneWidget);

      final overlayWidget = tester.widget<TutorialOverlay>(tutorialOverlayFinder);
      capturedFeature = overlayWidget.feature;
      expect(capturedFeature, isNotNull);

      final steps = capturedFeature.steps;
      final giftsStepIndex = steps.indexWhere(
        (s) => s.titleKey == 'tutorial_create_step_gifts_title',
      );
      final formsStepIndex = steps.indexWhere(
        (s) => s.titleKey == 'tutorial_create_step8_title',
      );
      final glitchStepIndex = steps.indexWhere(
        (s) => s.titleKey == 'tutorial_create_step7_glitch_title',
      );

      expect(giftsStepIndex, isNonNegative, reason: 'Gifts tutorial step should exist');
      expect(formsStepIndex, isNonNegative, reason: 'Forms expansion tutorial step should exist');
      expect(glitchStepIndex, isNonNegative, reason: 'Glitch tutorial step should exist');

      // Must be immediately after gifts and before forms expansion
      expect(glitchStepIndex, equals(giftsStepIndex + 1));
      expect(formsStepIndex, equals(glitchStepIndex + 1));

      final glitchStep = steps[glitchStepIndex];
      expect(glitchStep.titleKey, equals('tutorial_create_step7_glitch_title'));
      expect(glitchStep.textKey, equals('tutorial_create_step7_glitch_text'));
      expect(glitchStep.requireTargetTap, isTrue);

      // Invoke the step that selects national dex so glitch switch is mounted
      final natStep = steps.firstWhere((s) => s.titleKey == 'tutorial_create_step5_title');
      natStep.onTargetTap?.call();
      await tester.pump(const Duration(milliseconds: 200));

      // TargetKey must be attached to the Glitch SwitchListTile
      expect(glitchStep.targetKey, isNotNull);
      final targetContext = glitchStep.targetKey!.currentContext;
      expect(targetContext, isNotNull);

      // Verify that triggering onTargetTap toggles includeGlitch
      glitchStep.onTargetTap?.call();
      await tester.pump(const Duration(milliseconds: 200));

      final glitchSwitchFinder = find.byKey(const Key('switch_include_glitch'));
      expect(glitchSwitchFinder, findsOneWidget);
      final glitchSwitch = tester.widget<SwitchListTile>(glitchSwitchFinder);
      expect(glitchSwitch.value, isTrue);
    });

    test('Translation keys for glitch tutorial step exist in German and English', () {
      Translator.currentLanguage = 'de';
      final titleDe = Translator.get('tutorial_create_step7_glitch_title');
      final textDe = Translator.get('tutorial_create_step7_glitch_text');

      expect(titleDe, isNotEmpty);
      expect(titleDe, isNot(equals('tutorial_create_step7_glitch_title')));
      expect(titleDe.toLowerCase(), contains('glitch'));

      expect(textDe, isNotEmpty);
      expect(textDe, isNot(equals('tutorial_create_step7_glitch_text')));
      expect(textDe.toLowerCase(), contains('glitch'));

      Translator.currentLanguage = 'en';
      final titleEn = Translator.get('tutorial_create_step7_glitch_title');
      final textEn = Translator.get('tutorial_create_step7_glitch_text');

      expect(titleEn, isNotEmpty);
      expect(titleEn, isNot(equals('tutorial_create_step7_glitch_title')));
      expect(titleEn.toLowerCase(), contains('glitch'));

      expect(textEn, isNotEmpty);
      expect(textEn, isNot(equals('tutorial_create_step7_glitch_text')));
      expect(textEn.toLowerCase(), contains('glitch'));
    });

    testWidgets('Advancing step with Next button works without blocking', (
      WidgetTester tester,
    ) async {
      when(() => mockTutorialProvider.hasSeenFeature('create_dex_sheet')).thenReturn(false);
      when(() => mockTutorialProvider.getFeatureStep('create_dex_sheet')).thenReturn(0);
      when(() => mockTutorialProvider.markFeatureAsSeen('create_dex_sheet')).thenAnswer((_) async {});
      when(() => mockTutorialProvider.updateFatureStep('create_dex_sheet', any())).thenAnswer((_) async {});

      await tester.pumpWidget(createBottomSheetWidget());
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 200));

      final nextBtn = find.text('Weiter');
      expect(nextBtn, findsOneWidget);
      await tester.tap(nextBtn);
      await tester.pump(const Duration(milliseconds: 200));
      verify(() => mockTutorialProvider.updateFatureStep('create_dex_sheet', 1)).called(greaterThanOrEqualTo(1));
    });

    testWidgets('Glitch tutorial step renders cleanly on small 320x480 screen without overflow', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      when(() => mockTutorialProvider.hasSeenFeature('create_dex_sheet')).thenReturn(false);
      when(() => mockTutorialProvider.getFeatureStep('create_dex_sheet')).thenReturn(0);
      when(() => mockTutorialProvider.markFeatureAsSeen('create_dex_sheet')).thenAnswer((_) async {});
      when(() => mockTutorialProvider.updateFatureStep('create_dex_sheet', any())).thenAnswer((_) async {});

      await tester.pumpWidget(createBottomSheetWidget());
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
    });
  });
}
