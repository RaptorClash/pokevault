import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokevault/l10n/app_translations.dart';
import 'package:pokevault/providers/settings_provider.dart';
import 'package:pokevault/providers/tutorial_provider.dart';
import 'package:pokevault/screens/settings/controls_guide_screen.dart';
import 'package:pokevault/screens/settings/widgets/misc_settings_cards.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Translator.currentLanguage = 'de';
  });

  Widget createTestWidget({
    TargetPlatform? initialPlatform,
    String language = 'de',
  }) {
    Translator.currentLanguage = language;
    return MaterialApp(
      locale: language == 'de' ? const Locale('de') : const Locale('en'),
      home: ControlsGuideScreen(initialPlatform: initialPlatform),
    );
  }

  group('ControlsGuideScreen Widget Tests', () {
    testWidgets('renders desktop tab by default on TargetPlatform.windows',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(initialPlatform: TargetPlatform.windows),
      );
      await tester.pumpAndSettle();

      // Title & Tabs
      expect(find.text(Translator.get('controls_guide_title')), findsOneWidget);
      expect(find.text(Translator.get('controls_tab_desktop')), findsOneWidget);
      expect(find.text(Translator.get('controls_tab_mobile')), findsOneWidget);

      // Desktop hint card
      expect(
        find.text(Translator.get('controls_platform_hint_desktop')),
        findsOneWidget,
      );

      // Desktop specific controls
      expect(
        find.text(Translator.get('controls_nav_back_key')),
        findsOneWidget,
      );
      expect(
        find.text(Translator.get('controls_dex_toggle_click')),
        findsOneWidget,
      );
      expect(
        find.text(Translator.get('controls_dex_details_key')),
        findsOneWidget,
      );
      expect(
        find.text(Translator.get('controls_hunt_inc_key')),
        findsOneWidget,
      );
      expect(
        find.text(Translator.get('controls_cat_ribbons_marks')),
        findsOneWidget,
      );
      expect(
        find.text(Translator.get('controls_cat_abilities_moves')),
        findsOneWidget,
      );
    });

    testWidgets('renders mobile tab by default on TargetPlatform.android',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(initialPlatform: TargetPlatform.android),
      );
      await tester.pumpAndSettle();

      // Mobile hint card
      expect(
        find.text(Translator.get('controls_platform_hint_mobile')),
        findsOneWidget,
      );

      // Mobile specific controls
      expect(
        find.text(Translator.get('controls_nav_back_gesture')),
        findsOneWidget,
      );
      expect(
        find.text(Translator.get('controls_dex_toggle_tap')),
        findsOneWidget,
      );
      expect(
        find.text(Translator.get('controls_hunt_inc_touch')),
        findsOneWidget,
      );
    });

    testWidgets('switches between tabs on user interaction',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(initialPlatform: TargetPlatform.windows),
      );
      await tester.pumpAndSettle();

      // Initially on Desktop
      expect(
        find.text(Translator.get('controls_platform_hint_desktop')),
        findsOneWidget,
      );

      // Tap on Mobile tab
      final mobileTab = find.text(Translator.get('controls_tab_mobile'));
      await tester.tap(mobileTab);
      await tester.pumpAndSettle();

      // Now Mobile content is visible
      expect(
        find.text(Translator.get('controls_platform_hint_mobile')),
        findsOneWidget,
      );
      expect(
        find.text(Translator.get('controls_dex_toggle_tap')),
        findsOneWidget,
      );

      // Tap back to Desktop tab
      final desktopTab = find.text(Translator.get('controls_tab_desktop'));
      await tester.tap(desktopTab);
      await tester.pumpAndSettle();

      // Desktop content is visible again
      expect(
        find.text(Translator.get('controls_platform_hint_desktop')),
        findsOneWidget,
      );
      expect(
        find.text(Translator.get('controls_nav_back_key')),
        findsOneWidget,
      );
    });

    testWidgets('supports English localization', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(
          initialPlatform: TargetPlatform.windows,
          language: 'en',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Controls & Shortcuts'), findsOneWidget);
      expect(find.text('Desktop & Web'), findsOneWidget);
      expect(find.text('Touch & Mobile'), findsOneWidget);
      expect(
        find.text(
          'Overview of all keyboard and mouse shortcuts for Desktop and Web.',
        ),
        findsOneWidget,
      );
      expect(find.text('Backspace / Browser Back'), findsOneWidget);
      expect(find.text('Spacebar / Up Arrow (↑)'), findsOneWidget);
      expect(find.text('+1 Encounter'), findsOneWidget);
      expect(find.text('Pause / Resume'), findsOneWidget);
    });

    testWidgets('renders mobile tab by default on TargetPlatform.iOS',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(initialPlatform: TargetPlatform.iOS),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(Translator.get('controls_platform_hint_mobile')),
        findsOneWidget,
      );
    });

    testWidgets('renders cleanly on narrow viewports without overflow',
        (tester) async {
      // 320x640 small screen phone
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestWidget(initialPlatform: TargetPlatform.android),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text(Translator.get('controls_platform_hint_mobile')),
        findsOneWidget,
      );
    });

    testWidgets('GeneralCard contains tile and navigates to ControlsGuideScreen',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final prefs = await SharedPreferences.getInstance();
      final settingsProvider = SettingsProvider();
      final tutorialProvider = TutorialProvider(prefs);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settingsProvider),
            ChangeNotifierProvider.value(value: tutorialProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: GeneralCard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final tileFinder =
          find.text(Translator.get('controls_guide_title'));
      expect(tileFinder, findsOneWidget);

      await tester.tap(tileFinder);
      await tester.pumpAndSettle();

      // ControlsGuideScreen is now shown
      expect(find.byType(ControlsGuideScreen), findsOneWidget);
    });
  });
}
