import '../scanner_core/models/scanner_settings.dart';
import 'desktop_capture_driver.dart';

/// Abstract contract for performing text recognition on desktop image frames.
abstract class DesktopOcrDriver {
  Future<List<String>> recognizeText(CapturedFrame frame);
}

/// Optional interface for OCR drivers that accept a dynamic BCP-47 language tag.
abstract class LanguageAwareOcrDriver implements DesktopOcrDriver {
  void setLanguageTag(String? languageTag);
  String? get languageTag;
}

/// Optional interface for OCR drivers that accept a native preprocessing profile.
abstract class PreprocessAwareOcrDriver implements DesktopOcrDriver {
  void setPreprocessProfile(OcrPreprocessProfile profile);
  OcrPreprocessProfile get preprocessProfile;
}

/// Default desktop OCR driver delegating to Windows Media OCR (WinRT) or custom handler.
class DefaultDesktopOcrDriver implements LanguageAwareOcrDriver {
  final Future<List<String>> Function(CapturedFrame frame)? nativeOcrHandler;
  final Future<List<String>> Function(CapturedFrame frame, String? languageTag)?
      localizedOcrHandler;
  String? _languageTag;

  DefaultDesktopOcrDriver({
    this.nativeOcrHandler,
    this.localizedOcrHandler,
    String? initialLanguageTag,
  }) : _languageTag = initialLanguageTag;

  @override
  String? get languageTag => _languageTag;

  @override
  void setLanguageTag(String? languageTag) {
    _languageTag = languageTag;
  }

  @override
  Future<List<String>> recognizeText(CapturedFrame frame) async {
    if (frame.width <= 0 || frame.height <= 0) return const [];

    List<String>? rawLines;
    if (localizedOcrHandler != null) {
      rawLines = await localizedOcrHandler!(frame, _languageTag);
    } else if (nativeOcrHandler != null) {
      rawLines = await nativeOcrHandler!(frame);
    }

    if (rawLines == null) return const [];
    return rawLines
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }
}
