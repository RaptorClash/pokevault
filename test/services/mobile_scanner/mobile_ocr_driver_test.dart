import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:pokevault/services/desktop_tracker/desktop_capture_driver.dart';
import 'package:pokevault/services/mobile_scanner/camera_frame_processor.dart';
import 'package:pokevault/services/mobile_scanner/mobile_ocr_driver.dart';
import 'package:pokevault/services/scanner_core/models/scanner_settings.dart';

void main() {
  group('MobileOcrDriver Tests (TDD)', () {
    test('maps PokéVault language tags to matching ML Kit TextRecognitionScript', () {
      expect(MobileOcrDriver.scriptForLanguageTag('de-DE'), TextRecognitionScript.latin);
      expect(MobileOcrDriver.scriptForLanguageTag('en'), TextRecognitionScript.latin);
      expect(MobileOcrDriver.scriptForLanguageTag('fr-FR'), TextRecognitionScript.latin);
      expect(MobileOcrDriver.scriptForLanguageTag('ja-JP'), TextRecognitionScript.japanese);
      expect(MobileOcrDriver.scriptForLanguageTag('ja'), TextRecognitionScript.japanese);
      expect(MobileOcrDriver.scriptForLanguageTag('ko-KR'), TextRecognitionScript.korean);
      expect(MobileOcrDriver.scriptForLanguageTag('ko'), TextRecognitionScript.korean);
      expect(MobileOcrDriver.scriptForLanguageTag('zh-Hans'), TextRecognitionScript.chinese);
      expect(MobileOcrDriver.scriptForLanguageTag('zh-Hant'), TextRecognitionScript.chinese);
      expect(MobileOcrDriver.scriptForLanguageTag(null), TextRecognitionScript.latin);
    });

    test('delegates recognition with active script, language tag, and preprocess profile', () async {
      TextRecognitionScript? usedScript;
      CapturedFrame? receivedFrame;

      final driver = MobileOcrDriver(
        initialLanguageTag: 'ja-JP',
        initialPreprocessProfile: OcrPreprocessProfile.cameraDisplay,
        customRecognizer: (frame, script) async {
          usedScript = script;
          receivedFrame = frame;
          return ['  ヒトカゲを つかまえた!  ', '', '   '];
        },
      );

      final frame = CapturedFrame(
        width: 4,
        height: 4,
        bytes: Uint8List(4 * 4 * 4),
        pixelFormat: 'bgra8888',
      );

      final lines = await driver.recognizeText(frame);
      expect(usedScript, TextRecognitionScript.japanese);
      expect(receivedFrame, isNotNull);
      expect(lines, ['ヒトカゲを つかまえた!']);

      // Switching language dynamically updates script
      driver.setLanguageTag('ko-KR');
      await driver.recognizeText(frame);
      expect(usedScript, TextRecognitionScript.korean);

      // Switching preprocess profile works cleanly
      driver.setPreprocessProfile(OcrPreprocessProfile.pixelArtDs);
      expect(driver.preprocessProfile, OcrPreprocessProfile.pixelArtDs);
    });

    test('returns empty list for invalid/empty frames without calling recognizer', () async {
      bool called = false;
      final driver = MobileOcrDriver(
        customRecognizer: (frame, script) async {
          called = true;
          return ['should not run'];
        },
      );

      const empty = CapturedFrame(width: 0, height: 0, bytes: []);
      expect(await driver.recognizeText(empty), isEmpty);
      expect(called, isFalse);
    });

    test('converts BGRA8888 to valid NV21 byte layout for Android ML Kit', () {
      // 4x4 frame -> Y plane = 16 bytes, UV interleaved = (4*4)/2 = 8 bytes -> total 24 bytes
      final bgra = Uint8List(4 * 4 * 4);
      for (int i = 0; i < 16; i++) {
        bgra[i * 4] = 100;
        bgra[i * 4 + 1] = 150;
        bgra[i * 4 + 2] = 200;
        bgra[i * 4 + 3] = 255;
      }
      final frame = CapturedFrame(
        width: 4,
        height: 4,
        bytes: bgra,
        pixelFormat: 'bgra8888',
      );
      final nv21 = CameraFrameProcessor.bgraToNv21(frame);
      expect(nv21.length, 24);
    });
  });
}
