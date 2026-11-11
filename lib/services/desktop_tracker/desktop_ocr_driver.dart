import 'desktop_capture_driver.dart';

/// Abstract contract for performing text recognition on desktop image frames.
abstract class DesktopOcrDriver {
  Future<List<String>> recognizeText(CapturedFrame frame);
}

/// Default desktop OCR driver delegating to Windows Media OCR (WinRT) or Tesseract on Linux.
class DefaultDesktopOcrDriver implements DesktopOcrDriver {
  final Future<List<String>> Function(CapturedFrame frame)? nativeOcrHandler;

  const DefaultDesktopOcrDriver({this.nativeOcrHandler});

  @override
  Future<List<String>> recognizeText(CapturedFrame frame) async {
    if (nativeOcrHandler != null) {
      return await nativeOcrHandler!(frame);
    }
    return const [];
  }
}
