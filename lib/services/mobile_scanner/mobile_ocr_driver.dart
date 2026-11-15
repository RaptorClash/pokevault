import 'dart:typed_data';
import 'dart:ui';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:universal_io/io.dart' as io;
import '../desktop_tracker/desktop_capture_driver.dart';
import '../desktop_tracker/desktop_ocr_driver.dart';
import '../scanner_core/models/scanner_settings.dart';
import 'camera_frame_processor.dart';

/// On-device ML Kit OCR driver for Android & iOS supporting all PokéVault script families
/// (Latin, Japanese, Korean, Chinese) and camera display preprocessing.
class MobileOcrDriver implements LanguageAwareOcrDriver, PreprocessAwareOcrDriver {
  final Future<List<String>> Function(
    CapturedFrame frame,
    TextRecognitionScript script,
  )? customRecognizer;

  String? _languageTag;
  OcrPreprocessProfile _preprocessProfile;
  final Map<TextRecognitionScript, TextRecognizer> _recognizers = {};

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
    if (frame.width <= 0 || frame.height <= 0 || frame.bytes.isEmpty) {
      return const [];
    }

    final processed = CameraFrameProcessor.applyPreprocessProfile(
      frame,
      _preprocessProfile,
    );
    final script = scriptForLanguageTag(_languageTag);

    if (customRecognizer != null) {
      final raw = await customRecognizer!(processed, script);
      return raw.map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    }

    final inputImage = _buildInputImage(processed);
    if (inputImage == null) return const [];

    try {
      final recognizer = _getOrCreateRecognizer(script);
      final recognized = await recognizer.processImage(inputImage);
      return recognized.blocks
          .expand((block) => block.lines)
          .map((line) => line.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  InputImage? _buildInputImage(CapturedFrame frame) {
    if (frame.filePath != null && frame.filePath!.isNotEmpty) {
      return InputImage.fromFilePath(frame.filePath!);
    }

    final rawBytes = frame.bytes is Uint8List
        ? frame.bytes as Uint8List
        : Uint8List.fromList(frame.bytes);
    if (rawBytes.isEmpty) return null;

    final isIos = io.Platform.isIOS;
    final Uint8List bytes;
    final InputImageFormat format;
    final int bytesPerRow;

    if (isIos) {
      bytes = rawBytes;
      format = InputImageFormat.bgra8888;
      bytesPerRow = frame.width * 4;
    } else {
      bytes = CameraFrameProcessor.bgraToNv21(frame);
      if (bytes.isEmpty) return null;
      format = InputImageFormat.nv21;
      bytesPerRow = frame.width;
    }

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(frame.width.toDouble(), frame.height.toDouble()),
        rotation: InputImageRotation.rotation0deg,
        format: format,
        bytesPerRow: bytesPerRow,
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
