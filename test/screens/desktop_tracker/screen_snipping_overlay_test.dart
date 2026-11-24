import 'dart:typed_data';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/screens/desktop_tracker/widgets/screen_snipping_overlay.dart';
import 'package:pokevault/services/desktop_tracker/screen_region.dart';

void main() {
  group('ScreenSnippingOverlay Widget Tests (TDD)', () {
    testWidgets('Renders snipping overlay with instructions and cancel button', (tester) async {
      bool cancelled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScreenSnippingOverlay(
              onRegionSelected: (_) {},
              onCancel: () => cancelled = true,
            ),
          ),
        ),
      );

      expect(find.textContaining('Snipping-Modus'), findsOneWidget);
      expect(find.byKey(const Key('btn_cancel_snipping')), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_cancel_snipping')));
      await tester.pump();
      expect(cancelled, isTrue);
    });

    testWidgets('Allows dragging to define a rectangle and confirms region', (tester) async {
      ScreenRegion? selectedRegion;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: ScreenSnippingOverlay(
                onRegionSelected: (region) => selectedRegion = region,
                onCancel: () {},
              ),
            ),
          ),
        ),
      );

      // Drag from (100, 160) to (500, 360) below the instruction bar
      final gesture = await tester.startGesture(const Offset(100, 160));
      await tester.pump();
      await gesture.moveTo(const Offset(500, 360));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      // Dimension badge should be rendered
      expect(find.textContaining('400 x 200'), findsOneWidget);

      // Tap confirm button
      final confirmBtn = find.byKey(const Key('btn_confirm_snipping'));
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pump();

      expect(selectedRegion, isNotNull);
      expect(selectedRegion!.width, 400);
      expect(selectedRegion!.height, 200);
      expect(selectedRegion!.isAbsoluteScreen, isTrue);
    });

    testWidgets('Allows selecting a DS Top Screen preset chip and confirms it', (tester) async {
      ScreenRegion? selectedRegion;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: ScreenSnippingOverlay(
                onRegionSelected: (region) => selectedRegion = region,
                onCancel: () {},
              ),
            ),
          ),
        ),
      );

      final dsTopChip = find.byKey(const Key('chip_preset_ds_top'));
      expect(dsTopChip, findsOneWidget);
      await tester.tap(dsTopChip);
      await tester.pump();

      // Dimension badge for 800 x 312 (top screen) should appear
      expect(find.textContaining('800 x 312'), findsOneWidget);

      final confirmBtn = find.byKey(const Key('btn_confirm_snipping'));
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pump();

      expect(selectedRegion, isNotNull);
      expect(selectedRegion!.height, 312);
      expect(selectedRegion!.width, 800);
      expect(selectedRegion!.label, contains('DS Oben'));
    });

    testWidgets('Renders native Windows Snipping and Clipboard buttons and triggers callbacks', (tester) async {
      bool windowsSnippingTriggered = false;
      bool clipboardPasteTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScreenSnippingOverlay(
              onRegionSelected: (_) {},
              onCancel: () {},
              onTriggerWindowsSnipping: () => windowsSnippingTriggered = true,
              onPasteFromClipboard: () => clipboardPasteTriggered = true,
            ),
          ),
        ),
      );

      final winSnipBtn = find.byKey(const Key('btn_native_desktop_snipping'));
      expect(winSnipBtn, findsOneWidget);
      await tester.tap(winSnipBtn);
      await tester.pump();
      expect(windowsSnippingTriggered, isTrue);

      final pasteBtn = find.byKey(const Key('btn_paste_from_clipboard_in_snipping'));
      expect(pasteBtn, findsOneWidget);
      await tester.tap(pasteBtn);
      await tester.pump();
      expect(clipboardPasteTriggered, isTrue);
    });

    testWidgets('Renders desktopBackgroundBytes when provided', (tester) async {
      final sampleBytes = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
        0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
        0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
        0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
        0x42, 0x60, 0x82
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScreenSnippingOverlay(
              onRegionSelected: (_) {},
              onCancel: () {},
              desktopBackgroundBytes: sampleBytes,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('desktop_background_image')), findsOneWidget);
    });
  });
}
