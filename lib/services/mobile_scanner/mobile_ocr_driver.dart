import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:universal_io/io.dart' as io;
import '../desktop_tracker/desktop_capture_driver.dart';
import '../desktop_tracker/desktop_ocr_driver.dart';
import '../scanner_core/models/scanner_settings.dart';
import 'camera_frame_processor.dart';

/// On-device ML Kit OCR driver for Android & iOS supporting all 9 Pokémon game
/// language scripts (Latin, Japanese, Korean, Chinese) and camera display preprocessing.
class MobileOcrDriver implements LanguageAwareOcrDriver, PreprocessAwareOcrDriver {
  final Future<List<String>> Function(
    CapturedFrame frame,
    TextRecognitionScript script,
  )? customRecognizer;

  String? _languageTag;
  OcrPreprocessProfile _preprocessProfile;
  final Map<TextRecognitionScript, TextRecognizer> _recognizers = {};
  String? lastDiagnosticHint;

  MobileOcrDriver({
    String? initialLanguageTag,
    OcrPreprocessProfile initialPreprocessProfile = OcrPreprocessProfile.cameraDisplay,
    this.customRecognizer,
  })  : _languageTag = initialLanguageTag,
        _preprocessProfile = initialPreprocessProfile;

  @override
  String? get languageTag => _languageTag;

  @override
  void setLanguageTag(String? languageTag) {
    _languageTag = languageTag;
  }

  @override
  OcrPreprocessProfile get preprocessProfile => _preprocessProfile;

  @override
  void setPreprocessProfile(OcrPreprocessProfile profile) {
    _preprocessProfile = profile;
  }

  /// Resolves a PokéVault language code or BCP-47 tag to the matching ML Kit script.
  static TextRecognitionScript scriptForLanguageTag(String? languageTag) {
    final norm = (languageTag ?? '').trim().toLowerCase();
    if (norm.startsWith('ja')) return TextRecognitionScript.japanese;
    if (norm.startsWith('ko')) return TextRecognitionScript.korean;
    if (norm.startsWith('zh')) return TextRecognitionScript.chinese;
    return TextRecognitionScript.latin;
  }

  TextRecognizer _getOrCreateRecognizer(TextRecognitionScript script) {
    return _recognizers.putIfAbsent(
      script,
      () => TextRecognizer(script: script),
    );
  }

  @override
  Future<List<String>> recognizeText(CapturedFrame frame) async {
    lastDiagnosticHint = null;
    if (frame.width <= 0 || frame.height <= 0 || frame.bytes.isEmpty) {
      return const [];
    }

    final script = scriptForLanguageTag(_languageTag);
    final profile = _preprocessProfile;

    if (customRecognizer != null) {
      try {
        final processed = CameraFrameProcessor.applyPreprocessProfile(frame, profile);
        final raw = await customRecognizer!(processed, script);
        return raw.map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
      } catch (e) {
        lastDiagnosticHint = 'ML Kit OCR Fehler (${script.name}): $e';
        return const [];
      }
    }

    final inputImage = await _buildInputImageAsync(frame, profile);
    if (inputImage == null) {
      lastDiagnosticHint ??= 'Ungültige Bilddaten für ML Kit OCR';
      return const [];
    }

    try {
      final recognizer = _getOrCreateRecognizer(script);
      final recognized = await recognizer.processImage(inputImage);
      return recognized.blocks
          .expand((block) => block.lines)
          .map((line) => line.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();
    } catch (e) {
      lastDiagnosticHint = 'ML Kit OCR Fehler (${script.name}): $e';
      return const [];
    }
  }

  Future<InputImage?> _buildInputImageAsync(
    CapturedFrame frame,
    OcrPreprocessProfile profile,
  ) async {
    if (frame.filePath != null && frame.filePath!.isNotEmpty) {
      return InputImage.fromFilePath(frame.filePath!);
    }

    final rawBytes = frame.bytes is Uint8List
        ? frame.bytes as Uint8List
        : Uint8List.fromList(frame.bytes);
    if (rawBytes.isEmpty) return null;

    final isIos = io.Platform.isIOS;
    final pixelCount = frame.width * frame.height;
    final useIsolate = !kIsWeb && pixelCount > 16000;

    if (isIos) {
      final processed = useIsolate
          ? await Isolate.run(
              () => CameraFrameProcessor.applyPreprocessProfile(frame, profile),
            )
          : CameraFrameProcessor.applyPreprocessProfile(frame, profile);
      final iosBytes = processed.bytes is Uint8List
          ? processed.bytes as Uint8List
          : Uint8List.fromList(processed.bytes);
      return InputImage.fromBytes(
        bytes: iosBytes,
        metadata: InputImageMetadata(
          size: Size(processed.width.toDouble(), processed.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.bgra8888,
          bytesPerRow: processed.width * 4,
        ),
      );
    }

    final nv21Payload = useIsolate
        ? await Isolate.run(() {
            final processed =
                CameraFrameProcessor.applyPreprocessProfile(frame, profile);
            return CameraFrameProcessor.bgraToEvenAlignedNv21(processed);
          })
        : CameraFrameProcessor.bgraToEvenAlignedNv21(
            CameraFrameProcessor.applyPreprocessProfile(frame, profile),
          );

    if (nv21Payload.bytes.isEmpty ||
        nv21Payload.width <= 0 ||
        nv21Payload.height <= 0) {
      return null;
    }

    return InputImage.fromBytes(
      bytes: nv21Payload.bytes,
      metadata: InputImageMetadata(
        size: Size(nv21Payload.width.toDouble(), nv21Payload.height.toDouble()),
        rotation: InputImageRotation.rotation0deg,
        format: InputImageFormat.nv21,
        bytesPerRow: nv21Payload.width,
      ),
    );
  }

  Future<void> dispose() async {
    for (final recognizer in _recognizers.values) {
      await recognizer.close();
    }
    _recognizers.clear();
  }
}
