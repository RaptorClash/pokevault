import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/screens/mobile_scanner/widgets/camera_region_overlay.dart';
import 'package:pokevault/services/mobile_scanner/camera_scan_region.dart';

void main() {
  group('CameraRegionOverlay Widget Tests (TDD & Adversarial)', () {
    testWidgets('draws new rectangle in customRegions mode, moves, resizes, and deletes it', (tester) async {
      List<NormalizedScanRect> currentRegions = const [];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 300,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return CameraRegionOverlay(
                      scanMode: MobileCameraScanMode.customRegions,
                      regions: currentRegions,
                      activeBrushRole: CameraZoneRole.scan,
                      isEditing: true,
                      onRegionsChanged: (next) {
                        setState(() => currentRegions = next);
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      // 1. Drag across canvas to draw Zone A
      final overlayFinder = find.byKey(const Key('camera_region_canvas'));
      final topLeft = tester.getTopLeft(overlayFinder);
      await tester.timedDragFrom(
        topLeft + const Offset(40, 150),
        const Offset(240, 80),
        const Duration(milliseconds: 120),
      );
      await tester.pump();

      expect(currentRegions.length, 1);
      final created = currentRegions.first;
      expect(created.role, CameraZoneRole.scan);
      expect(created.width, greaterThan(0.4));
      expect(created.height, greaterThan(0.15));

      // 2. Move existing rectangle via its body
      final origLeft = created.left;
      final boxFinder = find.byKey(Key('region_box_${created.id}'));
      await tester.drag(boxFinder, const Offset(40, -30));
      await tester.pump();
      expect(currentRegions.first.left, greaterThan(origLeft));

      // 3. Resize via bottom-right handle
      final prevW = currentRegions.first.width;
      final handleFinder = find.byKey(Key('resize_handle_${created.id}'));
      await tester.drag(handleFinder, const Offset(40, 20));
      await tester.pump();
      expect(currentRegions.first.width, greaterThan(prevW));

      // 4. Tap box to select and delete it
      await tester.tap(boxFinder);
      await tester.pump();
      await tester.tap(find.byKey(Key('btn_delete_region_${created.id}')));
      await tester.pump();
      expect(currentRegions, isEmpty);
    });

    testWidgets('ignores accidental tiny tap-drags and renders autoFull mode indicator', (tester) async {
      List<NormalizedScanRect> currentRegions = const [];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 240,
              child: CameraRegionOverlay(
                scanMode: MobileCameraScanMode.customRegions,
                regions: currentRegions,
                activeBrushRole: CameraZoneRole.focus,
                isEditing: true,
                onRegionsChanged: (next) => currentRegions = next,
              ),
            ),
          ),
        ),
      );

      final topLeft = tester.getTopLeft(find.byKey(const Key('camera_region_canvas')));
      await tester.dragFrom(topLeft + const Offset(50, 50), const Offset(3, 3));
      await tester.pump();
      expect(currentRegions, isEmpty);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 240,
              child: CameraRegionOverlay(
                scanMode: MobileCameraScanMode.autoFull,
                regions: const [],
                activeBrushRole: CameraZoneRole.scan,
                isEditing: false,
                onRegionsChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('auto_full_scan_badge')), findsOneWidget);
    });

    testWidgets('draws separate Zone A (scan) and Zone B (focus) boxes for the same multi-instance slot', (tester) async {
      List<NormalizedScanRect> currentRegions = const [];
      CameraBrushTarget activeBrush = CameraBrushTarget.multiScan(2);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 300,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return CameraRegionOverlay(
                      scanMode: MobileCameraScanMode.customRegions,
                      regions: currentRegions,
                      activeBrushRole: activeBrush.role,
                      activeBrush: activeBrush,
                      isEditing: true,
                      onRegionsChanged: (next) => setState(() => currentRegions = next),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      final overlayFinder = find.byKey(const Key('camera_region_canvas'));
      final topLeft = tester.getTopLeft(overlayFinder);

      // Draw Instanz #2 Zone A (Scan)
      await tester.timedDragFrom(
        topLeft + const Offset(20, 180),
        const Offset(160, 70),
        const Duration(milliseconds: 100),
      );
      await tester.pump();
      expect(currentRegions.length, 1);
      expect(currentRegions.first.id, 'multi_2_scan');
      expect(currentRegions.first.slotId, 2);
      expect(currentRegions.first.encounterOnly, isFalse);

      // Switch brush to Instanz #2 Zone B (Focus) and draw second rectangle
      activeBrush = CameraBrushTarget.multiFocus(2);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 300,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return CameraRegionOverlay(
                      scanMode: MobileCameraScanMode.customRegions,
                      regions: currentRegions,
                      activeBrushRole: activeBrush.role,
                      activeBrush: activeBrush,
                      isEditing: true,
                      onRegionsChanged: (next) => setState(() => currentRegions = next),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.timedDragFrom(
        topLeft + const Offset(20, 20),
        const Offset(160, 70),
        const Duration(milliseconds: 100),
      );
      await tester.pump();

      expect(currentRegions.length, 2);
      expect(currentRegions.any((r) => r.id == 'multi_2_scan' && !r.encounterOnly), isTrue);
      expect(currentRegions.any((r) => r.id == 'multi_2_focus' && r.encounterOnly), isTrue);
    });

    testWidgets('supports tap-to-focus in autoFull mode and on empty canvas in customRegions mode', (tester) async {
      Offset? tappedPoint;

      // 1. AutoFull mode allows tap-to-focus
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 200,
                child: CameraRegionOverlay(
                  scanMode: MobileCameraScanMode.autoFull,
                  regions: const [],
                  activeBrushRole: CameraZoneRole.scan,
                  isEditing: true,
                  onRegionsChanged: (_) {},
                  onTapCameraFocus: (pt) => tappedPoint = pt,
                ),
              ),
            ),
          ),
        ),
      );

      final autoBox = find.byType(CameraRegionOverlay);
      await tester.tapAt(tester.getTopLeft(autoBox) + const Offset(200, 100));
      await tester.pump();
      expect(tappedPoint, isNotNull);
      expect(tappedPoint!.dx, closeTo(0.5, 0.05));
      expect(tappedPoint!.dy, closeTo(0.5, 0.05));
      expect(find.byKey(const Key('camera_focus_indicator')), findsOneWidget);

      // 2. CustomRegions mode allows tap-to-focus on empty canvas even while editing is enabled
      tappedPoint = null;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 200,
                child: CameraRegionOverlay(
                  scanMode: MobileCameraScanMode.customRegions,
                  regions: const [],
                  activeBrushRole: CameraZoneRole.scan,
                  isEditing: true,
                  onRegionsChanged: (_) {},
                  onTapCameraFocus: (pt) => tappedPoint = pt,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tapAt(tester.getTopLeft(find.byKey(const Key('camera_region_canvas'))) + const Offset(100, 50));
      await tester.pump();
      expect(tappedPoint, isNotNull);
      expect(tappedPoint!.dx, closeTo(0.25, 0.05));
      expect(tappedPoint!.dy, closeTo(0.25, 0.05));

      // Advance timer so focus ring timer cleans up cleanly
      await tester.pump(const Duration(seconds: 2));
    });
  });
}
