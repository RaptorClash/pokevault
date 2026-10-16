import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'r1_grayscale_test.dart' as r1;
import 'r2_drag_drop_test.dart' as r2;
import 'r3_overflow_linking_test.dart' as r3;
import 'r4_shift_back_cleanup_test.dart' as r4;
import 'r5_settings_ui_test.dart' as r5;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Pokevault Box Management E2E Test Suite', () {
    group('Feature 1 (R1): Grayscale Bug Fix', r1.main);
    group('Feature 2 (R2): Smart Drag & Drop Insertion', r2.main);
    group('Feature 3 (R3): Intelligent Box Linking & Overflow', r3.main);
    group('Feature 4 (R4): Auto-Shift Back & Empty Box Cleanup', r4.main);
    group('Feature 5 (R5): Configurable Box Settings UI', r5.main);
  });
}
