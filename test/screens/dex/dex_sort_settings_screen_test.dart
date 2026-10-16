import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:pokevault/models/user_dex.dart';
import 'package:pokevault/screens/dex/dex_sort_settings_screen.dart';
import '../../e2e/helpers/e2e_test_helper.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async =>
      Directory.systemTemp.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    PathProviderPlatform.instance = MockPathProviderPlatform();
  });

  testWidgets('DexSortSettingsScreen renders and updates sort settings with forceRefresh', (tester) async {
    final dex = UserDex(
      id: 'test_sort_dex',
      title: 'Sort Dex',
      region: 'kanto',
      includeGenders: false,
      includeRegional: false,
      includeMega: false,
      includeGMax: false,
      includeOther: false,
      isShinyDex: false,
      megaSort: 'origin',
      gmaxSort: 'origin',
      regionalSort: 'origin',
    );

    final mockDexProvider = MockDexProvider();
    when(() => mockDexProvider.forceRefresh()).thenReturn(null);
    when(() => mockDexProvider.updateSortSettings(
      dex: dex,
      megaSort: any(named: 'megaSort'),
      gmaxSort: any(named: 'gmaxSort'),
      regionalSort: any(named: 'regionalSort'),
    )).thenAnswer((invocation) async {
      dex.megaSort = invocation.namedArguments[#megaSort] as String;
      dex.gmaxSort = invocation.namedArguments[#gmaxSort] as String;
      dex.regionalSort = invocation.namedArguments[#regionalSort] as String;
      mockDexProvider.forceRefresh();
    });

    await tester.pumpWidget(
      wrapWithApp(
        child: DexSortSettingsScreen(dex: dex),
        mockDexProvider: mockDexProvider,
        language: 'de',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RadioGroup<String>), findsNWidgets(3));
    expect(find.byType(RadioListTile<String>), findsNWidgets(6));

    // Tap 'Region der Mechanik (Kalos/Hoenn)' under Mega
    final mechanicTile = find.widgetWithText(RadioListTile<String>, 'Region der Mechanik (Kalos/Hoenn)');
    expect(mechanicTile, findsOneWidget);
    await tester.tap(mechanicTile);
    await tester.pumpAndSettle();

    expect(dex.megaSort, 'mechanic');
    verify(() => mockDexProvider.forceRefresh()).called(1);

    // Tap 'Region der Mechanik (Galar)' under GMax
    final gmaxMechanicTile = find.widgetWithText(RadioListTile<String>, 'Region der Mechanik (Galar)');
    expect(gmaxMechanicTile, findsOneWidget);
    await tester.tap(gmaxMechanicTile);
    await tester.pumpAndSettle();

    expect(dex.gmaxSort, 'mechanic');
    verify(() => mockDexProvider.forceRefresh()).called(1);

    // Tap 'Region der Form (z.B. Alola)' under Regional
    final regionalMechanicTile = find.widgetWithText(RadioListTile<String>, 'Region der Form (z.B. Alola)');
    expect(regionalMechanicTile, findsOneWidget);
    await tester.tap(regionalMechanicTile);
    await tester.pumpAndSettle();

    expect(dex.regionalSort, 'mechanic');
    verify(() => mockDexProvider.forceRefresh()).called(1);
  });
}
