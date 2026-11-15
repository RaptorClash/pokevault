import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/services/mobile_scanner/camera_scan_region.dart';

void main() {
  group('CameraScanRegion & NormalizedScanRect Tests (TDD)', () {
    test('clamps coordinates to [0..1] and enforces minimum size', () {
      final rect = NormalizedScanRect(
        id: 'zone_a',
        role: CameraZoneRole.scan,
        left: -0.2,
        top: 0.98,
        width: 0.001,
        height: 0.5,
        colorHex: 0xFF10B981,
        label: 'Zone A',
      );

      expect(rect.left, 0.0);
      expect(rect.width, greaterThanOrEqualTo(NormalizedScanRect.minSize));
      expect(rect.top + rect.height, lessThanOrEqualTo(1.0001));
      expect(rect.height, greaterThanOrEqualTo(NormalizedScanRect.minSize));
    });

    test('converts accurately between normalized and pixel rects', () {
      const pixelRect = Rect.fromLTWH(200, 300, 400, 150);
      final normalized = NormalizedScanRect.fromPixelRect(
        id: 'zone_b',
        role: CameraZoneRole.focus,
        pixelRect: pixelRect,
        frameWidth: 1000,
        frameHeight: 1000,
        colorHex: 0xFF06B6D4,
        label: 'Zone B',
      );

      expect(normalized.left, closeTo(0.2, 0.001));
      expect(normalized.top, closeTo(0.3, 0.001));
      expect(normalized.width, closeTo(0.4, 0.001));
      expect(normalized.height, closeTo(0.15, 0.001));

      final restored = normalized.toPixelRect(1000, 1000);
      expect(restored.left, closeTo(200, 1.0));
      expect(restored.top, closeTo(300, 1.0));
      expect(restored.width, closeTo(400, 1.0));
      expect(restored.height, closeTo(150, 1.0));
    });

    test('roundtrips through toMap and fromMap cleanly', () {
      final original = NormalizedScanRect(
        id: 'multi_2',
        role: CameraZoneRole.multiInstance,
        slotId: 2,
        left: 0.1,
        top: 0.25,
        width: 0.35,
        height: 0.2,
        colorHex: 0xFFEC4899,
        label: 'Instanz #2',
        encounterOnly: true,
      );

      final map = original.toMap();
      final decoded = NormalizedScanRect.fromMap(map);

      expect(decoded, equals(original));
      expect(decoded.slotId, 2);
      expect(decoded.encounterOnly, isTrue);
      expect(decoded.role, CameraZoneRole.multiInstance);
    });

    test('enums MobileCameraScanMode & MobileScannerViewMode expose expected values', () {
      expect(MobileCameraScanMode.values, containsAll([
        MobileCameraScanMode.autoFull,
        MobileCameraScanMode.customRegions,
      ]));
      expect(MobileScannerViewMode.values, containsAll([
        MobileScannerViewMode.fullscreen,
        MobileScannerViewMode.split,
        MobileScannerViewMode.pip,
      ]));
    });

    test('CameraBrushTarget & MobileMultiInstanceHelper manage paired Zone A and Zone B per slot', () {
      final scanTarget = CameraBrushTarget.multiScan(2);
      final focusTarget = CameraBrushTarget.multiFocus(2);

      expect(scanTarget.role, CameraZoneRole.multiInstance);
      expect(scanTarget.slotId, 2);
      expect(scanTarget.encounterOnly, isFalse);
      expect(scanTarget.regionId, 'multi_2_scan');

      expect(focusTarget.role, CameraZoneRole.multiInstance);
      expect(focusTarget.slotId, 2);
      expect(focusTarget.encounterOnly, isTrue);
      expect(focusTarget.regionId, 'multi_2_focus');
      expect(focusTarget.colorHex, equals(scanTarget.colorHex));

      final regions = <NormalizedScanRect>[
        NormalizedScanRect(
          id: 'zone_a',
          role: CameraZoneRole.scan,
          left: 0.0,
          top: 0.7,
          width: 0.5,
          height: 0.25,
          colorHex: 0xFF10B981,
          label: 'Zone A · Scan',
        ),
        NormalizedScanRect(
          id: 'multi_2_scan',
          role: CameraZoneRole.multiInstance,
          slotId: 2,
          left: 0.5,
          top: 0.7,
          width: 0.45,
          height: 0.25,
          colorHex: scanTarget.colorHex,
          label: '#2 Zone A · Scan',
          encounterOnly: false,
        ),
        NormalizedScanRect(
          id: 'multi_2_focus',
          role: CameraZoneRole.multiInstance,
          slotId: 2,
          left: 0.5,
          top: 0.1,
          width: 0.45,
          height: 0.25,
          colorHex: focusTarget.colorHex,
          label: '#2 Zone B · Fokus',
          encounterOnly: true,
        ),
      ];

      expect(regions.multiSlotIds, [2]);
      expect(regions.scanRectForSlot(2)?.id, 'multi_2_scan');
      expect(regions.focusRectForSlot(2)?.id, 'multi_2_focus');
      expect(regions.nextMultiSlotId(), 3);
    });
  });
}
