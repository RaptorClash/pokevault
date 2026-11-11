import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokevault/screens/home/home_screen.dart';
import 'package:pokevault/screens/desktop_tracker/desktop_tracker_screen.dart';
import 'package:pokevault/providers/dex_provider.dart';
import 'package:pokevault/providers/tutorial_provider.dart';
import 'package:pokevault/providers/settings_provider.dart';
import 'package:pokevault/models/pokemon.dart';
import 'package:pokevault/models/user_dex.dart';

class MockDexProvider extends Mock implements DexProvider {}
class MockTutorialProvider extends Mock implements TutorialProvider {}
class MockSettingsProvider extends Mock implements SettingsProvider {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDexProvider mockDexProvider;
  late MockTutorialProvider mockTutorialProvider;
  late MockSettingsProvider mockSettingsProvider;

  setUp(() {
    SharedPreferences.setMockInitialValues({});

    mockDexProvider = MockDexProvider();
    mockTutorialProvider = MockTutorialProvider();
    mockSettingsProvider = MockSettingsProvider();

    when(() => mockTutorialProvider.hasSeenFeature(any())).thenReturn(true);
    when(() => mockTutorialProvider.getFeatureStep(any())).thenReturn(0);
    when(() => mockTutorialProvider.shouldShowV16UpdatePrompt).thenReturn(false);
    when(() => mockTutorialProvider.isDeltaTourActive).thenReturn(false);

    when(() => mockSettingsProvider.autoSyncEnabled).thenReturn(false);
    when(() => mockSettingsProvider.googleClientId).thenReturn('');
    when(() => mockSettingsProvider.googleClientSecret).thenReturn('');

    when(() => mockDexProvider.isInitialized).thenReturn(true);
    when(() => mockDexProvider.isMigrating).thenReturn(false);
    when(() => mockDexProvider.userDexes).thenReturn(<UserDex>[]);
    when(() => mockDexProvider.folders).thenReturn(<DexFolder>[]);
    when(() => mockDexProvider.structure).thenReturn({'root': <String>[]});
    when(() => mockDexProvider.allAvailableDexes).thenReturn({});
    when(() => mockDexProvider.allPokemon).thenReturn(<Pokemon>[]);
  });

  Widget buildWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DexProvider>.value(value: mockDexProvider),
        ChangeNotifierProvider<TutorialProvider>.value(value: mockTutorialProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: mockSettingsProvider),
      ],
      child: const MaterialApp(
        home: HomeScreen(),
      ),
    );
  }

  testWidgets('Desktop Tracker action icon appears on Desktop platforms and opens DesktopTrackerScreen', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    // Verify track_changes icon button exists
    final trackerIconFinder = find.byTooltip('Desktop Tracker & Overlay');
    expect(trackerIconFinder, findsOneWidget);

    // Tap icon
    await tester.tap(trackerIconFinder);
    await tester.pumpAndSettle();

    // Verify DesktopTrackerScreen was pushed
    expect(find.byType(DesktopTrackerScreen), findsOneWidget);
  });
}
