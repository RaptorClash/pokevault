import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokevault/services/desktop_tracker/screen_region.dart';

void main() {
  group('ScreenRegion Tests (TDD)', () {
    test('Creates valid absolute ScreenRegion from Rect', () {
      const rect = Rect.fromLTWH(100.0, 150.0, 400.0, 200.0);
      final region = ScreenRegion.fromRect(rect, isAbsoluteScreen: true);

      expect(region.x, 100.0);
      expect(region.y, 150.0);
      expect(region.width, 400.0);
      expect(region.height, 200.0);
      expect(region.isAbsoluteScreen, isTrue);
      expect(region.toRect(), rect);
    });

    test('Clamps negative dimensions and ensures minimum width/height', () {
      final region = ScreenRegion(
        x: -50,
        y: -20,
        width: 5,
        height: -10,
        isAbsoluteScreen: true,
      );

      expect(region.width, greaterThanOrEqualTo(10.0));
      expect(region.height, greaterThanOrEqualTo(10.0));
    });

    test('Serialization to/from Map and description string', () {
      final region = ScreenRegion(
        x: 50,
        y: 80,
        width: 320,
        height: 120,
        label: 'Snipping Bereich',
        isAbsoluteScreen: true,
      );

      expect(region.description, contains('320x120'));
      expect(region.label, 'Snipping Bereich');

      final map = region.toMap();
      final fromMap = ScreenRegion.fromMap(map);
      expect(fromMap.x, 50);
      expect(fromMap.y, 80);
      expect(fromMap.width, 320);
      expect(fromMap.height, 120);
      expect(fromMap.isAbsoluteScreen, isTrue);
    });
  });
}
