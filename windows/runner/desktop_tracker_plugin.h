#ifndef RUNNER_DESKTOP_TRACKER_PLUGIN_H_
#define RUNNER_DESKTOP_TRACKER_PLUGIN_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>

#include <array>
#include <atomic>
#include <chrono>
#include <condition_variable>
#include <cstdint>
#include <map>
#include <memory>
#include <mutex>
#include <queue>
#include <string>
#include <thread>
#include <unordered_map>
#include <vector>

/// Native Windows Win32/WinRT plugin handling:
/// - Visible window & monitor enumeration (EnumWindows + EnumDisplayMonitors)
/// - Full-virtual-desktop free-drag snipping overlay (without hiding main window)
/// - Always-on-top non-activating layered desktop HUD
/// - Screen/window pixel capture & Windows.Media.Ocr text recognition
class DesktopTrackerPlugin {
 public:
  explicit DesktopTrackerPlugin(HWND main_window_hwnd,
                                flutter::BinaryMessenger* messenger);
  ~DesktopTrackerPlugin();

  DesktopTrackerPlugin(const DesktopTrackerPlugin&) = delete;
  DesktopTrackerPlugin& operator=(const DesktopTrackerPlugin&) = delete;

 private:
  struct HudFocusEntry {
    int pokemon_id = 0;
    std::wstring pokemon_name;
    bool is_shiny = false;
    bool is_caught = false;
    int encounter_count = 1;
  };

  struct HudButtonRects {
    RECT compact_btn{};
    RECT pin_btn{};
    RECT close_btn{};
    RECT catch_btn{};
    bool has_catch_btn = false;
    std::vector<std::pair<RECT, int>> multi_catch_btns;
  };

  struct HudStateData {
    std::wstring pokemon_name = L"Warte auf Spiel...";
    int pokemon_id = 0;
    bool is_shiny = false;
    bool is_caught = false;
    bool is_compact = false;
    bool is_pinned = true;
    double opacity = 0.92;
    bool has_event = false;
    bool has_anchor_rect = false;
    RECT anchor_rect{};
    bool has_explicit_pos = false;
    int pos_x = 40;
    int pos_y = 40;
    std::wstring evolution_summary;
    bool has_missing_evolutions = false;
    std::wstring instance_label;
    std::wstring waiting_label = L"Warte auf Spiel-Ereignis...";
    std::wstring caught_label = L"\u2714 Gefangen";
    std::wstring missing_label = L"\u26A0 Fehlt im Ziel-Dex";
    std::wstring footer_label;
    std::vector<HudFocusEntry> focus_entries;
  };

  struct OverlayBorderEntry {
    HWND hwnd = nullptr;
    COLORREF color = RGB(34, 197, 94);
    std::wstring label;
  };

  struct OcrAsyncPayload {
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result;
    std::vector<std::string> lines;
    bool used_fallback_language = false;
    std::string resolved_language_tag;
    std::string requested_language_tag;
    std::vector<std::string> available_languages;
    std::string error_hint;
    int64_t ocr_duration_ms = 0;
    bool success = false;
  };

  struct OcrWorkItem {
    std::vector<uint8_t> bytes;
    int width = 0;
    int height = 0;
    std::string language_tag;
    std::string preprocess_profile;
    OcrAsyncPayload* payload = nullptr;
  };

  struct CaptureAsyncPayload {
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result;
    bool success = false;
    int width = 0;
    int height = 0;
    std::string capture_method;
    std::vector<uint8_t> bytes;
  };

  struct CaptureAnalyzePayload {
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result;
    bool captured = false;
    bool ocr_skipped = true;
    std::vector<std::string> lines;
    bool used_fallback_language = false;
    std::string resolved_language_tag;
    std::string requested_language_tag;
    std::vector<std::string> available_languages;
    bool ocr_succeeded = true;
    std::string error_hint;
    int64_t capture_duration_ms = 0;
    int64_t ocr_duration_ms = 0;
    int frame_width = 0;
    int frame_height = 0;
    std::string capture_method = "unknown";
    std::string brightness_summary;
    bool has_luma = false;
    double avg_luma = 0.0;
    double std_dev = 0.0;
    bool has_color_histogram = false;
    std::array<double, 16> color_histogram{};
    bool self_window_overlaps = false;
    std::vector<uint8_t> thumbnail_png;
    int thumbnail_width = 0;
    int thumbnail_height = 0;
  };

  struct WorkerTask {
    enum class Type {
      kOcr,
      kCaptureRegion,
      kCaptureWindow,
      kCaptureAnalyze,
      kClearScanCache,
    };

    Type type = Type::kOcr;
    // Ocr task fields
    std::vector<uint8_t> bytes;
    int width = 0;
    int height = 0;
    std::string language_tag;
    std::string preprocess_profile;
    OcrAsyncPayload* ocr_payload = nullptr;

    // Capture / CaptureAnalyze fields
    bool is_region = false;
    int cap_x = 0;
    int cap_y = 0;
    int cap_w = 0;
    int cap_h = 0;
    int64_t hwnd_val = 0;
    bool has_crop = false;
    int crop_x = 0;
    int crop_y = 0;
    int crop_w = 0;
    int crop_h = 0;
    std::string slot_key;
    bool force_ocr = false;
    bool mask_self_window = false;
    bool compute_color_histogram = false;
    bool include_thumbnail = false;
    int thumbnail_max_width = 320;
    bool multi_band_fallback = false;
    CaptureAsyncPayload* capture_payload = nullptr;
    CaptureAnalyzePayload* analyze_payload = nullptr;
  };

  struct WindowCaptureCache {
    HWND hwnd = nullptr;
    int width = 0;
    int height = 0;
    std::string capture_method;
    std::chrono::steady_clock::time_point captured_at{};
    std::vector<uint8_t> bgra_bytes;
  };

  void OcrWorkerLoop();

  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Method handlers
  flutter::EncodableValue EnumerateWindowsAndMonitors();
  void StartDesktopSnipping(
      const flutter::EncodableMap* args,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void CaptureRegionAsync(
      const flutter::EncodableMap& args,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void CaptureWindowAsync(
      const flutter::EncodableMap& args,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void CaptureAndAnalyzeAsync(
      const flutter::EncodableMap& args,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  void ClearScanCacheAsync();
  void RecognizeTextAsync(
      const flutter::EncodableMap& args,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  bool ShowOrUpdateFloatingHud(const flutter::EncodableMap& args,
                               bool create_if_missing);
  void HideFloatingHud();
  void ShowScanRegionBorder(const flutter::EncodableMap& args);
  void HideScanRegionBorder();
  void SetOverlayBorders(const flutter::EncodableMap& args);
  void ClearOverlayBorders();

  // Snipping overlay helpers
  bool EnsureOverlayWindowClasses();
  void CleanupSnippingOverlay();
  void FinishSnipping(bool confirm);
  void PaintSnippingOverlay(HWND hwnd);
  RECT GetNormalizedSelection() const;
  bool EncodeHbitmapRectToPng(HBITMAP source_bmp,
                              int src_x,
                              int src_y,
                              int width,
                              int height,
                              std::vector<uint8_t>* out_png);

  // Floating HUD helpers
  void ParseHudArgs(const flutter::EncodableMap& args);
  int ComputeHudHeight() const;
  void PositionHudFromAnchor();
  void RenderFloatingHud();
  void InvokeDartHudEvent(const std::string& method,
                          const flutter::EncodableValue& args =
                              flutter::EncodableValue());

  // Message pump window & window procs
  static LRESULT CALLBACK DispatcherWndProc(HWND hwnd,
                                            UINT msg,
                                            WPARAM wparam,
                                            LPARAM lparam);
  static LRESULT CALLBACK SnippingWndProc(HWND hwnd,
                                          UINT msg,
                                          WPARAM wparam,
                                          LPARAM lparam);
  static LRESULT CALLBACK HudWndProc(HWND hwnd,
                                     UINT msg,
                                     WPARAM wparam,
                                     LPARAM lparam);
  static LRESULT CALLBACK ScanBorderWndProc(HWND hwnd,
                                            UINT msg,
                                            WPARAM wparam,
                                            LPARAM lparam);

  HWND main_window_hwnd_ = nullptr;
  HWND dispatcher_hwnd_ = nullptr;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  ULONG_PTR gdiplus_token_ = 0;

  // Snipping state
  HWND snip_hwnd_ = nullptr;
  HBITMAP snip_bright_bmp_ = nullptr;
  HBITMAP snip_dimmed_bmp_ = nullptr;
  int virtual_x_ = 0;
  int virtual_y_ = 0;
  int virtual_w_ = 0;
  int virtual_h_ = 0;
  bool snip_is_dragging_ = false;
  bool snip_has_selection_ = false;
  POINT snip_start_{};
  POINT snip_end_{};
  RECT snip_confirm_btn_{};
  RECT snip_cancel_btn_{};
  std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
      pending_snip_result_;
  std::wstring snip_hint_label_ =
      L"Live-OCR-Bereich aufziehen: Bereich wird laufend gescannt  \u00B7  ESC = Abbrechen";
  std::wstring snip_confirm_label_ = L"\u2713 Live-OCR starten (Enter)";
  std::wstring snip_cancel_label_ = L"Abbrechen";
  std::shared_ptr<std::atomic<bool>> alive_flag_ =
      std::make_shared<std::atomic<bool>>(true);

  // Dedicated OCR + Capture background worker thread
  std::mutex ocr_queue_mutex_;
  std::condition_variable ocr_queue_cv_;
  std::queue<WorkerTask> ocr_queue_;
  bool ocr_worker_stopping_ = false;
  HANDLE ocr_stop_event_ = nullptr;
  std::thread ocr_worker_thread_;
  WindowCaptureCache window_capture_cache_{};
  std::unordered_map<std::string, int64_t> slot_fingerprints_;

  // HUD state
  HWND hud_hwnd_ = nullptr;
  HWND scan_border_hwnd_ = nullptr;
  HFONT scan_border_font_ = nullptr;
  bool scan_border_active_ = true;
  std::map<std::string, OverlayBorderEntry> overlay_borders_;
  HudStateData hud_state_{};
  HudButtonRects hud_buttons_{};
  bool hud_is_dragging_ = false;
  POINT hud_drag_offset_{};
  bool hud_user_moved_ = false;

  static constexpr UINT kMsgOcrComplete = WM_APP + 101;
  static constexpr UINT kMsgCaptureComplete = WM_APP + 102;
  static constexpr UINT kMsgCaptureAnalyzeComplete = WM_APP + 103;
};

#endif  // RUNNER_DESKTOP_TRACKER_PLUGIN_H_
