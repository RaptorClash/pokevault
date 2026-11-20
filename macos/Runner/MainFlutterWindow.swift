import Cocoa
import CoreGraphics
import FlutterMacOS
import Vision

class MainFlutterWindow: NSWindow {
  private var visionOcrChannel: FlutterMethodChannel?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    registerVisionOcrChannel(messenger: flutterViewController.engine.binaryMessenger)

    super.awakeFromNib()
  }

  private func registerVisionOcrChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "pokevault/macos_vision_ocr",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "recognizeText",
            let args = call.arguments as? [String: Any],
            let width = args["width"] as? Int,
            let height = args["height"] as? Int,
            let typedBytes = args["bytes"] as? FlutterStandardTypedData else {
        result(FlutterError(code: "INVALID_ARGS", message: "Missing frame arguments", details: nil))
        return
      }

      let languageTag = args["languageTag"] as? String
      let data = typedBytes.data

      DispatchQueue.global(qos: .userInitiated).async {
        let start = CFAbsoluteTimeGetCurrent()
        let outcome = Self.performVisionOcr(
          bgraData: data,
          width: width,
          height: height,
          languageTag: languageTag
        )
        let elapsedMs = Int((CFAbsoluteTimeGetCurrent() - start) * 1000)
        DispatchQueue.main.async {
          var payload: [String: Any] = [
            "lines": outcome.lines,
            "ocrSucceeded": outcome.errorMessage == nil,
            "ocrDurationMs": elapsedMs,
          ]
          if let errorMsg = outcome.errorMessage {
            payload["errorHint"] = errorMsg
          }
          result(payload)
        }
      }
    }
    self.visionOcrChannel = channel
  }

  private static func performVisionOcr(
    bgraData: Data,
    width: Int,
    height: Int,
    languageTag: String?
  ) -> (lines: [String], errorMessage: String?) {
    guard width > 0, height > 0, bgraData.count >= width * height * 4 else {
      return ([], "Invalid frame dimensions or buffer length")
    }
    guard let provider = CGDataProvider(data: bgraData as CFData) else {
      return ([], "Failed to create CGDataProvider")
    }
    let bitmapInfo = CGBitmapInfo(rawValue:
      CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
    )
    guard let cgImage = CGImage(
      width: width,
      height: height,
      bitsPerComponent: 8,
      bitsPerPixel: 32,
      bytesPerRow: width * 4,
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: bitmapInfo,
      provider: provider,
      decode: nil,
      shouldInterpolate: false,
      intent: .defaultIntent
    ) else {
      return ([], "Failed to construct CGImage")
    }

    var recognizedLines: [String] = []
    var requestError: Error?
    let request = VNRecognizeTextRequest { req, err in
      if let err = err {
        requestError = err
        return
      }
      guard let observations = req.results as? [VNRecognizedTextObservation] else { return }
      for observation in observations {
        if let top = observation.topCandidates(1).first {
          let trimmed = top.string.trimmingCharacters(in: .whitespacesAndNewlines)
          if !trimmed.isEmpty {
            recognizedLines.append(trimmed)
          }
        }
      }
    }
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true
    if let tag = languageTag, !tag.isEmpty {
      request.recognitionLanguages = [tag]
    }

    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    do {
      try handler.perform([request])
    } catch {
      return ([], error.localizedDescription)
    }
    if let requestError = requestError {
      return ([], requestError.localizedDescription)
    }
    return (recognizedLines, nil)
  }
}
