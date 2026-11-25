#include "desktop_tracker_plugin.h"

#include <dwmapi.h>
#include <roapi.h>
#include <robuffer.h>
#include <windows.foundation.collections.h>
#include <windows.foundation.h>
#include <windows.globalization.h>
#include <windows.graphics.imaging.h>
#include <windows.media.ocr.h>
#include <windows.storage.streams.h>
#include <winstring.h>
#include <wrl/client.h>
#include <wrl/event.h>
#include <wrl/implements.h>
#include <wrl/wrappers/corewrappers.h>

#include <algorithm>
#include <array>
#include <cctype>
#include <chrono>
#include <cmath>
#include <cstring>
#include <thread>
#include <unordered_map>
#include <unordered_set>

// gdiplus.h expects min/max in global scope when NOMINMAX is defined.
using std::max;
using std::min;
#include <gdiplus.h>

namespace {

constexpr wchar_t kDispatcherClassName[] = L"POKEVAULT_TRACKER_DISPATCHER";
constexpr wchar_t kSnipOverlayClassName[] = L"POKEVAULT_SNIPPING_OVERLAY";
constexpr wchar_t kHudWindowClassName[] = L"POKEVAULT_FLOATING_HUD";
constexpr wchar_t kScanBorderClassName[] = L"POKEVAULT_SCAN_BORDER";

constexpr int kHudWidthNormal = 320;
constexpr int kHudHeightNormal = 128;
constexpr int kHudWidthCompact = 270;
constexpr int kHudHeightCompact = 86;

/// Queries virtual-screen bounds under an explicit Per-Monitor-V2 DPI context
/// so mixed-DPI multi-monitor setups always yield consistent physical pixels.
void QueryVirtualScreenBounds(int* out_x, int* out_y, int* out_w, int* out_h) {
  const DPI_AWARENESS_CONTEXT prev_dpi_ctx =
      SetThreadDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
  if (out_x) *out_x = GetSystemMetrics(SM_XVIRTUALSCREEN);
  if (out_y) *out_y = GetSystemMetrics(SM_YVIRTUALSCREEN);
  if (out_w) *out_w = GetSystemMetrics(SM_CXVIRTUALSCREEN);
  if (out_h) *out_h = GetSystemMetrics(SM_CYVIRTUALSCREEN);
  if (prev_dpi_ctx) {
    SetThreadDpiAwarenessContext(prev_dpi_ctx);
  }
}

std::string WideToUtf8(const std::wstring& wide) {
  if (wide.empty()) return {};
  int size_needed = WideCharToMultiByte(
      CP_UTF8, 0, wide.data(), static_cast<int>(wide.size()), nullptr, 0,
      nullptr, nullptr);
  if (size_needed <= 0) return {};
  std::string result(static_cast<size_t>(size_needed), '\0');
  WideCharToMultiByte(CP_UTF8, 0, wide.data(), static_cast<int>(wide.size()),
                      result.data(), size_needed, nullptr, nullptr);
  return result;
}

std::wstring Utf8ToWide(const std::string& utf8) {
  if (utf8.empty()) return {};
  int size_needed = MultiByteToWideChar(
      CP_UTF8, 0, utf8.data(), static_cast<int>(utf8.size()), nullptr, 0);
  if (size_needed <= 0) return {};
  std::wstring result(static_cast<size_t>(size_needed), L'\0');
  MultiByteToWideChar(CP_UTF8, 0, utf8.data(), static_cast<int>(utf8.size()),
                      result.data(), size_needed);
  return result;
}

double GetDoubleArg(const flutter::EncodableMap& args,
                    const char* key,
                    double fallback) {
  auto it = args.find(flutter::EncodableValue(key));
  if (it == args.end()) return fallback;
  if (std::holds_alternative<double>(it->second)) {
    return std::get<double>(it->second);
  }
  if (std::holds_alternative<int32_t>(it->second)) {
    return static_cast<double>(std::get<int32_t>(it->second));
  }
  if (std::holds_alternative<int64_t>(it->second)) {
    return static_cast<double>(std::get<int64_t>(it->second));
  }
  return fallback;
}

int64_t GetInt64Arg(const flutter::EncodableMap& args,
                    const char* key,
                    int64_t fallback) {
  auto it = args.find(flutter::EncodableValue(key));
  if (it == args.end()) return fallback;
  if (std::holds_alternative<int64_t>(it->second)) {
    return std::get<int64_t>(it->second);
  }
  if (std::holds_alternative<int32_t>(it->second)) {
    return static_cast<int64_t>(std::get<int32_t>(it->second));
  }
  if (std::holds_alternative<double>(it->second)) {
    return static_cast<int64_t>(std::get<double>(it->second));
  }
  return fallback;
}

bool GetBoolArg(const flutter::EncodableMap& args,
                const char* key,
                bool fallback) {
  auto it = args.find(flutter::EncodableValue(key));
  if (it == args.end()) return fallback;
  if (std::holds_alternative<bool>(it->second)) {
    return std::get<bool>(it->second);
  }
  return fallback;
}

std::string GetStringArg(const flutter::EncodableMap& args,
                         const char* key,
                         const std::string& fallback = "") {
  auto it = args.find(flutter::EncodableValue(key));
  if (it == args.end()) return fallback;
  if (std::holds_alternative<std::string>(it->second)) {
    return std::get<std::string>(it->second);
  }
  return fallback;
}

struct EnumMonitorsContext {
  flutter::EncodableList* monitors = nullptr;
  int index = 0;
};

BOOL CALLBACK EnumMonitorsProc(HMONITOR hMonitor,
                               HDC /*hdcMonitor*/,
                               LPRECT /*lprcMonitor*/,
                               LPARAM dwData) {
  auto* ctx = reinterpret_cast<EnumMonitorsContext*>(dwData);
  if (!ctx || !ctx->monitors) return FALSE;

  MONITORINFOEXW mi{};
  mi.cbSize = sizeof(mi);
  if (!GetMonitorInfoW(hMonitor, &mi)) {
    return TRUE;
  }

  ctx->index += 1;
  const int width = mi.rcMonitor.right - mi.rcMonitor.left;
  const int height = mi.rcMonitor.bottom - mi.rcMonitor.top;
  const bool is_primary = (mi.dwFlags & MONITORINFOF_PRIMARY) != 0;

  wchar_t label[128]{};
  if (is_primary) {
    swprintf_s(label, L"\U0001F5A5\uFE0F Monitor %d (Prim\u00E4r) \u2014 %d\u00D7%d",
               ctx->index, width, height);
  } else {
    swprintf_s(label, L"\U0001F5A5\uFE0F Monitor %d \u2014 %d\u00D7%d",
               ctx->index, width, height);
  }

  flutter::EncodableMap entry;
  entry[flutter::EncodableValue("index")] =
      flutter::EncodableValue(ctx->index);
  entry[flutter::EncodableValue("title")] =
      flutter::EncodableValue(WideToUtf8(label));
  entry[flutter::EncodableValue("x")] =
      flutter::EncodableValue(static_cast<double>(mi.rcMonitor.left));
  entry[flutter::EncodableValue("y")] =
      flutter::EncodableValue(static_cast<double>(mi.rcMonitor.top));
  entry[flutter::EncodableValue("width")] =
      flutter::EncodableValue(static_cast<double>(width));
  entry[flutter::EncodableValue("height")] =
      flutter::EncodableValue(static_cast<double>(height));
  entry[flutter::EncodableValue("isPrimary")] =
      flutter::EncodableValue(is_primary);
  entry[flutter::EncodableValue("isVirtualDesktop")] =
      flutter::EncodableValue(false);

  ctx->monitors->push_back(flutter::EncodableValue(entry));
  return TRUE;
}

struct EnumWindowsContext {
  flutter::EncodableList* windows = nullptr;
  DWORD self_pid = 0;
  HWND snip_hwnd = nullptr;
  HWND hud_hwnd = nullptr;
  HWND scan_border_hwnd = nullptr;
};

std::wstring GetProcessBaseName(DWORD pid) {
  HANDLE proc = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pid);
  if (!proc) return {};
  wchar_t path_buf[MAX_PATH * 2]{};
  DWORD size = static_cast<DWORD>(std::size(path_buf));
  std::wstring name;
  if (QueryFullProcessImageNameW(proc, 0, path_buf, &size) && size > 0) {
    std::wstring full(path_buf, size);
    size_t slash = full.find_last_of(L"\\/");
    name = (slash != std::wstring::npos) ? full.substr(slash + 1) : full;
  }
  CloseHandle(proc);
  return name;
}

bool GetAccurateWindowRect(HWND hwnd, RECT* out_rect) {
  if (!out_rect) return false;
  if (SUCCEEDED(DwmGetWindowAttribute(hwnd, DWMWA_EXTENDED_FRAME_BOUNDS,
                                      out_rect, sizeof(RECT)))) {
    if (out_rect->right > out_rect->left && out_rect->bottom > out_rect->top) {
      return true;
    }
  }
  return GetWindowRect(hwnd, out_rect) != FALSE;
}

BOOL CALLBACK EnumVisibleWindowsProc(HWND hwnd, LPARAM lparam) {
  auto* ctx = reinterpret_cast<EnumWindowsContext*>(lparam);
  if (!ctx || !ctx->windows) return FALSE;

  if (hwnd == ctx->snip_hwnd || hwnd == ctx->hud_hwnd ||
      hwnd == ctx->scan_border_hwnd) {
    return TRUE;
  }
  if (!IsWindowVisible(hwnd)) return TRUE;

  DWORD pid = 0;
  GetWindowThreadProcessId(hwnd, &pid);
  if (pid == 0 || pid == ctx->self_pid) return TRUE;

  LONG_PTR ex_style = GetWindowLongPtrW(hwnd, GWL_EXSTYLE);
  if ((ex_style & WS_EX_TOOLWINDOW) != 0 &&
      (ex_style & WS_EX_APPWINDOW) == 0) {
    return TRUE;
  }

  // Exclude cloaked UWP background frames (e.g. suspended Store/Settings apps)
  DWORD cloaked = 0;
  if (SUCCEEDED(DwmGetWindowAttribute(hwnd, DWMWA_CLOAKED, &cloaked,
                                      sizeof(cloaked))) &&
      cloaked != 0) {
    return TRUE;
  }

  int title_len = GetWindowTextLengthW(hwnd);
  if (title_len <= 0) return TRUE;

  std::wstring title(static_cast<size_t>(title_len) + 1, L'\0');
  int copied = GetWindowTextW(hwnd, title.data(), title_len + 1);
  if (copied <= 0) return TRUE;
  title.resize(static_cast<size_t>(copied));

  const bool is_minimized = IsIconic(hwnd) != FALSE;
  RECT rect{};
  if (!is_minimized) {
    if (!GetAccurateWindowRect(hwnd, &rect)) return TRUE;
    if ((rect.right - rect.left) <= 1 || (rect.bottom - rect.top) <= 1) {
      return TRUE;
    }
  } else {
    WINDOWPLACEMENT wp{};
    wp.length = sizeof(wp);
    if (GetWindowPlacement(hwnd, &wp)) {
      rect = wp.rcNormalPosition;
    }
  }

  const int width = max(1, static_cast<int>(rect.right - rect.left));
  const int height = max(1, static_cast<int>(rect.bottom - rect.top));
  std::wstring proc_name = GetProcessBaseName(pid);

  flutter::EncodableMap entry;
  entry[flutter::EncodableValue("hwnd")] =
      flutter::EncodableValue(reinterpret_cast<int64_t>(hwnd));
  entry[flutter::EncodableValue("pid")] =
      flutter::EncodableValue(static_cast<int64_t>(pid));
  entry[flutter::EncodableValue("title")] =
      flutter::EncodableValue(WideToUtf8(title));
  entry[flutter::EncodableValue("processName")] =
      flutter::EncodableValue(WideToUtf8(proc_name));
  entry[flutter::EncodableValue("x")] =
      flutter::EncodableValue(static_cast<double>(rect.left));
  entry[flutter::EncodableValue("y")] =
      flutter::EncodableValue(static_cast<double>(rect.top));
  entry[flutter::EncodableValue("width")] =
      flutter::EncodableValue(static_cast<double>(width));
  entry[flutter::EncodableValue("height")] =
      flutter::EncodableValue(static_cast<double>(height));
  entry[flutter::EncodableValue("isMinimized")] =
      flutter::EncodableValue(is_minimized);

  ctx->windows->push_back(flutter::EncodableValue(entry));
  return TRUE;
}

bool GetEncoderClsid(const WCHAR* format, CLSID* pClsid) {
  UINT num = 0;
  UINT size = 0;
  Gdiplus::GetImageEncodersSize(&num, &size);
  if (size == 0) return false;

  std::vector<uint8_t> buffer(size);
  auto* info = reinterpret_cast<Gdiplus::ImageCodecInfo*>(buffer.data());
  if (Gdiplus::GetImageEncoders(num, size, info) != Gdiplus::Ok) return false;

  for (UINT j = 0; j < num; ++j) {
    if (wcscmp(info[j].MimeType, format) == 0) {
      *pClsid = info[j].Clsid;
      return true;
    }
  }
  return false;
}

/// Lightweight COM IBuffer wrapper over a byte vector for WinRT SoftwareBitmap.
class BgraWinRtBuffer
    : public Microsoft::WRL::RuntimeClass<
          Microsoft::WRL::RuntimeClassFlags<Microsoft::WRL::WinRtClassicComMix>,
          ABI::Windows::Storage::Streams::IBuffer,
          Windows::Storage::Streams::IBufferByteAccess> {
 public:
  explicit BgraWinRtBuffer(std::vector<uint8_t> data)
      : data_(std::move(data)) {}

  IFACEMETHODIMP get_Capacity(UINT32* value) override {
    if (!value) return E_POINTER;
    *value = static_cast<UINT32>(data_.size());
    return S_OK;
  }

  IFACEMETHODIMP get_Length(UINT32* value) override {
    if (!value) return E_POINTER;
    *value = static_cast<UINT32>(data_.size());
    return S_OK;
  }

  IFACEMETHODIMP put_Length(UINT32 value) override {
    if (value > data_.size()) return E_INVALIDARG;
    return S_OK;
  }

  IFACEMETHODIMP Buffer(byte** value) override {
    if (!value) return E_POINTER;
    *value = data_.empty() ? nullptr : data_.data();
    return S_OK;
  }

 private:
  std::vector<uint8_t> data_;
};

// Applies profile-specific contrast enhancement (removing DS grey drop shadows
// or normalizing camera lighting) and forces alpha = 255 for WinRT OCR.
std::vector<uint8_t> PreprocessFrameBytes(const std::vector<uint8_t>& bgra_bytes,
                                          int width,
                                          int height,
                                          const std::string& profile) {
  std::vector<uint8_t> out(bgra_bytes);
  const size_t pixel_count =
      static_cast<size_t>(width) * static_cast<size_t>(height);

  if (profile == "pixelArtDs") {
    for (size_t i = 0; i < pixel_count; ++i) {
      const size_t off = i * 4;
      const int b = out[off];
      const int g = out[off + 1];
      const int r = out[off + 2];
      const int y = (r * 299 + g * 587 + b * 114) / 1000;
      int mapped = 255;
      if (y <= 92) {
        mapped = 0;
      } else if (y <= 125) {
        mapped = (y - 92) * 4;
      } else if (y <= 195) {
        // Compress DS pixel-font grey drop shadows toward crisp background white.
        mapped = 185 + ((y - 125) * 70) / 70;
      }
      const uint8_t v =
          static_cast<uint8_t>((std::min)(255, (std::max)(0, mapped)));
      out[off] = v;
      out[off + 1] = v;
      out[off + 2] = v;
      out[off + 3] = 255;
    }
    return out;
  }

  if (profile == "cameraDisplay" && width >= 16 && height >= 16) {
    constexpr int kGrid = 8;
    const int cell_w = (std::max)(1, width / kGrid);
    const int cell_h = (std::max)(1, height / kGrid);
    int cell_min[kGrid][kGrid];
    int cell_max[kGrid][kGrid];
    for (int gy = 0; gy < kGrid; ++gy) {
      for (int gx = 0; gx < kGrid; ++gx) {
        cell_min[gy][gx] = 255;
        cell_max[gy][gx] = 0;
      }
    }
    for (int row = 0; row < height; ++row) {
      const int gy = (std::min)(kGrid - 1, row / cell_h);
      for (int col = 0; col < width; ++col) {
        const int gx = (std::min)(kGrid - 1, col / cell_w);
        const size_t off =
            (static_cast<size_t>(row) * static_cast<size_t>(width) + col) * 4;
        const int y =
            (out[off + 2] * 299 + out[off + 1] * 587 + out[off] * 114) / 1000;
        if (y < cell_min[gy][gx]) cell_min[gy][gx] = y;
        if (y > cell_max[gy][gx]) cell_max[gy][gx] = y;
      }
    }
    for (int row = 0; row < height; ++row) {
      const int gy = (std::min)(kGrid - 1, row / cell_h);
      for (int col = 0; col < width; ++col) {
        const int gx = (std::min)(kGrid - 1, col / cell_w);
        const size_t off =
            (static_cast<size_t>(row) * static_cast<size_t>(width) + col) * 4;
        const int lo = cell_min[gy][gx];
        const int hi = cell_max[gy][gx];
        const int span = hi - lo;
        const int y =
            (out[off + 2] * 299 + out[off + 1] * 587 + out[off] * 114) / 1000;
        int stretched = y;
        if (span >= 32) {
          stretched = ((y - lo) * 255) / span;
        }
        const uint8_t v =
            static_cast<uint8_t>((std::min)(255, (std::max)(0, stretched)));
        out[off] = v;
        out[off + 1] = v;
        out[off + 2] = v;
        out[off + 3] = 255;
      }
    }
    return out;
  }

  for (size_t i = 0; i < pixel_count; ++i) {
    out[i * 4 + 3] = 255;
  }
  return out;
}

struct CachedOcrEngineEntry {
  Microsoft::WRL::ComPtr<ABI::Windows::Media::Ocr::IOcrEngine> engine;
  std::string resolved_tag;
  bool used_fallback = false;
};

struct OcrRuntimeCache {
  Microsoft::WRL::ComPtr<ABI::Windows::Media::Ocr::IOcrEngineStatics>
      ocr_statics;
  Microsoft::WRL::ComPtr<ABI::Windows::Graphics::Imaging::ISoftwareBitmapStatics>
      bmp_statics;
  bool available_languages_loaded = false;
  std::vector<std::string> available_languages;
  std::unordered_map<std::string, CachedOcrEngineEntry> engines_by_tag;

  void Reset() {
    engines_by_tag.clear();
    available_languages.clear();
    available_languages_loaded = false;
    bmp_statics.Reset();
    ocr_statics.Reset();
  }
};

struct DoneEventGuard {
  std::mutex mtx;
  HANDLE handle = nullptr;
};

bool RunWindowsMediaOcrCached(OcrRuntimeCache* cache,
                              HANDLE stop_event,
                              const std::vector<uint8_t>& bgra_bytes,
                              int width,
                              int height,
                              const std::string& language_tag,
                              const std::string& preprocess_profile,
                              std::vector<std::string>* out_lines,
                              bool* out_used_fallback,
                              std::string* out_resolved_tag,
                              std::vector<std::string>* out_available_languages,
                              std::string* out_error_hint) {
  if (!cache || !out_lines || width <= 0 || height <= 0 ||
      bgra_bytes.size() < static_cast<size_t>(width) * height * 4) {
    if (out_error_hint) *out_error_hint = "Invalid frame buffer or dimensions";
    return false;
  }

  using namespace Microsoft::WRL;
  using namespace Microsoft::WRL::Wrappers;

  if (!cache->ocr_statics) {
    HRESULT hr = RoGetActivationFactory(
        HStringReference(RuntimeClass_Windows_Media_Ocr_OcrEngine).Get(),
        IID_PPV_ARGS(&cache->ocr_statics));
    if (FAILED(hr) || !cache->ocr_statics) {
      if (out_error_hint) *out_error_hint = "OcrEngine factory init failed";
      return false;
    }
  }

  if (!cache->available_languages_loaded) {
    ComPtr<ABI::Windows::Foundation::Collections::IVectorView<
        ABI::Windows::Globalization::Language*>>
        avail_langs;
    if (SUCCEEDED(
            cache->ocr_statics->get_AvailableRecognizerLanguages(&avail_langs)) &&
        avail_langs) {
      UINT32 lang_count = 0;
      avail_langs->get_Size(&lang_count);
      for (UINT32 i = 0; i < lang_count; ++i) {
        ComPtr<ABI::Windows::Globalization::ILanguage> lang_item;
        if (SUCCEEDED(avail_langs->GetAt(i, &lang_item)) && lang_item) {
          HSTRING h_tag = nullptr;
          if (SUCCEEDED(lang_item->get_LanguageTag(&h_tag)) && h_tag) {
            UINT32 len = 0;
            const wchar_t* raw = WindowsGetStringRawBuffer(h_tag, &len);
            if (raw && len > 0) {
              cache->available_languages.push_back(
                  WideToUtf8(std::wstring(raw, len)));
            }
            WindowsDeleteString(h_tag);
          }
        }
      }
      cache->available_languages_loaded = true;
    }
  }
  if (out_available_languages) {
    *out_available_languages = cache->available_languages;
  }

  ComPtr<ABI::Windows::Media::Ocr::IOcrEngine> ocr_engine;
  bool used_fallback = false;
  std::string resolved_tag = language_tag;

  auto cache_it = cache->engines_by_tag.find(language_tag);
  if (cache_it != cache->engines_by_tag.end() && cache_it->second.engine) {
    ocr_engine = cache_it->second.engine;
    used_fallback = cache_it->second.used_fallback;
    resolved_tag = cache_it->second.resolved_tag;
  } else {
    if (!language_tag.empty()) {
      ComPtr<ABI::Windows::Globalization::ILanguageFactory> lang_factory;
      if (SUCCEEDED(RoGetActivationFactory(
              HStringReference(RuntimeClass_Windows_Globalization_Language)
                  .Get(),
              IID_PPV_ARGS(&lang_factory))) &&
          lang_factory) {
        std::wstring wtag = Utf8ToWide(language_tag);
        HString htag;
        if (SUCCEEDED(htag.Set(wtag.c_str()))) {
          ComPtr<ABI::Windows::Globalization::ILanguage> lang;
          if (SUCCEEDED(lang_factory->CreateLanguage(htag.Get(), &lang)) &&
              lang) {
            cache->ocr_statics->TryCreateFromLanguage(lang.Get(), &ocr_engine);
          }
        }
      }
    }

    if (!ocr_engine) {
      used_fallback = !language_tag.empty();
      HRESULT hr = cache->ocr_statics->TryCreateFromUserProfileLanguages(
          &ocr_engine);
      if (FAILED(hr) || !ocr_engine) {
        if (out_error_hint) {
          *out_error_hint = "No Windows OCR language pack available";
        }
        return false;
      }
      ComPtr<ABI::Windows::Globalization::ILanguage> prof_lang;
      if (SUCCEEDED(ocr_engine->get_RecognizerLanguage(&prof_lang)) &&
          prof_lang) {
        HSTRING h_resolved = nullptr;
        if (SUCCEEDED(prof_lang->get_LanguageTag(&h_resolved)) && h_resolved) {
          UINT32 len = 0;
          const wchar_t* raw = WindowsGetStringRawBuffer(h_resolved, &len);
          if (raw && len > 0) {
            resolved_tag = WideToUtf8(std::wstring(raw, len));
          }
          WindowsDeleteString(h_resolved);
        }
      }
    }

    if (cache->engines_by_tag.size() >= 16) {
      cache->engines_by_tag.clear();
    }
    cache->engines_by_tag[language_tag] = CachedOcrEngineEntry{
        ocr_engine,
        resolved_tag,
        used_fallback,
    };
  }

  if (!cache->bmp_statics) {
    HRESULT hr = RoGetActivationFactory(
        HStringReference(RuntimeClass_Windows_Graphics_Imaging_SoftwareBitmap)
            .Get(),
        IID_PPV_ARGS(&cache->bmp_statics));
    if (FAILED(hr) || !cache->bmp_statics) {
      if (out_error_hint) *out_error_hint = "SoftwareBitmap factory init failed";
      return false;
    }
  }

  const std::vector<uint8_t>* active_bytes_ptr = &bgra_bytes;
  std::vector<uint8_t> preprocessed_storage;
  if (preprocess_profile == "pixelArtDs" ||
      preprocess_profile == "cameraDisplay") {
    preprocessed_storage =
        PreprocessFrameBytes(bgra_bytes, width, height, preprocess_profile);
    active_bytes_ptr = &preprocessed_storage;
  }
  const std::vector<uint8_t>& active_bytes = *active_bytes_ptr;

  ComPtr<BgraWinRtBuffer> winrt_buf;
  int ocr_width = width;
  int ocr_height = height;
  const int max_dim = (std::max)(width, height);
  int scaled_w = width;
  int scaled_h = height;
  bool use_nearest_neighbor = false;
  bool skip_gdi_resample = false;

  if (preprocess_profile == "pixelArtDs") {
    use_nearest_neighbor = true;
    int scale_factor = 1;
    if (max_dim <= 1000) {
      scale_factor = 3;
    } else if (max_dim <= 1800) {
      scale_factor = 2;
    }
    scaled_w = width * scale_factor;
    scaled_h = height * scale_factor;
  } else if (preprocess_profile == "cameraDisplay") {
    const int scale_factor = (max_dim <= 1600) ? 2 : 1;
    scaled_w = width * scale_factor;
    scaled_h = height * scale_factor;
    if (scale_factor == 1) skip_gdi_resample = true;
  } else {
    // "standard": upscale small dialogue boxes (<= 960px), direct 1:1 zero-GDI+
    // copy for medium sizes (961..1600px), and moderate downscale > 1600px.
    if (max_dim <= 960) {
      scaled_w = width * 2;
      scaled_h = height * 2;
    } else if (max_dim <= 1600) {
      skip_gdi_resample = true;
    } else {
      const double ratio = 1600.0 / static_cast<double>(max_dim);
      scaled_w = (std::max)(1, static_cast<int>(std::lround(width * ratio)));
      scaled_h = (std::max)(1, static_cast<int>(std::lround(height * ratio)));
    }
  }

  constexpr int kOcrPad = 16;
  const int padded_w = scaled_w + kOcrPad * 2;
  const int padded_h = scaled_h + kOcrPad * 2;

  if (skip_gdi_resample) {
    // Fast single-pass padding + opaque alpha without allocating GDI+ bitmaps
    std::vector<uint8_t> padded_bytes(
        static_cast<size_t>(padded_w) * padded_h * 4, 255);
    const size_t src_row_bytes = static_cast<size_t>(width) * 4;
    const size_t dst_row_bytes = static_cast<size_t>(padded_w) * 4;
    for (int row = 0; row < height; ++row) {
      const uint8_t* src_row =
          active_bytes.data() + static_cast<size_t>(row) * src_row_bytes;
      uint8_t* dst_row =
          padded_bytes.data() +
          static_cast<size_t>(row + kOcrPad) * dst_row_bytes +
          static_cast<size_t>(kOcrPad) * 4;
      std::memcpy(dst_row, src_row, src_row_bytes);
      for (int col = 0; col < width; ++col) {
        dst_row[col * 4 + 3] = 255;
      }
    }
    winrt_buf = Make<BgraWinRtBuffer>(std::move(padded_bytes));
    ocr_width = padded_w;
    ocr_height = padded_h;
  } else if (scaled_w > 0 && scaled_h > 0) {
    Gdiplus::Bitmap src_bmp(
        width, height, width * 4, PixelFormat32bppRGB,
        const_cast<BYTE*>(
            reinterpret_cast<const BYTE*>(active_bytes.data())));
    if (src_bmp.GetLastStatus() == Gdiplus::Ok) {
      Gdiplus::Bitmap dst_bmp(padded_w, padded_h, PixelFormat32bppRGB);
      if (dst_bmp.GetLastStatus() == Gdiplus::Ok) {
        Gdiplus::Graphics graphics(&dst_bmp);
        graphics.Clear(Gdiplus::Color(255, 255, 255));
        const bool is_downscale = scaled_w < width || scaled_h < height;
        graphics.SetInterpolationMode(
            use_nearest_neighbor
                ? Gdiplus::InterpolationModeNearestNeighbor
                : (is_downscale ? Gdiplus::InterpolationModeBilinear
                                : Gdiplus::InterpolationModeHighQualityBicubic));
        graphics.SetPixelOffsetMode(
            use_nearest_neighbor
                ? Gdiplus::PixelOffsetModeHalf
                : Gdiplus::PixelOffsetModeHighQuality);
        graphics.SetCompositingQuality(
            is_downscale ? Gdiplus::CompositingQualityHighSpeed
                         : Gdiplus::CompositingQualityHighQuality);
        if (graphics.DrawImage(&src_bmp,
                               Gdiplus::Rect(kOcrPad, kOcrPad, scaled_w, scaled_h),
                               0, 0, width, height, Gdiplus::UnitPixel) ==
            Gdiplus::Ok) {
          Gdiplus::BitmapData locked{};
          Gdiplus::Rect lock_rect(0, 0, padded_w, padded_h);
          if (dst_bmp.LockBits(&lock_rect, Gdiplus::ImageLockModeRead,
                               PixelFormat32bppRGB, &locked) == Gdiplus::Ok) {
            std::vector<uint8_t> scaled_bytes(
                static_cast<size_t>(padded_w) * padded_h * 4);
            const auto* base_ptr =
                static_cast<const uint8_t*>(locked.Scan0);
            const int row_bytes = padded_w * 4;
            for (int row = 0; row < padded_h; ++row) {
              const uint8_t* src_row = base_ptr + row * locked.Stride;
              uint8_t* dst_row =
                  scaled_bytes.data() + static_cast<size_t>(row) * row_bytes;
              std::memcpy(dst_row, src_row, static_cast<size_t>(row_bytes));
              for (int col = 0; col < padded_w; ++col) {
                dst_row[col * 4 + 3] = 255;
              }
            }
            dst_bmp.UnlockBits(&locked);
            winrt_buf = Make<BgraWinRtBuffer>(std::move(scaled_bytes));
            ocr_width = padded_w;
            ocr_height = padded_h;
          }
        }
      }
    }
  }
  if (!winrt_buf) {
    winrt_buf = Make<BgraWinRtBuffer>(active_bytes);
  }
  if (!winrt_buf) {
    if (out_error_hint) *out_error_hint = "BgraWinRtBuffer allocation failed";
    return false;
  }

  ComPtr<ABI::Windows::Storage::Streams::IBuffer> ibuf;
  if (FAILED(winrt_buf.As(&ibuf)) || !ibuf) {
    if (out_error_hint) *out_error_hint = "IBuffer cast failed";
    return false;
  }

  ComPtr<ABI::Windows::Graphics::Imaging::ISoftwareBitmap> software_bmp;
  HRESULT hr = cache->bmp_statics->CreateCopyFromBuffer(
      ibuf.Get(),
      ABI::Windows::Graphics::Imaging::BitmapPixelFormat_Bgra8,
      static_cast<INT32>(ocr_width),
      static_cast<INT32>(ocr_height),
      &software_bmp);
  if (FAILED(hr) || !software_bmp) {
    if (out_error_hint) *out_error_hint = "CreateCopyFromBuffer failed";
    return false;
  }

  ComPtr<ABI::Windows::Foundation::IAsyncOperation<
      ABI::Windows::Media::Ocr::OcrResult*>>
      async_op;
  hr = ocr_engine->RecognizeAsync(software_bmp.Get(), &async_op);
  if (FAILED(hr) || !async_op) {
    if (out_error_hint) *out_error_hint = "RecognizeAsync call failed";
    return false;
  }

  auto guard = std::make_shared<DoneEventGuard>();
  guard->handle = CreateEventW(nullptr, TRUE, FALSE, nullptr);
  if (!guard->handle) {
    if (out_error_hint) *out_error_hint = "CreateEventW failed";
    return false;
  }

  auto completed_cb = Callback<ABI::Windows::Foundation::IAsyncOperationCompletedHandler<
      ABI::Windows::Media::Ocr::OcrResult*>>(
      [guard](
          ABI::Windows::Foundation::IAsyncOperation<
              ABI::Windows::Media::Ocr::OcrResult*>* /*op*/,
          ABI::Windows::Foundation::AsyncStatus /*status*/) -> HRESULT {
        std::lock_guard<std::mutex> lock(guard->mtx);
        if (guard->handle) {
          SetEvent(guard->handle);
        }
        return S_OK;
      });

  hr = async_op->put_Completed(completed_cb.Get());
  if (FAILED(hr)) {
    if (out_error_hint) *out_error_hint = "put_Completed failed";
    HANDLE h_to_close = nullptr;
    {
      std::lock_guard<std::mutex> lock(guard->mtx);
      h_to_close = guard->handle;
      guard->handle = nullptr;
    }
    if (h_to_close) CloseHandle(h_to_close);
    return false;
  }

  HANDLE wait_handles[2] = {guard->handle, stop_event};
  const DWORD wait_count = stop_event ? 2 : 1;
  DWORD wait_res = WaitForMultipleObjects(wait_count, wait_handles, FALSE, 4000);
  {
    HANDLE h_to_close = nullptr;
    std::lock_guard<std::mutex> lock(guard->mtx);
    h_to_close = guard->handle;
    guard->handle = nullptr;
    if (h_to_close) CloseHandle(h_to_close);
  }
  if (wait_res == WAIT_OBJECT_0 + 1) {
    if (out_error_hint) *out_error_hint = "Windows OCR cancelled on shutdown";
    return false;
  }
  if (wait_res == WAIT_TIMEOUT) {
    if (out_error_hint) *out_error_hint = "Windows OCR timeout (>4s)";
    return false;
  }
  if (wait_res != WAIT_OBJECT_0) {
    if (out_error_hint) *out_error_hint = "Windows OCR wait failed";
    return false;
  }

  ComPtr<ABI::Windows::Media::Ocr::IOcrResult> ocr_result;
  hr = async_op->GetResults(&ocr_result);
  if (FAILED(hr) || !ocr_result) {
    if (out_error_hint) *out_error_hint = "GetResults failed";
    return false;
  }

  ComPtr<ABI::Windows::Foundation::Collections::IVectorView<
      ABI::Windows::Media::Ocr::OcrLine*>>
      lines_view;
  hr = ocr_result->get_Lines(&lines_view);
  if (FAILED(hr) || !lines_view) {
    return false;
  }

  UINT32 count = 0;
  lines_view->get_Size(&count);
  for (UINT32 i = 0; i < count; ++i) {
    ComPtr<ABI::Windows::Media::Ocr::IOcrLine> line;
    if (SUCCEEDED(lines_view->GetAt(i, &line)) && line) {
      HSTRING htext = nullptr;
      if (SUCCEEDED(line->get_Text(&htext)) && htext) {
        UINT32 len = 0;
        const wchar_t* raw = WindowsGetStringRawBuffer(htext, &len);
        if (raw && len > 0) {
          std::string utf8 = WideToUtf8(std::wstring(raw, len));
          if (!utf8.empty()) {
            out_lines->push_back(std::move(utf8));
          }
        }
        WindowsDeleteString(htext);
      }
    }
  }

  if (out_used_fallback) *out_used_fallback = used_fallback;
  if (out_resolved_tag) *out_resolved_tag = resolved_tag;

  return true;
}

int64_t ComputeFrameFingerprintNative(const std::vector<uint8_t>& bytes,
                                      int width,
                                      int height) {
  uint32_t hash = 2166136261u;
  auto mix = [&hash](uint32_t v) {
    hash = ((hash ^ v) * 16777619u) & 0x7FFFFFFFu;
  };
  mix(static_cast<uint32_t>(width));
  mix(static_cast<uint32_t>(height));
  mix(static_cast<uint32_t>(bytes.size()));
  if (bytes.empty()) return static_cast<int64_t>(hash);

  const size_t total_pixels = bytes.size() / 4;
  if (total_pixels == 0) {
    for (uint8_t b : bytes) mix(b);
    return static_cast<int64_t>(hash);
  }
  const size_t pixel_step =
      total_pixels <= 2048 ? 1 : ((total_pixels / 2048) | 1);
  for (size_t px = 0; px < total_pixels; px += pixel_step) {
    const size_t off = px * 4;
    const uint32_t rgb = static_cast<uint32_t>(bytes[off]) |
                         (static_cast<uint32_t>(bytes[off + 1]) << 8) |
                         (static_cast<uint32_t>(bytes[off + 2]) << 16);
    mix(rgb);
  }
  for (size_t i = total_pixels * 4; i < bytes.size(); ++i) {
    mix(bytes[i]);
  }
  mix(bytes.front());
  mix(bytes.back());
  return static_cast<int64_t>(hash);
}

void ComputeLuminanceAndSummary(const std::vector<uint8_t>& bytes,
                                int width,
                                int height,
                                double* out_avg_luma,
                                double* out_std_dev,
                                std::string* out_summary) {
  if (width <= 0 || height <= 0) return;
  const size_t total_pixels =
      static_cast<size_t>(width) * static_cast<size_t>(height);
  if (bytes.size() < total_pixels * 4 || total_pixels == 0) return;

  const size_t step = total_pixels > 2400 ? (total_pixels / 1200) : 1;
  int min_luma = 255;
  int max_luma = 0;
  int64_t sum = 0;
  int64_t sum_sq = 0;
  int64_t non_black = 0;
  int64_t count = 0;

  for (size_t px = 0; px < total_pixels; px += step) {
    const size_t off = px * 4;
    const int b = bytes[off];
    const int g = bytes[off + 1];
    const int r = bytes[off + 2];
    const int luma = (r * 299 + g * 587 + b * 114) / 1000;
    if (luma < min_luma) min_luma = luma;
    if (luma > max_luma) max_luma = luma;
    if (luma > 5) non_black++;
    sum += luma;
    sum_sq += static_cast<int64_t>(luma) * luma;
    count++;
  }
  if (count <= 0) return;

  const double mean = static_cast<double>(sum) / static_cast<double>(count);
  const double variance = (std::max)(
      0.0, (static_cast<double>(sum_sq) / static_cast<double>(count)) -
               (mean * mean));
  if (out_avg_luma) *out_avg_luma = mean;
  if (out_std_dev) *out_std_dev = std::sqrt(variance);

  if (out_summary) {
    char buf[96]{};
    if (max_luma <= 2) {
      snprintf(buf, sizeof(buf), "luma=0..%d ALL_BLACK (nonBlack=0%%)",
               max_luma);
    } else {
      const int avg_i = static_cast<int>(sum / count);
      const int pct = static_cast<int>(
          std::lround((static_cast<double>(non_black) * 100.0) /
                      static_cast<double>(count)));
      snprintf(buf, sizeof(buf), "luma=%d..%d avg=%d nonBlack=%d%%", min_luma,
               max_luma, avg_i, pct);
    }
    *out_summary = buf;
  }
}

bool ComputeColorHistogram16(const std::vector<uint8_t>& bytes,
                             int width,
                             int height,
                             std::array<double, 16>* out_bins) {
  if (!out_bins || width <= 0 || height <= 0) return false;
  const size_t total_pixels =
      static_cast<size_t>(width) * static_cast<size_t>(height);
  if (bytes.size() < total_pixels * 4 || total_pixels == 0) return false;

  const int x0 = static_cast<int>(std::floor(width * 0.2));
  const int x1 = (std::max)(x0 + 1, static_cast<int>(std::ceil(width * 0.8)));
  const int y0 = static_cast<int>(std::floor(height * 0.2));
  const int y1 = (std::max)(y0 + 1, static_cast<int>(std::ceil(height * 0.8)));
  const int region_pixels = (x1 - x0) * (y1 - y0);
  const int stride = (std::max)(
      1, static_cast<int>(std::floor(std::sqrt(region_pixels / 1200.0))));

  out_bins->fill(0.0);
  int total_sampled = 0;
  int chroma_count = 0;

  for (int y = y0; y < y1; y += stride) {
    const size_t row_off = static_cast<size_t>(y) * static_cast<size_t>(width);
    for (int x = x0; x < x1; x += stride) {
      const size_t idx = (row_off + static_cast<size_t>(x)) * 4;
      const double b = bytes[idx] / 255.0;
      const double g = bytes[idx + 1] / 255.0;
      const double r = bytes[idx + 2] / 255.0;

      const double max_c = (std::max)(r, (std::max)(g, b));
      const double min_c = (std::min)(r, (std::min)(g, b));
      const double delta = max_c - min_c;
      const double val = max_c;
      const double sat = max_c > 0.0 ? (delta / max_c) : 0.0;

      total_sampled++;
      if (sat >= 0.22 && val >= 0.18 && val <= 0.96 && delta > 0.001) {
        chroma_count++;
        double hue = 0.0;
        if (max_c == r) {
          hue = 60.0 * std::fmod(((g - b) / delta), 6.0);
        } else if (max_c == g) {
          hue = 60.0 * (((b - r) / delta) + 2.0);
        } else {
          hue = 60.0 * (((r - g) / delta) + 4.0);
        }
        if (hue < 0.0) hue += 360.0;
        const int hue_bin =
            std::clamp(static_cast<int>(std::floor(hue / 30.0)), 0, 11);
        (*out_bins)[static_cast<size_t>(hue_bin)] += 1.0;
      } else {
        const int v_bin =
            std::clamp(static_cast<int>(std::floor(val * 4.0)), 0, 3);
        (*out_bins)[static_cast<size_t>(12 + v_bin)] += 1.0;
      }
    }
  }

  if (total_sampled == 0) return false;
  if (static_cast<double>(chroma_count) / static_cast<double>(total_sampled) <
      0.08) {
    return false;
  }
  for (int i = 0; i < 16; ++i) {
    (*out_bins)[static_cast<size_t>(i)] /= static_cast<double>(total_sampled);
  }
  return true;
}

bool ApplySelfWindowMaskIfOverlapping(HWND main_hwnd,
                                      int cap_x,
                                      int cap_y,
                                      int cap_w,
                                      int cap_h,
                                      std::vector<uint8_t>* bgra,
                                      bool mask_self) {
  if (!main_hwnd || !IsWindow(main_hwnd) || !IsWindowVisible(main_hwnd) ||
      IsIconic(main_hwnd) || cap_w <= 0 || cap_h <= 0) {
    return false;
  }
  RECT main_rect{};
  if (!GetAccurateWindowRect(main_hwnd, &main_rect)) {
    return false;
  }
  const int ix0 = (std::max)(cap_x, static_cast<int>(main_rect.left));
  const int iy0 = (std::max)(cap_y, static_cast<int>(main_rect.top));
  const int ix1 =
      (std::min)(cap_x + cap_w, static_cast<int>(main_rect.right));
  const int iy1 =
      (std::min)(cap_y + cap_h, static_cast<int>(main_rect.bottom));

  if (ix1 <= ix0 || iy1 <= iy0) {
    return false;
  }

  // Only treat as meaningful overlap if at least 24x24 px intersects
  if ((ix1 - ix0) < 24 || (iy1 - iy0) < 24) {
    return false;
  }

  if (mask_self && bgra &&
      bgra->size() >=
          static_cast<size_t>(cap_w) * static_cast<size_t>(cap_h) * 4) {
    const int local_x0 = ix0 - cap_x;
    const int local_y0 = iy0 - cap_y;
    const int local_x1 = ix1 - cap_x;
    const int local_y1 = iy1 - cap_y;
    for (int row = local_y0; row < local_y1; ++row) {
      uint8_t* row_ptr =
          bgra->data() +
          (static_cast<size_t>(row) * static_cast<size_t>(cap_w) +
           static_cast<size_t>(local_x0)) *
              4;
      const int span_px = local_x1 - local_x0;
      for (int c = 0; c < span_px; ++c) {
        row_ptr[c * 4 + 0] = 0;
        row_ptr[c * 4 + 1] = 0;
        row_ptr[c * 4 + 2] = 0;
        row_ptr[c * 4 + 3] = 255;
      }
    }
  }
  return true;
}

bool EncodeDownscaledThumbnailPng(const std::vector<uint8_t>& bgra,
                                  int width,
                                  int height,
                                  int max_width,
                                  std::vector<uint8_t>* out_png,
                                  int* out_w,
                                  int* out_h) {
  if (!out_png || width <= 0 || height <= 0 ||
      bgra.size() < static_cast<size_t>(width) * static_cast<size_t>(height) * 4) {
    return false;
  }
  CLSID png_clsid{};
  if (!GetEncoderClsid(L"image/png", &png_clsid)) return false;

  const int clamped_max = (std::max)(64, max_width);
  const int dst_w = (std::min)(width, clamped_max);
  const int dst_h = (std::max)(
      1, static_cast<int>(std::lround(static_cast<double>(height) *
                                      static_cast<double>(dst_w) /
                                      static_cast<double>(width))));

  Gdiplus::Bitmap src_bmp(
      width, height, width * 4, PixelFormat32bppRGB,
      const_cast<BYTE*>(reinterpret_cast<const BYTE*>(bgra.data())));
  if (src_bmp.GetLastStatus() != Gdiplus::Ok) return false;

  IStream* stream = nullptr;
  if (FAILED(CreateStreamOnHGlobal(nullptr, TRUE, &stream)) || !stream) {
    return false;
  }

  bool ok = false;
  if (dst_w == width && dst_h == height) {
    ok = (src_bmp.Save(stream, &png_clsid, nullptr) == Gdiplus::Ok);
  } else {
    Gdiplus::Bitmap dst_bmp(dst_w, dst_h, PixelFormat32bppRGB);
    if (dst_bmp.GetLastStatus() == Gdiplus::Ok) {
      Gdiplus::Graphics g(&dst_bmp);
      g.SetInterpolationMode(Gdiplus::InterpolationModeBilinear);
      g.SetCompositingQuality(Gdiplus::CompositingQualityHighSpeed);
      if (g.DrawImage(&src_bmp, 0, 0, dst_w, dst_h) == Gdiplus::Ok) {
        ok = (dst_bmp.Save(stream, &png_clsid, nullptr) == Gdiplus::Ok);
      }
    }
  }

  if (ok) {
    STATSTG stat{};
    if (SUCCEEDED(stream->Stat(&stat, STATFLAG_NONAME)) &&
        stat.cbSize.QuadPart > 0) {
      LARGE_INTEGER zero{};
      stream->Seek(zero, STREAM_SEEK_SET, nullptr);
      out_png->resize(static_cast<size_t>(stat.cbSize.QuadPart));
      ULONG bytes_read = 0;
      if (SUCCEEDED(stream->Read(out_png->data(),
                                 static_cast<ULONG>(out_png->size()),
                                 &bytes_read))) {
        out_png->resize(bytes_read);
        ok = !out_png->empty();
      } else {
        ok = false;
      }
    } else {
      ok = false;
    }
  }

  stream->Release();
  if (ok) {
    if (out_w) *out_w = dst_w;
    if (out_h) *out_h = dst_h;
  }
  return ok;
}

bool IsFocusCandidateLine(const std::string& line) {
  int ascii_run = 0;
  int non_ascii_count = 0;
  for (size_t i = 0; i < line.size(); ++i) {
    const unsigned char c = static_cast<unsigned char>(line[i]);
    if (c >= 0x80) {
      non_ascii_count++;
      ascii_run = 0;
    } else if (std::isalpha(c)) {
      ascii_run++;
      if (ascii_run >= 5) return true;
    } else {
      ascii_run = 0;
    }
  }
  return non_ascii_count >= 4;
}

std::vector<uint8_t> CropBgraRect(const std::vector<uint8_t>& src,
                                  int src_w,
                                  int x,
                                  int y,
                                  int w,
                                  int h) {
  std::vector<uint8_t> out(static_cast<size_t>(w) * static_cast<size_t>(h) * 4);
  const size_t src_stride = static_cast<size_t>(src_w) * 4;
  const size_t dst_stride = static_cast<size_t>(w) * 4;
  for (int row = 0; row < h; ++row) {
    const size_t off =
        static_cast<size_t>(y + row) * src_stride + static_cast<size_t>(x) * 4;
    std::memcpy(out.data() + static_cast<size_t>(row) * dst_stride,
                src.data() + off, dst_stride);
  }
  return out;
}

std::vector<uint8_t> InvertBgraLuminance(const std::vector<uint8_t>& src) {
  std::vector<uint8_t> out(src.size());
  for (size_t i = 0; i + 3 < src.size(); i += 4) {
    out[i + 0] = static_cast<uint8_t>(255 - src[i + 0]);
    out[i + 1] = static_cast<uint8_t>(255 - src[i + 1]);
    out[i + 2] = static_cast<uint8_t>(255 - src[i + 2]);
    out[i + 3] = 255;
  }
  return out;
}

bool RunZoneBMultiBandOcr(OcrRuntimeCache* cache,
                          HANDLE stop_event,
                          const std::vector<uint8_t>& bgra_bytes,
                          int width,
                          int height,
                          const std::string& language_tag,
                          const std::string& preprocess_profile,
                          std::vector<std::string>* out_lines,
                          bool* out_used_fallback,
                          std::string* out_resolved_tag,
                          std::vector<std::string>* out_available_languages,
                          std::string* out_error_hint) {
  std::vector<std::string> merged;
  std::unordered_set<std::string> seen_lower;
  auto add_lines = [&](const std::vector<std::string>& lines) {
    for (const auto& l : lines) {
      std::string key = l;
      std::transform(key.begin(), key.end(), key.begin(),
                     [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
      if (seen_lower.insert(key).second) {
        merged.push_back(l);
      }
    }
  };
  auto count_candidates = [&]() {
    int c = 0;
    for (const auto& l : merged) {
      if (IsFocusCandidateLine(l)) c++;
    }
    return c;
  };

  std::vector<std::string> base_lines;
  const bool base_ok = RunWindowsMediaOcrCached(
      cache, stop_event, bgra_bytes, width, height, language_tag,
      preprocess_profile, &base_lines, out_used_fallback, out_resolved_tag,
      out_available_languages, out_error_hint);
  if (base_ok) {
    add_lines(base_lines);
  }

  auto run_bands = [&](const std::vector<uint8_t>& frame_bytes) {
    if (width < 20 || height < 16) return;
    const int band_h = (std::max)(8, (height * 58) / 100);
    const int band_w = (std::max)(12, (width * 58) / 100);
    struct BandRect {
      int x, y, w, h;
    };
    const BandRect bands[4] = {
        {0, 0, width, band_h},
        {0, (std::max)(0, height - band_h), width, band_h},
        {0, 0, band_w, height},
        {(std::max)(0, width - band_w), 0, band_w, height},
    };
    for (const auto& b : bands) {
      if (b.w <= 0 || b.h <= 0 || b.x + b.w > width || b.y + b.h > height) {
        continue;
      }
      auto cropped = CropBgraRect(frame_bytes, width, b.x, b.y, b.w, b.h);
      std::vector<std::string> band_lines;
      if (RunWindowsMediaOcrCached(cache, stop_event, cropped, b.w, b.h,
                                   language_tag, preprocess_profile,
                                   &band_lines, nullptr, nullptr, nullptr,
                                   nullptr)) {
        add_lines(band_lines);
      }
    }
  };

  if (count_candidates() < 2) {
    run_bands(bgra_bytes);
  }
  if (count_candidates() == 0) {
    auto inverted = InvertBgraLuminance(bgra_bytes);
    std::vector<std::string> inv_lines;
    if (RunWindowsMediaOcrCached(cache, stop_event, inverted, width, height,
                                 language_tag, preprocess_profile, &inv_lines,
                                 nullptr, nullptr, nullptr, nullptr)) {
      add_lines(inv_lines);
    }
    if (count_candidates() < 2) {
      run_bands(inverted);
    }
  }

  if (out_lines) {
    *out_lines = std::move(merged);
  }
  return base_ok;
}

}  // namespace

DesktopTrackerPlugin::DesktopTrackerPlugin(HWND main_window_hwnd,
                                           flutter::BinaryMessenger* messenger)
    : main_window_hwnd_(main_window_hwnd) {
  Gdiplus::GdiplusStartupInput gdiplus_startup_input;
  Gdiplus::GdiplusStartup(&gdiplus_token_, &gdiplus_startup_input, nullptr);

  EnsureOverlayWindowClasses();

  dispatcher_hwnd_ = CreateWindowExW(
      0, kDispatcherClassName, L"", 0, 0, 0, 0, 0, HWND_MESSAGE, nullptr,
      GetModuleHandleW(nullptr), this);

  ocr_stop_event_ = CreateEventW(nullptr, TRUE, FALSE, nullptr);
  ocr_worker_thread_ = std::thread(&DesktopTrackerPlugin::OcrWorkerLoop, this);

  channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "pokevault/desktop_tracker",
      &flutter::StandardMethodCodec::GetInstance());

  channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        this->HandleMethodCall(call, std::move(result));
      });
}

DesktopTrackerPlugin::~DesktopTrackerPlugin() {
  if (alive_flag_) {
    alive_flag_->store(false);
  }
  if (ocr_stop_event_) {
    SetEvent(ocr_stop_event_);
  }
  {
    std::lock_guard<std::mutex> lock(ocr_queue_mutex_);
    ocr_worker_stopping_ = true;
    while (!ocr_queue_.empty()) {
      auto item = std::move(ocr_queue_.front());
      ocr_queue_.pop();
      if (item.ocr_payload) {
        item.ocr_payload->result.release();
        delete item.ocr_payload;
      }
      if (item.capture_payload) {
        item.capture_payload->result.release();
        delete item.capture_payload;
      }
      if (item.analyze_payload) {
        item.analyze_payload->result.release();
        delete item.analyze_payload;
      }
    }
  }
  ocr_queue_cv_.notify_all();
  if (ocr_worker_thread_.joinable()) {
    ocr_worker_thread_.join();
  }
  if (ocr_stop_event_) {
    CloseHandle(ocr_stop_event_);
    ocr_stop_event_ = nullptr;
  }
  window_capture_cache_.bgra_bytes.clear();
  window_capture_cache_.hwnd = nullptr;
  slot_fingerprints_.clear();

  CleanupSnippingOverlay();
  HideScanRegionBorder();
  ClearOverlayBorders();
  HideFloatingHud();
  if (scan_border_font_) {
    DeleteObject(scan_border_font_);
    scan_border_font_ = nullptr;
  }
  if (pending_snip_result_) {
    pending_snip_result_->Success(flutter::EncodableValue());
    pending_snip_result_.reset();
  }
  if (dispatcher_hwnd_) {
    DestroyWindow(dispatcher_hwnd_);
    dispatcher_hwnd_ = nullptr;
  }
  if (gdiplus_token_ != 0) {
    Gdiplus::GdiplusShutdown(gdiplus_token_);
    gdiplus_token_ = 0;
  }
}

bool DesktopTrackerPlugin::EnsureOverlayWindowClasses() {
  HINSTANCE hinst = GetModuleHandleW(nullptr);

  WNDCLASSEXW disp_wc{};
  if (!GetClassInfoExW(hinst, kDispatcherClassName, &disp_wc)) {
    disp_wc.cbSize = sizeof(disp_wc);
    disp_wc.lpfnWndProc = DesktopTrackerPlugin::DispatcherWndProc;
    disp_wc.hInstance = hinst;
    disp_wc.lpszClassName = kDispatcherClassName;
    RegisterClassExW(&disp_wc);
  }

  WNDCLASSEXW snip_wc{};
  if (!GetClassInfoExW(hinst, kSnipOverlayClassName, &snip_wc)) {
    snip_wc.cbSize = sizeof(snip_wc);
    snip_wc.style = CS_HREDRAW | CS_VREDRAW | CS_DBLCLKS;
    snip_wc.lpfnWndProc = DesktopTrackerPlugin::SnippingWndProc;
    snip_wc.hInstance = hinst;
    snip_wc.hCursor = LoadCursorW(nullptr, IDC_CROSS);
    snip_wc.lpszClassName = kSnipOverlayClassName;
    RegisterClassExW(&snip_wc);
  }

  WNDCLASSEXW hud_wc{};
  if (!GetClassInfoExW(hinst, kHudWindowClassName, &hud_wc)) {
    hud_wc.cbSize = sizeof(hud_wc);
    hud_wc.style = CS_HREDRAW | CS_VREDRAW;
    hud_wc.lpfnWndProc = DesktopTrackerPlugin::HudWndProc;
    hud_wc.hInstance = hinst;
    hud_wc.hCursor = LoadCursorW(nullptr, IDC_ARROW);
    hud_wc.lpszClassName = kHudWindowClassName;
    RegisterClassExW(&hud_wc);
  }

  WNDCLASSEXW border_wc{};
  if (!GetClassInfoExW(hinst, kScanBorderClassName, &border_wc)) {
    border_wc.cbSize = sizeof(border_wc);
    border_wc.style = CS_HREDRAW | CS_VREDRAW;
    border_wc.lpfnWndProc = DesktopTrackerPlugin::ScanBorderWndProc;
    border_wc.hInstance = hinst;
    border_wc.lpszClassName = kScanBorderClassName;
    RegisterClassExW(&border_wc);
  }

  return true;
}

void DesktopTrackerPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const std::string& method = call.method_name();

  if (method == "enumerateWindows") {
    result->Success(EnumerateWindowsAndMonitors());
    return;
  }

  if (method == "startDesktopSnipping") {
    const auto* args =
        std::get_if<flutter::EncodableMap>(call.arguments());
    StartDesktopSnipping(args, std::move(result));
    return;
  }

  if (method == "captureRegion") {
    const auto* args =
        std::get_if<flutter::EncodableMap>(call.arguments());
    if (!args) {
      result->Success(flutter::EncodableValue());
      return;
    }
    CaptureRegionAsync(*args, std::move(result));
    return;
  }

  if (method == "captureWindow") {
    const auto* args =
        std::get_if<flutter::EncodableMap>(call.arguments());
    if (!args) {
      result->Success(flutter::EncodableValue());
      return;
    }
    CaptureWindowAsync(*args, std::move(result));
    return;
  }

  if (method == "captureAndAnalyze") {
    const auto* args =
        std::get_if<flutter::EncodableMap>(call.arguments());
    if (!args) {
      result->Success(flutter::EncodableValue());
      return;
    }
    CaptureAndAnalyzeAsync(*args, std::move(result));
    return;
  }

  if (method == "clearScanCache") {
    ClearScanCacheAsync();
    result->Success(flutter::EncodableValue(true));
    return;
  }

  if (method == "recognizeText") {
    const auto* args =
        std::get_if<flutter::EncodableMap>(call.arguments());
    if (!args) {
      result->Success(flutter::EncodableValue());
      return;
    }
    RecognizeTextAsync(*args, std::move(result));
    return;
  }

  if (method == "showFloatingHud") {
    const auto* args =
        std::get_if<flutter::EncodableMap>(call.arguments());
    bool ok = args ? ShowOrUpdateFloatingHud(*args, true) : false;
    result->Success(flutter::EncodableValue(ok));
    return;
  }

  if (method == "updateFloatingHud") {
    const auto* args =
        std::get_if<flutter::EncodableMap>(call.arguments());
    bool ok = args ? ShowOrUpdateFloatingHud(*args, false) : false;
    result->Success(flutter::EncodableValue(ok));
    return;
  }

  if (method == "hideFloatingHud") {
    HideFloatingHud();
    result->Success(flutter::EncodableValue(true));
    return;
  }

  if (method == "showScanRegionBorder") {
    const auto* args =
        std::get_if<flutter::EncodableMap>(call.arguments());
    if (args) {
      ShowScanRegionBorder(*args);
    }
    result->Success(flutter::EncodableValue(true));
    return;
  }

  if (method == "hideScanRegionBorder") {
    HideScanRegionBorder();
    result->Success(flutter::EncodableValue(true));
    return;
  }

  if (method == "setOverlayBorders") {
    const auto* args =
        std::get_if<flutter::EncodableMap>(call.arguments());
    if (args) {
      SetOverlayBorders(*args);
    } else {
      ClearOverlayBorders();
    }
    result->Success(flutter::EncodableValue(true));
    return;
  }

  result->NotImplemented();
}

flutter::EncodableValue DesktopTrackerPlugin::EnumerateWindowsAndMonitors() {
  flutter::EncodableList monitors;
  EnumMonitorsContext mon_ctx{&monitors, 0};
  EnumDisplayMonitors(nullptr, nullptr, EnumMonitorsProc,
                      reinterpret_cast<LPARAM>(&mon_ctx));

  // If multiple monitors exist, append a combined Virtual Desktop entry
  if (monitors.size() > 1) {
    int vx = 0, vy = 0, vw = 0, vh = 0;
    QueryVirtualScreenBounds(&vx, &vy, &vw, &vh);
    wchar_t vlabel[128]{};
    swprintf_s(
        vlabel,
        L"\U0001F5A5\uFE0F Gesamter Desktop (Alle Monitore \u2014 %d\u00D7%d)",
        vw, vh);

    flutter::EncodableMap vmap;
    vmap[flutter::EncodableValue("index")] = flutter::EncodableValue(0);
    vmap[flutter::EncodableValue("title")] =
        flutter::EncodableValue(WideToUtf8(vlabel));
    vmap[flutter::EncodableValue("x")] =
        flutter::EncodableValue(static_cast<double>(vx));
    vmap[flutter::EncodableValue("y")] =
        flutter::EncodableValue(static_cast<double>(vy));
    vmap[flutter::EncodableValue("width")] =
        flutter::EncodableValue(static_cast<double>(vw));
    vmap[flutter::EncodableValue("height")] =
        flutter::EncodableValue(static_cast<double>(vh));
    vmap[flutter::EncodableValue("isPrimary")] = flutter::EncodableValue(false);
    vmap[flutter::EncodableValue("isVirtualDesktop")] =
        flutter::EncodableValue(true);
    monitors.push_back(flutter::EncodableValue(vmap));
  }

  flutter::EncodableList windows;
  EnumWindowsContext win_ctx{&windows, GetCurrentProcessId(), snip_hwnd_,
                             hud_hwnd_, scan_border_hwnd_};
  EnumWindows(EnumVisibleWindowsProc, reinterpret_cast<LPARAM>(&win_ctx));

  flutter::EncodableMap root;
  root[flutter::EncodableValue("monitors")] =
      flutter::EncodableValue(std::move(monitors));
  root[flutter::EncodableValue("windows")] =
      flutter::EncodableValue(std::move(windows));
  return flutter::EncodableValue(std::move(root));
}

void DesktopTrackerPlugin::StartDesktopSnipping(
    const flutter::EncodableMap* args,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (pending_snip_result_ || snip_hwnd_) {
    result->Success(flutter::EncodableValue());
    return;
  }

  snip_hint_label_ =
      L"Live-OCR-Bereich aufziehen: Bereich wird laufend gescannt  \u00B7  ESC = Abbrechen";
  snip_confirm_label_ = L"\u2713 Live-OCR starten (Enter)";
  snip_cancel_label_ = L"Abbrechen";
  if (args) {
    const std::string hint_utf8 = GetStringArg(*args, "hintLabel", "");
    const std::string confirm_utf8 = GetStringArg(*args, "confirmLabel", "");
    const std::string cancel_utf8 = GetStringArg(*args, "cancelLabel", "");
    if (!hint_utf8.empty()) snip_hint_label_ = Utf8ToWide(hint_utf8);
    if (!confirm_utf8.empty()) snip_confirm_label_ = Utf8ToWide(confirm_utf8);
    if (!cancel_utf8.empty()) snip_cancel_label_ = Utf8ToWide(cancel_utf8);
  }

  QueryVirtualScreenBounds(&virtual_x_, &virtual_y_, &virtual_w_, &virtual_h_);
  if (virtual_w_ <= 0 || virtual_h_ <= 0) {
    result->Success(flutter::EncodableValue());
    return;
  }

  HDC screen_dc = GetDC(nullptr);
  if (!screen_dc) {
    result->Success(flutter::EncodableValue());
    return;
  }

  BITMAPINFO bmi{};
  bmi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
  bmi.bmiHeader.biWidth = virtual_w_;
  bmi.bmiHeader.biHeight = -virtual_h_;  // top-down
  bmi.bmiHeader.biPlanes = 1;
  bmi.bmiHeader.biBitCount = 32;
  bmi.bmiHeader.biCompression = BI_RGB;

  void* bright_bits = nullptr;
  void* dimmed_bits = nullptr;
  snip_bright_bmp_ = CreateDIBSection(screen_dc, &bmi, DIB_RGB_COLORS,
                                      &bright_bits, nullptr, 0);
  snip_dimmed_bmp_ = CreateDIBSection(screen_dc, &bmi, DIB_RGB_COLORS,
                                      &dimmed_bits, nullptr, 0);

  if (!snip_bright_bmp_ || !snip_dimmed_bmp_ || !bright_bits || !dimmed_bits) {
    ReleaseDC(nullptr, screen_dc);
    CleanupSnippingOverlay();
    result->Success(flutter::EncodableValue());
    return;
  }

  HDC mem_dc = CreateCompatibleDC(screen_dc);
  HGDIOBJ old_obj = SelectObject(mem_dc, snip_bright_bmp_);
  BitBlt(mem_dc, 0, 0, virtual_w_, virtual_h_, screen_dc, virtual_x_,
         virtual_y_, SRCCOPY | CAPTUREBLT);
  SelectObject(mem_dc, old_obj);
  DeleteDC(mem_dc);
  ReleaseDC(nullptr, screen_dc);

  // Fast 50% darken pass for dimmed background copy
  const size_t pixel_count =
      static_cast<size_t>(virtual_w_) * static_cast<size_t>(virtual_h_);
  const auto* src_px = static_cast<const uint32_t*>(bright_bits);
  auto* dst_px = static_cast<uint32_t*>(dimmed_bits);
  for (size_t i = 0; i < pixel_count; ++i) {
    const uint32_t px = src_px[i];
    dst_px[i] = ((px & 0xFEFEFEFEu) >> 1) | 0xFF000000u;
  }

  snip_is_dragging_ = false;
  snip_has_selection_ = false;
  snip_start_ = {0, 0};
  snip_end_ = {0, 0};
  SetRectEmpty(&snip_confirm_btn_);
  SetRectEmpty(&snip_cancel_btn_);

  pending_snip_result_ = std::move(result);

  snip_hwnd_ = CreateWindowExW(
      WS_EX_TOPMOST | WS_EX_TOOLWINDOW, kSnipOverlayClassName,
      L"Pok\u00E9Vault Desktop Snipping", WS_POPUP, virtual_x_, virtual_y_,
      virtual_w_, virtual_h_, nullptr, nullptr, GetModuleHandleW(nullptr),
      this);

  if (!snip_hwnd_) {
    CleanupSnippingOverlay();
    if (pending_snip_result_) {
      pending_snip_result_->Success(flutter::EncodableValue());
      pending_snip_result_.reset();
    }
    return;
  }

  ShowWindow(snip_hwnd_, SW_SHOW);
  SetForegroundWindow(snip_hwnd_);
  SetFocus(snip_hwnd_);
}

void DesktopTrackerPlugin::CleanupSnippingOverlay() {
  if (snip_hwnd_) {
    DestroyWindow(snip_hwnd_);
    snip_hwnd_ = nullptr;
  }
  if (snip_bright_bmp_) {
    DeleteObject(snip_bright_bmp_);
    snip_bright_bmp_ = nullptr;
  }
  if (snip_dimmed_bmp_) {
    DeleteObject(snip_dimmed_bmp_);
    snip_dimmed_bmp_ = nullptr;
  }
  snip_is_dragging_ = false;
  snip_has_selection_ = false;
}

RECT DesktopTrackerPlugin::GetNormalizedSelection() const {
  RECT r{};
  r.left = min(snip_start_.x, snip_end_.x);
  r.top = min(snip_start_.y, snip_end_.y);
  r.right = max(snip_start_.x, snip_end_.x);
  r.bottom = max(snip_start_.y, snip_end_.y);
  return r;
}

bool DesktopTrackerPlugin::EncodeHbitmapRectToPng(
    HBITMAP source_bmp,
    int src_x,
    int src_y,
    int width,
    int height,
    std::vector<uint8_t>* out_png) {
  if (!source_bmp || !out_png || width <= 0 || height <= 0) return false;

  HDC screen_dc = GetDC(nullptr);
  HDC src_dc = CreateCompatibleDC(screen_dc);
  HDC dst_dc = CreateCompatibleDC(screen_dc);

  HBITMAP crop_bmp = CreateCompatibleBitmap(screen_dc, width, height);
  if (!crop_bmp) {
    DeleteDC(src_dc);
    DeleteDC(dst_dc);
    ReleaseDC(nullptr, screen_dc);
    return false;
  }

  HGDIOBJ old_src = SelectObject(src_dc, source_bmp);
  HGDIOBJ old_dst = SelectObject(dst_dc, crop_bmp);
  BitBlt(dst_dc, 0, 0, width, height, src_dc, src_x, src_y, SRCCOPY);
  SelectObject(src_dc, old_src);
  SelectObject(dst_dc, old_dst);
  DeleteDC(src_dc);
  DeleteDC(dst_dc);
  ReleaseDC(nullptr, screen_dc);

  CLSID png_clsid{};
  if (!GetEncoderClsid(L"image/png", &png_clsid)) {
    DeleteObject(crop_bmp);
    return false;
  }

  IStream* stream = nullptr;
  if (FAILED(CreateStreamOnHGlobal(nullptr, TRUE, &stream)) || !stream) {
    DeleteObject(crop_bmp);
    return false;
  }

  bool ok = false;
  {
    Gdiplus::Bitmap gdip_bmp(crop_bmp, nullptr);
    if (gdip_bmp.GetLastStatus() == Gdiplus::Ok &&
        gdip_bmp.Save(stream, &png_clsid, nullptr) == Gdiplus::Ok) {
      STATSTG stat{};
      if (SUCCEEDED(stream->Stat(&stat, STATFLAG_NONAME)) &&
          stat.cbSize.QuadPart > 0) {
        LARGE_INTEGER zero{};
        stream->Seek(zero, STREAM_SEEK_SET, nullptr);
        out_png->resize(static_cast<size_t>(stat.cbSize.QuadPart));
        ULONG bytes_read = 0;
        if (SUCCEEDED(stream->Read(out_png->data(),
                                   static_cast<ULONG>(out_png->size()),
                                   &bytes_read))) {
          out_png->resize(bytes_read);
          ok = !out_png->empty();
        }
      }
    }
  }

  stream->Release();
  DeleteObject(crop_bmp);
  return ok;
}

void DesktopTrackerPlugin::FinishSnipping(bool confirm) {
  if (!pending_snip_result_) {
    CleanupSnippingOverlay();
    return;
  }

  auto result = std::move(pending_snip_result_);

  if (!confirm || !snip_has_selection_) {
    CleanupSnippingOverlay();
    result->Success(flutter::EncodableValue());
    return;
  }

  RECT sel = GetNormalizedSelection();
  const int w = sel.right - sel.left;
  const int h = sel.bottom - sel.top;
  if (w < 10 || h < 10) {
    CleanupSnippingOverlay();
    result->Success(flutter::EncodableValue());
    return;
  }

  std::vector<uint8_t> preview_png;
  EncodeHbitmapRectToPng(snip_bright_bmp_, sel.left, sel.top, w, h,
                         &preview_png);

  const double abs_x = static_cast<double>(virtual_x_ + sel.left);
  const double abs_y = static_cast<double>(virtual_y_ + sel.top);

  CleanupSnippingOverlay();

  flutter::EncodableMap payload;
  payload[flutter::EncodableValue("x")] = flutter::EncodableValue(abs_x);
  payload[flutter::EncodableValue("y")] = flutter::EncodableValue(abs_y);
  payload[flutter::EncodableValue("width")] =
      flutter::EncodableValue(static_cast<double>(w));
  payload[flutter::EncodableValue("height")] =
      flutter::EncodableValue(static_cast<double>(h));
  if (!preview_png.empty()) {
    payload[flutter::EncodableValue("previewPng")] =
        flutter::EncodableValue(std::move(preview_png));
  }

  result->Success(flutter::EncodableValue(std::move(payload)));
}

void DesktopTrackerPlugin::PaintSnippingOverlay(HWND hwnd) {
  PAINTSTRUCT ps{};
  HDC hdc = BeginPaint(hwnd, &ps);
  if (!hdc) return;

  HDC back_dc = CreateCompatibleDC(hdc);
  HBITMAP back_bmp = CreateCompatibleBitmap(hdc, virtual_w_, virtual_h_);
  HGDIOBJ old_back = SelectObject(back_dc, back_bmp);

  HDC img_dc = CreateCompatibleDC(hdc);
  HGDIOBJ old_img = SelectObject(img_dc, snip_dimmed_bmp_);
  BitBlt(back_dc, 0, 0, virtual_w_, virtual_h_, img_dc, 0, 0, SRCCOPY);

  RECT sel = GetNormalizedSelection();
  const int sel_w = sel.right - sel.left;
  const int sel_h = sel.bottom - sel.top;
  const bool valid_sel =
      (snip_is_dragging_ || snip_has_selection_) && sel_w >= 6 && sel_h >= 6;

  if (valid_sel) {
    // Draw crisp bright cutout inside selection
    SelectObject(img_dc, snip_bright_bmp_);
    BitBlt(back_dc, sel.left, sel.top, sel_w, sel_h, img_dc, sel.left, sel.top,
           SRCCOPY);
  }

  SelectObject(img_dc, old_img);
  DeleteDC(img_dc);

  // Use GDI+ on back_dc for clean pills, borders, and crisp text
  {
    Gdiplus::Graphics g(back_dc);
    g.SetSmoothingMode(Gdiplus::SmoothingModeAntiAlias);
    g.SetTextRenderingHint(Gdiplus::TextRenderingHintClearTypeGridFit);

    Gdiplus::FontFamily font_family(L"Segoe UI");
    Gdiplus::Font font_bold(&font_family, 12.0f, Gdiplus::FontStyleBold,
                            Gdiplus::UnitPixel);
    Gdiplus::Font font_mono(&font_family, 11.0f, Gdiplus::FontStyleBold,
                            Gdiplus::UnitPixel);
    Gdiplus::SolidBrush white_brush(Gdiplus::Color(255, 255, 255, 255));
    Gdiplus::SolidBrush pill_bg(Gdiplus::Color(230, 24, 25, 38));
    Gdiplus::Pen pill_border(Gdiplus::Color(220, 62, 66, 98), 1.0f);

    // Top instruction banner on primary monitor
    HMONITOR primary_mon =
        MonitorFromPoint(POINT{0, 0}, MONITOR_DEFAULTTOPRIMARY);
    MONITORINFO mi{};
    mi.cbSize = sizeof(mi);
    GetMonitorInfoW(primary_mon, &mi);
    const int mon_left = mi.rcWork.left - virtual_x_;
    const int mon_top = mi.rcWork.top - virtual_y_;
    const int mon_w = mi.rcWork.right - mi.rcWork.left;

    const int banner_w = 620;
    const int banner_h = 34;
    const int banner_x = mon_left + (mon_w - banner_w) / 2;
    const int banner_y = mon_top + 16;

    Gdiplus::GraphicsPath banner_path;
    banner_path.AddRectangle(Gdiplus::Rect(banner_x, banner_y, banner_w, banner_h));
    g.FillRectangle(&pill_bg, banner_x, banner_y, banner_w, banner_h);
    g.DrawRectangle(&pill_border, banner_x, banner_y, banner_w, banner_h);

    Gdiplus::StringFormat sf;
    sf.SetAlignment(Gdiplus::StringAlignmentCenter);
    sf.SetLineAlignment(Gdiplus::StringAlignmentCenter);
    g.DrawString(
        snip_hint_label_.c_str(),
        -1, &font_bold,
        Gdiplus::RectF(static_cast<float>(banner_x),
                       static_cast<float>(banner_y),
                       static_cast<float>(banner_w),
                       static_cast<float>(banner_h)),
        &sf, &white_brush);

    SetRectEmpty(&snip_confirm_btn_);
    SetRectEmpty(&snip_cancel_btn_);

    if (valid_sel) {
      Gdiplus::Pen blue_pen(Gdiplus::Color(255, 59, 130, 246), 2.0f);
      g.DrawRectangle(&blue_pen, sel.left, sel.top, sel_w, sel_h);

      // Coordinate badge
      wchar_t badge_txt[96]{};
      swprintf_s(badge_txt, L"%d \u00D7 %d px  @ (%d, %d)", sel_w, sel_h,
                 virtual_x_ + sel.left, virtual_y_ + sel.top);
      const int badge_w = 200;
      const int badge_h = 24;
      const int badge_x = sel.left;
      const int badge_y =
          (sel.top - badge_h - 6 >= 0) ? (sel.top - badge_h - 6) : (sel.top + 6);
      g.FillRectangle(&pill_bg, badge_x, badge_y, badge_w, badge_h);
      Gdiplus::SolidBrush blue_txt(Gdiplus::Color(255, 147, 197, 253));
      g.DrawString(badge_txt, -1, &font_mono,
                   Gdiplus::RectF(static_cast<float>(badge_x),
                                  static_cast<float>(badge_y),
                                  static_cast<float>(badge_w),
                                  static_cast<float>(badge_h)),
                   &sf, &blue_txt);

      // Show Confirm / Cancel buttons after mouse release
      if (!snip_is_dragging_ && snip_has_selection_) {
        const int btn_y = (sel.bottom + 42 < virtual_h_)
                              ? (sel.bottom + 8)
                              : max(4, static_cast<int>(sel.top - 38));
        const int confirm_w = 178;
        const int cancel_w = 96;
        const int btn_h = 30;
        const int confirm_x =
            min(max(4, static_cast<int>(sel.left)),
                virtual_w_ - confirm_w - cancel_w - 16);
        const int cancel_x = confirm_x + confirm_w + 8;

        snip_confirm_btn_ = {confirm_x, btn_y, confirm_x + confirm_w,
                             btn_y + btn_h};
        snip_cancel_btn_ = {cancel_x, btn_y, cancel_x + cancel_w,
                            btn_y + btn_h};

        Gdiplus::SolidBrush confirm_bg(Gdiplus::Color(255, 37, 99, 235));
        g.FillRectangle(&confirm_bg, confirm_x, btn_y, confirm_w, btn_h);
        g.DrawString(
            snip_confirm_label_.c_str(), -1, &font_bold,
            Gdiplus::RectF(static_cast<float>(confirm_x),
                           static_cast<float>(btn_y),
                           static_cast<float>(confirm_w),
                           static_cast<float>(btn_h)),
            &sf, &white_brush);

        g.FillRectangle(&pill_bg, cancel_x, btn_y, cancel_w, btn_h);
        g.DrawRectangle(&pill_border, cancel_x, btn_y, cancel_w, btn_h);
        g.DrawString(
            snip_cancel_label_.c_str(), -1, &font_bold,
            Gdiplus::RectF(static_cast<float>(cancel_x),
                           static_cast<float>(btn_y),
                           static_cast<float>(cancel_w),
                           static_cast<float>(btn_h)),
            &sf, &white_brush);
      }
    }
  }

  BitBlt(hdc, 0, 0, virtual_w_, virtual_h_, back_dc, 0, 0, SRCCOPY);
  SelectObject(back_dc, old_back);
  DeleteObject(back_bmp);
  DeleteDC(back_dc);
  EndPaint(hwnd, &ps);
}

namespace {

bool CaptureRegionRaw(int x,
                      int y,
                      int width,
                      int height,
                      std::vector<uint8_t>* out_bytes,
                      std::string* out_method) {
  if (!out_bytes || width <= 0 || height <= 0) return false;

  HDC screen_dc = GetDC(nullptr);
  if (!screen_dc) return false;

  BITMAPINFO bmi{};
  bmi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
  bmi.bmiHeader.biWidth = width;
  bmi.bmiHeader.biHeight = -height;  // top-down BGRA
  bmi.bmiHeader.biPlanes = 1;
  bmi.bmiHeader.biBitCount = 32;
  bmi.bmiHeader.biCompression = BI_RGB;

  void* bits = nullptr;
  HBITMAP dib =
      CreateDIBSection(screen_dc, &bmi, DIB_RGB_COLORS, &bits, nullptr, 0);
  if (!dib || !bits) {
    if (dib) DeleteObject(dib);
    ReleaseDC(nullptr, screen_dc);
    return false;
  }

  HDC mem_dc = CreateCompatibleDC(screen_dc);
  HGDIOBJ old_obj = SelectObject(mem_dc, dib);
  BOOL copied = BitBlt(mem_dc, 0, 0, width, height, screen_dc, x, y,
                       SRCCOPY | CAPTUREBLT);
  SelectObject(mem_dc, old_obj);
  DeleteDC(mem_dc);
  ReleaseDC(nullptr, screen_dc);

  if (!copied) {
    DeleteObject(dib);
    return false;
  }

  const size_t byte_count =
      static_cast<size_t>(width) * static_cast<size_t>(height) * 4;
  out_bytes->resize(byte_count);
  std::memcpy(out_bytes->data(), bits, byte_count);
  DeleteObject(dib);
  if (out_method) *out_method = "bitblt_screen";
  return true;
}

template <typename CacheT>
bool CaptureWindowRaw(CacheT* cache,
                      int64_t hwnd_val,
                      bool has_crop,
                      int crop_x_in,
                      int crop_y_in,
                      int crop_w_in,
                      int crop_h_in,
                      std::vector<uint8_t>* out_bytes,
                      int* out_w,
                      int* out_h,
                      std::string* out_method) {
  if (!cache || !out_bytes || hwnd_val == 0) {
    if (cache) {
      cache->bgra_bytes.clear();
      cache->hwnd = nullptr;
    }
    return false;
  }
  HWND target = reinterpret_cast<HWND>(hwnd_val);
  if (!IsWindow(target) || IsIconic(target)) {
    cache->bgra_bytes.clear();
    cache->hwnd = nullptr;
    return false;
  }

  RECT win_rect{};
  if (!GetWindowRect(target, &win_rect)) {
    cache->bgra_bytes.clear();
    cache->hwnd = nullptr;
    return false;
  }

  const int full_w = win_rect.right - win_rect.left;
  const int full_h = win_rect.bottom - win_rect.top;
  if (full_w <= 0 || full_h <= 0) {
    cache->bgra_bytes.clear();
    cache->hwnd = nullptr;
    return false;
  }

  int crop_x = 0;
  int crop_y = 0;
  int crop_w = full_w;
  int crop_h = full_h;
  if (has_crop) {
    crop_x = (std::max)(0, crop_x_in);
    crop_y = (std::max)(0, crop_y_in);
    crop_w = (std::min)(crop_w_in, full_w - crop_x);
    crop_h = (std::min)(crop_h_in, full_h - crop_y);
  }
  if (crop_w <= 0 || crop_h <= 0) {
    return false;
  }

  const size_t full_bytes_len =
      static_cast<size_t>(full_w) * static_cast<size_t>(full_h) * 4;
  const auto now = std::chrono::steady_clock::now();
  const bool cache_hit =
      cache->hwnd == target &&
      cache->width == full_w &&
      cache->height == full_h &&
      cache->bgra_bytes.size() == full_bytes_len &&
      (now - cache->captured_at) <= std::chrono::milliseconds(60);

  std::string capture_method;
  const uint8_t* src_bytes = nullptr;

  if (cache_hit) {
    capture_method = cache->capture_method;
    src_bytes = cache->bgra_bytes.data();
  } else {
    HDC screen_dc = GetDC(nullptr);
    if (!screen_dc) return false;

    BITMAPINFO full_bmi{};
    full_bmi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    full_bmi.bmiHeader.biWidth = full_w;
    full_bmi.bmiHeader.biHeight = -full_h;
    full_bmi.bmiHeader.biPlanes = 1;
    full_bmi.bmiHeader.biBitCount = 32;
    full_bmi.bmiHeader.biCompression = BI_RGB;

    void* full_bits = nullptr;
    HBITMAP full_dib = CreateDIBSection(screen_dc, &full_bmi, DIB_RGB_COLORS,
                                        &full_bits, nullptr, 0);
    if (!full_dib || !full_bits) {
      if (full_dib) DeleteObject(full_dib);
      ReleaseDC(nullptr, screen_dc);
      cache->bgra_bytes.clear();
      cache->hwnd = nullptr;
      return false;
    }

    HDC full_dc = CreateCompatibleDC(screen_dc);
    HGDIOBJ old_full = SelectObject(full_dc, full_dib);

    capture_method = "printwindow_pw2";
    BOOL printed = PrintWindow(target, full_dc, 2);
    if (!printed) {
      capture_method = "bitblt_fallback";
      printed = BitBlt(full_dc, 0, 0, full_w, full_h, screen_dc, win_rect.left,
                       win_rect.top, SRCCOPY | CAPTUREBLT);
    }

    if (!printed) {
      SelectObject(full_dc, old_full);
      DeleteDC(full_dc);
      DeleteObject(full_dib);
      ReleaseDC(nullptr, screen_dc);
      cache->bgra_bytes.clear();
      cache->hwnd = nullptr;
      return false;
    }

    cache->hwnd = target;
    cache->width = full_w;
    cache->height = full_h;
    cache->capture_method = capture_method;
    cache->captured_at = now;
    cache->bgra_bytes.resize(full_bytes_len);
    std::memcpy(cache->bgra_bytes.data(), full_bits, full_bytes_len);

    SelectObject(full_dc, old_full);
    DeleteDC(full_dc);
    DeleteObject(full_dib);
    ReleaseDC(nullptr, screen_dc);

    src_bytes = cache->bgra_bytes.data();
  }

  const size_t out_bytes_len =
      static_cast<size_t>(crop_w) * static_cast<size_t>(crop_h) * 4;
  out_bytes->resize(out_bytes_len);

  const size_t src_stride = static_cast<size_t>(full_w) * 4;
  const size_t dst_stride = static_cast<size_t>(crop_w) * 4;
  for (int row = 0; row < crop_h; ++row) {
    const size_t src_off =
        static_cast<size_t>(crop_y + row) * src_stride +
        static_cast<size_t>(crop_x) * 4;
    std::memcpy(out_bytes->data() + static_cast<size_t>(row) * dst_stride,
                src_bytes + src_off, dst_stride);
  }

  if (out_w) *out_w = crop_w;
  if (out_h) *out_h = crop_h;
  if (out_method) *out_method = capture_method;
  return true;
}

}  // namespace

void DesktopTrackerPlugin::CaptureRegionAsync(
    const flutter::EncodableMap& args,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const int x = static_cast<int>(std::lround(GetDoubleArg(args, "x", 0.0)));
  const int y = static_cast<int>(std::lround(GetDoubleArg(args, "y", 0.0)));
  const int width =
      static_cast<int>(std::lround(GetDoubleArg(args, "width", 0.0)));
  const int height =
      static_cast<int>(std::lround(GetDoubleArg(args, "height", 0.0)));

  if (width <= 0 || height <= 0) {
    result->Success(flutter::EncodableValue());
    return;
  }

  auto* payload = new CaptureAsyncPayload();
  payload->result = std::move(result);
  {
    std::lock_guard<std::mutex> lock(ocr_queue_mutex_);
    if (ocr_worker_stopping_) {
      payload->result.release();
      delete payload;
      return;
    }
    WorkerTask task;
    task.type = WorkerTask::Type::kCaptureRegion;
    task.cap_x = x;
    task.cap_y = y;
    task.cap_w = width;
    task.cap_h = height;
    task.capture_payload = payload;
    ocr_queue_.push(std::move(task));
  }
  ocr_queue_cv_.notify_one();
}

void DesktopTrackerPlugin::CaptureWindowAsync(
    const flutter::EncodableMap& args,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const int64_t hwnd_val = GetInt64Arg(args, "hwnd", 0);
  if (hwnd_val == 0) {
    result->Success(flutter::EncodableValue());
    return;
  }

  bool has_crop = false;
  int crop_x = 0, crop_y = 0, crop_w = 0, crop_h = 0;
  auto crop_it = args.find(flutter::EncodableValue("cropRegion"));
  if (crop_it != args.end() &&
      std::holds_alternative<flutter::EncodableMap>(crop_it->second)) {
    const auto& cmap = std::get<flutter::EncodableMap>(crop_it->second);
    has_crop = true;
    crop_x = static_cast<int>(std::lround(GetDoubleArg(cmap, "x", 0.0)));
    crop_y = static_cast<int>(std::lround(GetDoubleArg(cmap, "y", 0.0)));
    crop_w = static_cast<int>(std::lround(GetDoubleArg(cmap, "width", 0.0)));
    crop_h = static_cast<int>(std::lround(GetDoubleArg(cmap, "height", 0.0)));
  }

  auto* payload = new CaptureAsyncPayload();
  payload->result = std::move(result);
  {
    std::lock_guard<std::mutex> lock(ocr_queue_mutex_);
    if (ocr_worker_stopping_) {
      payload->result.release();
      delete payload;
      return;
    }
    WorkerTask task;
    task.type = WorkerTask::Type::kCaptureWindow;
    task.hwnd_val = hwnd_val;
    task.has_crop = has_crop;
    task.crop_x = crop_x;
    task.crop_y = crop_y;
    task.crop_w = crop_w;
    task.crop_h = crop_h;
    task.capture_payload = payload;
    ocr_queue_.push(std::move(task));
  }
  ocr_queue_cv_.notify_one();
}

void DesktopTrackerPlugin::CaptureAndAnalyzeAsync(
    const flutter::EncodableMap& args,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const std::string mode = GetStringArg(args, "mode", "window");
  const std::string slot_key = GetStringArg(args, "slotKey", "zoneA");
  const std::string language_tag = GetStringArg(args, "languageTag", "");
  const std::string preprocess_profile =
      GetStringArg(args, "preprocessProfile", "standard");
  const bool force_ocr = GetBoolArg(args, "forceOcr", false);
  const bool mask_self_window = GetBoolArg(args, "maskSelfWindow", false);
  const bool compute_color_histogram =
      GetBoolArg(args, "computeColorHistogram", false);
  const bool include_thumbnail = GetBoolArg(args, "includeThumbnail", false);
  const int thumbnail_max_width =
      static_cast<int>(GetInt64Arg(args, "thumbnailMaxWidth", 320));
  const bool multi_band_fallback = GetBoolArg(args, "multiBandFallback", false);

  bool is_region = (mode == "region");
  int cap_x = 0, cap_y = 0, cap_w = 0, cap_h = 0;
  if (is_region) {
    auto reg_it = args.find(flutter::EncodableValue("screenRegion"));
    if (reg_it != args.end() &&
        std::holds_alternative<flutter::EncodableMap>(reg_it->second)) {
      const auto& rmap = std::get<flutter::EncodableMap>(reg_it->second);
      cap_x = static_cast<int>(std::lround(GetDoubleArg(rmap, "x", 0.0)));
      cap_y = static_cast<int>(std::lround(GetDoubleArg(rmap, "y", 0.0)));
      cap_w = static_cast<int>(std::lround(GetDoubleArg(rmap, "width", 0.0)));
      cap_h = static_cast<int>(std::lround(GetDoubleArg(rmap, "height", 0.0)));
    }
  }

  const int64_t hwnd_val = GetInt64Arg(args, "hwnd", 0);
  bool has_crop = false;
  int crop_x = 0, crop_y = 0, crop_w = 0, crop_h = 0;
  auto crop_it = args.find(flutter::EncodableValue("cropRegion"));
  if (crop_it != args.end() &&
      std::holds_alternative<flutter::EncodableMap>(crop_it->second)) {
    const auto& cmap = std::get<flutter::EncodableMap>(crop_it->second);
    has_crop = true;
    crop_x = static_cast<int>(std::lround(GetDoubleArg(cmap, "x", 0.0)));
    crop_y = static_cast<int>(std::lround(GetDoubleArg(cmap, "y", 0.0)));
    crop_w = static_cast<int>(std::lround(GetDoubleArg(cmap, "width", 0.0)));
    crop_h = static_cast<int>(std::lround(GetDoubleArg(cmap, "height", 0.0)));
  }

  auto* payload = new CaptureAnalyzePayload();
  payload->result = std::move(result);
  payload->requested_language_tag = language_tag;
  payload->resolved_language_tag = language_tag;

  {
    std::lock_guard<std::mutex> lock(ocr_queue_mutex_);
    if (ocr_worker_stopping_) {
      payload->result.release();
      delete payload;
      return;
    }
    WorkerTask task;
    task.type = WorkerTask::Type::kCaptureAnalyze;
    task.is_region = is_region;
    task.cap_x = cap_x;
    task.cap_y = cap_y;
    task.cap_w = cap_w;
    task.cap_h = cap_h;
    task.hwnd_val = hwnd_val;
    task.has_crop = has_crop;
    task.crop_x = crop_x;
    task.crop_y = crop_y;
    task.crop_w = crop_w;
    task.crop_h = crop_h;
    task.slot_key = slot_key;
    task.force_ocr = force_ocr;
    task.language_tag = language_tag;
    task.preprocess_profile = preprocess_profile;
    task.mask_self_window = mask_self_window;
    task.compute_color_histogram = compute_color_histogram;
    task.include_thumbnail = include_thumbnail;
    task.thumbnail_max_width = thumbnail_max_width;
    task.multi_band_fallback = multi_band_fallback;
    task.analyze_payload = payload;
    ocr_queue_.push(std::move(task));
  }
  ocr_queue_cv_.notify_one();
}

void DesktopTrackerPlugin::ClearScanCacheAsync() {
  {
    std::lock_guard<std::mutex> lock(ocr_queue_mutex_);
    if (ocr_worker_stopping_) return;
    WorkerTask task;
    task.type = WorkerTask::Type::kClearScanCache;
    ocr_queue_.push(std::move(task));
  }
  ocr_queue_cv_.notify_one();
}

void DesktopTrackerPlugin::OcrWorkerLoop() {
  SetThreadDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
  HRESULT ro_hr = RoInitialize(RO_INIT_MULTITHREADED);
  OcrRuntimeCache runtime_cache;
  HWND notify_hwnd = dispatcher_hwnd_;
  HWND main_hwnd = main_window_hwnd_;
  auto alive = alive_flag_;

  while (true) {
    WorkerTask task;
    {
      std::unique_lock<std::mutex> lock(ocr_queue_mutex_);
      ocr_queue_cv_.wait(lock, [this]() {
        return ocr_worker_stopping_ || !ocr_queue_.empty();
      });
      if (ocr_worker_stopping_) {
        break;
      }
      task = std::move(ocr_queue_.front());
      ocr_queue_.pop();
    }

    if (task.type == WorkerTask::Type::kClearScanCache) {
      slot_fingerprints_.clear();
      window_capture_cache_.bgra_bytes.clear();
      window_capture_cache_.hwnd = nullptr;
      continue;
    }

    if (task.type == WorkerTask::Type::kOcr) {
      if (!task.ocr_payload) continue;
      const auto t0 = std::chrono::steady_clock::now();
      task.ocr_payload->success = RunWindowsMediaOcrCached(
          &runtime_cache, ocr_stop_event_, task.bytes, task.width, task.height,
          task.language_tag, task.preprocess_profile, &task.ocr_payload->lines,
          &task.ocr_payload->used_fallback_language,
          &task.ocr_payload->resolved_language_tag,
          &task.ocr_payload->available_languages,
          &task.ocr_payload->error_hint);
      const auto t1 = std::chrono::steady_clock::now();
      task.ocr_payload->ocr_duration_ms =
          std::chrono::duration_cast<std::chrono::milliseconds>(t1 - t0).count();

      if (!alive || !alive->load() ||
          !PostMessageW(notify_hwnd, kMsgOcrComplete, 0,
                        reinterpret_cast<LPARAM>(task.ocr_payload))) {
        if (!alive || !alive->load()) {
          task.ocr_payload->result.release();
        }
        delete task.ocr_payload;
      }
      continue;
    }

    if (task.type == WorkerTask::Type::kCaptureRegion ||
        task.type == WorkerTask::Type::kCaptureWindow) {
      if (!task.capture_payload) continue;
      if (task.type == WorkerTask::Type::kCaptureRegion) {
        task.capture_payload->success = CaptureRegionRaw(
            task.cap_x, task.cap_y, task.cap_w, task.cap_h,
            &task.capture_payload->bytes,
            &task.capture_payload->capture_method);
        if (task.capture_payload->success) {
          task.capture_payload->width = task.cap_w;
          task.capture_payload->height = task.cap_h;
        }
      } else {
        task.capture_payload->success = CaptureWindowRaw(
            &window_capture_cache_, task.hwnd_val, task.has_crop, task.crop_x,
            task.crop_y, task.crop_w, task.crop_h, &task.capture_payload->bytes,
            &task.capture_payload->width, &task.capture_payload->height,
            &task.capture_payload->capture_method);
      }

      if (!alive || !alive->load() ||
          !PostMessageW(notify_hwnd, kMsgCaptureComplete, 0,
                        reinterpret_cast<LPARAM>(task.capture_payload))) {
        if (!alive || !alive->load()) {
          task.capture_payload->result.release();
        }
        delete task.capture_payload;
      }
      continue;
    }

    if (task.type == WorkerTask::Type::kCaptureAnalyze) {
      if (!task.analyze_payload) continue;
      auto* p = task.analyze_payload;

      const auto cap_t0 = std::chrono::steady_clock::now();
      std::vector<uint8_t> frame_bytes;
      int frame_w = 0;
      int frame_h = 0;
      std::string cap_method;
      bool cap_ok = false;

      if (task.is_region) {
        cap_ok = CaptureRegionRaw(task.cap_x, task.cap_y, task.cap_w, task.cap_h,
                                  &frame_bytes, &cap_method);
        if (cap_ok) {
          frame_w = task.cap_w;
          frame_h = task.cap_h;
        }
      } else {
        cap_ok = CaptureWindowRaw(
            &window_capture_cache_, task.hwnd_val, task.has_crop, task.crop_x,
            task.crop_y, task.crop_w, task.crop_h, &frame_bytes, &frame_w,
            &frame_h, &cap_method);
      }
      const auto cap_t1 = std::chrono::steady_clock::now();
      p->capture_duration_ms =
          std::chrono::duration_cast<std::chrono::milliseconds>(cap_t1 - cap_t0)
              .count();

      if (cap_ok && frame_w > 0 && frame_h > 0) {
        p->captured = true;
        p->frame_width = frame_w;
        p->frame_height = frame_h;
        p->capture_method = cap_method;

        if (task.is_region) {
          p->self_window_overlaps = ApplySelfWindowMaskIfOverlapping(
              main_hwnd, task.cap_x, task.cap_y, frame_w, frame_h, &frame_bytes,
              task.mask_self_window);
        }

        ComputeLuminanceAndSummary(frame_bytes, frame_w, frame_h, &p->avg_luma,
                                   &p->std_dev, &p->brightness_summary);
        p->has_luma = true;

        if (task.compute_color_histogram) {
          p->has_color_histogram = ComputeColorHistogram16(
              frame_bytes, frame_w, frame_h, &p->color_histogram);
        }

        const int64_t fp =
            ComputeFrameFingerprintNative(frame_bytes, frame_w, frame_h);
        auto fp_it = slot_fingerprints_.find(task.slot_key);
        const bool changed = task.force_ocr ||
                             fp_it == slot_fingerprints_.end() ||
                             fp_it->second != fp;
        slot_fingerprints_[task.slot_key] = fp;

        if (changed) {
          p->ocr_skipped = false;
          const auto ocr_t0 = std::chrono::steady_clock::now();
          if (task.multi_band_fallback) {
            p->ocr_succeeded = RunZoneBMultiBandOcr(
                &runtime_cache, ocr_stop_event_, frame_bytes, frame_w, frame_h,
                task.language_tag, task.preprocess_profile, &p->lines,
                &p->used_fallback_language, &p->resolved_language_tag,
                &p->available_languages, &p->error_hint);
          } else {
            p->ocr_succeeded = RunWindowsMediaOcrCached(
                &runtime_cache, ocr_stop_event_, frame_bytes, frame_w, frame_h,
                task.language_tag, task.preprocess_profile, &p->lines,
                &p->used_fallback_language, &p->resolved_language_tag,
                &p->available_languages, &p->error_hint);
          }
          const auto ocr_t1 = std::chrono::steady_clock::now();
          p->ocr_duration_ms =
              std::chrono::duration_cast<std::chrono::milliseconds>(ocr_t1 -
                                                                    ocr_t0)
                  .count();
        } else {
          p->ocr_skipped = true;
          p->ocr_succeeded = true;
        }

        if (task.include_thumbnail) {
          EncodeDownscaledThumbnailPng(
              frame_bytes, frame_w, frame_h, task.thumbnail_max_width,
              &p->thumbnail_png, &p->thumbnail_width, &p->thumbnail_height);
        }
      } else {
        p->captured = false;
        p->ocr_skipped = true;
        p->ocr_succeeded = false;
        p->error_hint = "Capture failed or window unavailable";
      }

      if (!alive || !alive->load() ||
          !PostMessageW(notify_hwnd, kMsgCaptureAnalyzeComplete, 0,
                        reinterpret_cast<LPARAM>(p))) {
        if (!alive || !alive->load()) {
          p->result.release();
        }
        delete p;
      }
    }
  }

  runtime_cache.Reset();
  if (SUCCEEDED(ro_hr)) {
    RoUninitialize();
  }
}

void DesktopTrackerPlugin::RecognizeTextAsync(
    const flutter::EncodableMap& args,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const int width =
      static_cast<int>(GetInt64Arg(args, "width", 0));
  const int height =
      static_cast<int>(GetInt64Arg(args, "height", 0));
  const std::string language_tag = GetStringArg(args, "languageTag", "");
  const std::string preprocess_profile =
      GetStringArg(args, "preprocessProfile", "standard");

  auto bytes_it = args.find(flutter::EncodableValue("bytes"));
  if (bytes_it == args.end() ||
      !std::holds_alternative<std::vector<uint8_t>>(bytes_it->second) ||
      width <= 0 || height <= 0) {
    flutter::EncodableMap empty;
    empty[flutter::EncodableValue("lines")] =
        flutter::EncodableValue(flutter::EncodableList{});
    empty[flutter::EncodableValue("usedFallbackLanguage")] =
        flutter::EncodableValue(false);
    empty[flutter::EncodableValue("resolvedLanguageTag")] =
        flutter::EncodableValue(language_tag);
    empty[flutter::EncodableValue("requestedLanguageTag")] =
        flutter::EncodableValue(language_tag);
    empty[flutter::EncodableValue("availableLanguages")] =
        flutter::EncodableValue(flutter::EncodableList{});
    empty[flutter::EncodableValue("ocrSucceeded")] =
        flutter::EncodableValue(false);
    empty[flutter::EncodableValue("ocrDurationMs")] =
        flutter::EncodableValue(0);
    empty[flutter::EncodableValue("errorHint")] =
        flutter::EncodableValue("Invalid frame bytes or dimensions");
    result->Success(flutter::EncodableValue(std::move(empty)));
    return;
  }

  std::vector<uint8_t> bytes =
      std::get<std::vector<uint8_t>>(bytes_it->second);
  auto* payload = new OcrAsyncPayload();
  payload->result = std::move(result);
  payload->resolved_language_tag = language_tag;
  payload->requested_language_tag = language_tag;

  {
    std::lock_guard<std::mutex> lock(ocr_queue_mutex_);
    if (ocr_worker_stopping_) {
      payload->result.release();
      delete payload;
      return;
    }
    WorkerTask item;
    item.type = WorkerTask::Type::kOcr;
    item.bytes = std::move(bytes);
    item.width = width;
    item.height = height;
    item.language_tag = language_tag;
    item.preprocess_profile = preprocess_profile;
    item.ocr_payload = payload;
    ocr_queue_.push(std::move(item));
  }
  ocr_queue_cv_.notify_one();
}

void DesktopTrackerPlugin::ParseHudArgs(const flutter::EncodableMap& args) {
  hud_state_.pokemon_name =
      Utf8ToWide(GetStringArg(args, "pokemonName", "Warte auf Spiel..."));
  hud_state_.pokemon_id = static_cast<int>(GetInt64Arg(args, "pokemonId", 0));
  hud_state_.is_shiny = GetBoolArg(args, "isShiny", false);
  hud_state_.is_caught = GetBoolArg(args, "isCaught", false);
  hud_state_.is_compact = GetBoolArg(args, "isCompact", hud_state_.is_compact);
  hud_state_.is_pinned = GetBoolArg(args, "isPinned", hud_state_.is_pinned);
  hud_state_.opacity =
      std::clamp(GetDoubleArg(args, "opacity", hud_state_.opacity), 0.3, 1.0);
  hud_state_.has_event = GetBoolArg(args, "hasEvent", false);
  hud_state_.evolution_summary =
      Utf8ToWide(GetStringArg(args, "evolutionSummary", ""));
  hud_state_.has_missing_evolutions =
      GetBoolArg(args, "hasMissingEvolutions", false);
  hud_state_.instance_label =
      Utf8ToWide(GetStringArg(args, "instanceLabel", ""));
  const std::string waiting_utf8 = GetStringArg(args, "waitingLabel", "");
  if (!waiting_utf8.empty()) {
    hud_state_.waiting_label = Utf8ToWide(waiting_utf8);
  }
  const std::string caught_utf8 = GetStringArg(args, "caughtLabel", "");
  if (!caught_utf8.empty()) {
    hud_state_.caught_label = Utf8ToWide(caught_utf8);
  }
  const std::string missing_utf8 = GetStringArg(args, "missingLabel", "");
  if (!missing_utf8.empty()) {
    hud_state_.missing_label = Utf8ToWide(missing_utf8);
  }
  const std::string footer_utf8 = GetStringArg(args, "footerLabel", "");
  hud_state_.footer_label = Utf8ToWide(footer_utf8);

  hud_state_.focus_entries.clear();
  auto focus_it = args.find(flutter::EncodableValue("focusEntries"));
  if (focus_it != args.end() &&
      std::holds_alternative<flutter::EncodableList>(focus_it->second)) {
    const auto& flist = std::get<flutter::EncodableList>(focus_it->second);
    for (const auto& item : flist) {
      if (!std::holds_alternative<flutter::EncodableMap>(item)) continue;
      const auto& fmap = std::get<flutter::EncodableMap>(item);
      HudFocusEntry entry;
      entry.pokemon_id = static_cast<int>(GetInt64Arg(fmap, "pokemonId", 0));
      entry.pokemon_name =
          Utf8ToWide(GetStringArg(fmap, "pokemonName", ""));
      entry.is_shiny = GetBoolArg(fmap, "isShiny", false);
      entry.is_caught = GetBoolArg(fmap, "isCaught", false);
      entry.encounter_count =
          static_cast<int>(GetInt64Arg(fmap, "encounterCount", 1));
      if (!entry.pokemon_name.empty()) {
        hud_state_.focus_entries.push_back(std::move(entry));
        if (hud_state_.focus_entries.size() >= 5) break;
      }
    }
  }

  auto anchor_it = args.find(flutter::EncodableValue("anchorRect"));
  if (anchor_it != args.end() &&
      std::holds_alternative<flutter::EncodableMap>(anchor_it->second)) {
    const auto& amap = std::get<flutter::EncodableMap>(anchor_it->second);
    const int ax = static_cast<int>(std::lround(GetDoubleArg(amap, "x", 0.0)));
    const int ay = static_cast<int>(std::lround(GetDoubleArg(amap, "y", 0.0)));
    const int aw =
        static_cast<int>(std::lround(GetDoubleArg(amap, "width", 0.0)));
    const int ah =
        static_cast<int>(std::lround(GetDoubleArg(amap, "height", 0.0)));
    if (aw > 0 && ah > 0) {
      hud_state_.has_anchor_rect = true;
      hud_state_.anchor_rect = {ax, ay, ax + aw, ay + ah};
    }
  }
}

int DesktopTrackerPlugin::ComputeHudHeight() const {
  if (hud_state_.focus_entries.size() > 1) {
    const int count = static_cast<int>(hud_state_.focus_entries.size());
    const int footer_h = hud_state_.is_compact ? 10 : 28;
    return 36 + count * 36 + footer_h;
  }
  return hud_state_.is_compact ? kHudHeightCompact : kHudHeightNormal;
}

void DesktopTrackerPlugin::PositionHudFromAnchor() {
  const int hud_w = hud_state_.is_compact ? kHudWidthCompact : kHudWidthNormal;
  const int hud_h = ComputeHudHeight();

  int target_x = hud_state_.pos_x;
  int target_y = hud_state_.pos_y;

  if (!hud_user_moved_ && hud_state_.has_anchor_rect) {
    const RECT& a = hud_state_.anchor_rect;
    const int anchor_h = a.bottom - a.top;
    // For small snipped textboxes (<260px), hover right above the region so text stays clear;
    // for full windows, anchor inside the top-right corner.
    if (anchor_h < 260) {
      target_x = a.left;
      target_y = a.top - hud_h - 8;
    } else {
      target_x = a.right - hud_w - 14;
      target_y = a.top + 14;
    }
  }

  POINT pt{target_x, target_y};
  HMONITOR mon = MonitorFromPoint(pt, MONITOR_DEFAULTTONEAREST);
  MONITORINFO mi{};
  mi.cbSize = sizeof(mi);
  if (GetMonitorInfoW(mon, &mi)) {
    target_x =
        std::clamp(target_x, static_cast<int>(mi.rcWork.left),
                   static_cast<int>(mi.rcWork.right) - hud_w);
    target_y =
        std::clamp(target_y, static_cast<int>(mi.rcWork.top),
                   static_cast<int>(mi.rcWork.bottom) - hud_h);
  }

  hud_state_.pos_x = target_x;
  hud_state_.pos_y = target_y;
}

bool DesktopTrackerPlugin::ShowOrUpdateFloatingHud(
    const flutter::EncodableMap& args,
    bool create_if_missing) {
  ParseHudArgs(args);

  if (!hud_hwnd_) {
    if (!create_if_missing) return false;
    hud_user_moved_ = false;
    PositionHudFromAnchor();
    const int hud_w =
        hud_state_.is_compact ? kHudWidthCompact : kHudWidthNormal;
    const int hud_h = ComputeHudHeight();

    hud_hwnd_ = CreateWindowExW(
        WS_EX_TOPMOST | WS_EX_TOOLWINDOW | WS_EX_LAYERED | WS_EX_NOACTIVATE,
        kHudWindowClassName, L"Pok\u00E9Vault HUD", WS_POPUP,
        hud_state_.pos_x, hud_state_.pos_y, hud_w, hud_h, nullptr, nullptr,
        GetModuleHandleW(nullptr), this);
    if (!hud_hwnd_) return false;
    ShowWindow(hud_hwnd_, SW_SHOWNOACTIVATE);
  } else {
    PositionHudFromAnchor();
  }

  HWND z_order = hud_state_.is_pinned ? HWND_TOPMOST : HWND_NOTOPMOST;
  const int hud_w = hud_state_.is_compact ? kHudWidthCompact : kHudWidthNormal;
  const int hud_h = ComputeHudHeight();
  SetWindowPos(hud_hwnd_, z_order, hud_state_.pos_x, hud_state_.pos_y, hud_w,
               hud_h, SWP_NOACTIVATE | SWP_SHOWWINDOW);

  RenderFloatingHud();
  return true;
}

void DesktopTrackerPlugin::HideFloatingHud() {
  if (hud_hwnd_) {
    DestroyWindow(hud_hwnd_);
    hud_hwnd_ = nullptr;
  }
  hud_is_dragging_ = false;
  hud_user_moved_ = false;
}

void DesktopTrackerPlugin::RenderFloatingHud() {
  if (!hud_hwnd_) return;

  const int w = hud_state_.is_compact ? kHudWidthCompact : kHudWidthNormal;
  const int h = ComputeHudHeight();

  HDC screen_dc = GetDC(nullptr);
  HDC mem_dc = CreateCompatibleDC(screen_dc);

  BITMAPINFO bmi{};
  bmi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
  bmi.bmiHeader.biWidth = w;
  bmi.bmiHeader.biHeight = -h;
  bmi.bmiHeader.biPlanes = 1;
  bmi.bmiHeader.biBitCount = 32;
  bmi.bmiHeader.biCompression = BI_RGB;

  void* bits = nullptr;
  HBITMAP bmp =
      CreateDIBSection(screen_dc, &bmi, DIB_RGB_COLORS, &bits, nullptr, 0);
  if (!bmp) {
    DeleteDC(mem_dc);
    ReleaseDC(nullptr, screen_dc);
    return;
  }

  HGDIOBJ old_bmp = SelectObject(mem_dc, bmp);

  {
    Gdiplus::Graphics g(mem_dc);
    g.Clear(Gdiplus::Color(0, 0, 0, 0));
    g.SetSmoothingMode(Gdiplus::SmoothingModeAntiAlias);
    g.SetTextRenderingHint(Gdiplus::TextRenderingHintAntiAliasGridFit);

    const float radius = 14.0f;
    Gdiplus::GraphicsPath card_path;
    const float rw = static_cast<float>(w - 2);
    const float rh = static_cast<float>(h - 2);
    card_path.AddArc(1.0f, 1.0f, radius * 2, radius * 2, 180.0f, 90.0f);
    card_path.AddArc(1.0f + rw - radius * 2, 1.0f, radius * 2, radius * 2,
                     270.0f, 90.0f);
    card_path.AddArc(1.0f + rw - radius * 2, 1.0f + rh - radius * 2,
                     radius * 2, radius * 2, 0.0f, 90.0f);
    card_path.AddArc(1.0f, 1.0f + rh - radius * 2, radius * 2, radius * 2,
                     90.0f, 90.0f);
    card_path.CloseFigure();

    Gdiplus::SolidBrush bg_brush(Gdiplus::Color(242, 26, 27, 40));
    g.FillPath(&bg_brush, &card_path);

    Gdiplus::Pen border_pen(
        hud_state_.is_shiny ? Gdiplus::Color(255, 251, 192, 45)
                            : Gdiplus::Color(235, 62, 65, 92),
        hud_state_.is_shiny ? 2.0f : 1.2f);
    g.DrawPath(&border_pen, &card_path);

    // Header row: status dot + title + [compact][pin][close]
    Gdiplus::SolidBrush green_dot(Gdiplus::Color(255, 52, 211, 153));
    g.FillEllipse(&green_dot, 14.0f, 13.0f, 7.0f, 7.0f);

    Gdiplus::FontFamily ff(L"Segoe UI");
    Gdiplus::Font font_hdr(&ff, 10.5f, Gdiplus::FontStyleBold,
                           Gdiplus::UnitPixel);
    Gdiplus::Font font_name(&ff, hud_state_.is_compact ? 13.0f : 14.5f,
                            Gdiplus::FontStyleBold, Gdiplus::UnitPixel);
    Gdiplus::Font font_sub(&ff, 10.5f, Gdiplus::FontStyleBold,
                           Gdiplus::UnitPixel);

    Gdiplus::SolidBrush muted_brush(Gdiplus::Color(220, 185, 192, 210));
    Gdiplus::SolidBrush white_brush(Gdiplus::Color(255, 255, 255, 255));
    Gdiplus::SolidBrush shiny_brush(Gdiplus::Color(255, 255, 241, 118));

    Gdiplus::StringFormat sf_left;
    sf_left.SetAlignment(Gdiplus::StringAlignmentNear);
    sf_left.SetLineAlignment(Gdiplus::StringAlignmentCenter);
    sf_left.SetTrimming(Gdiplus::StringTrimmingEllipsisCharacter);
    sf_left.SetFormatFlags(Gdiplus::StringFormatFlagsNoWrap);

    Gdiplus::StringFormat sf_center;
    sf_center.SetAlignment(Gdiplus::StringAlignmentCenter);
    sf_center.SetLineAlignment(Gdiplus::StringAlignmentCenter);

    g.DrawString(L"Pok\u00E9Vault HUD", -1, &font_hdr,
                 Gdiplus::RectF(26.0f, 7.0f, 140.0f, 18.0f), &sf_left,
                 &muted_brush);

    // Header action button rects
    const int btn_size = 20;
    const int btn_y = 6;
    hud_buttons_.close_btn = {w - 28, btn_y, w - 8, btn_y + btn_size};
    hud_buttons_.pin_btn = {w - 52, btn_y, w - 32, btn_y + btn_size};
    hud_buttons_.compact_btn = {w - 76, btn_y, w - 56, btn_y + btn_size};

    g.DrawString(
        hud_state_.is_compact ? L"\u25A1" : L"\u2014", -1, &font_hdr,
        Gdiplus::RectF(static_cast<float>(hud_buttons_.compact_btn.left),
                       static_cast<float>(btn_y), 20.0f, 20.0f),
        &sf_center, &muted_brush);

    Gdiplus::SolidBrush pin_brush(hud_state_.is_pinned
                                      ? Gdiplus::Color(255, 251, 192, 45)
                                      : Gdiplus::Color(200, 180, 185, 200));
    g.DrawString(
        L"\U0001F4CC", -1, &font_hdr,
        Gdiplus::RectF(static_cast<float>(hud_buttons_.pin_btn.left),
                       static_cast<float>(btn_y), 20.0f, 20.0f),
        &sf_center, &pin_brush);

    g.DrawString(
        L"\u2715", -1, &font_hdr,
        Gdiplus::RectF(static_cast<float>(hud_buttons_.close_btn.left),
                       static_cast<float>(btn_y), 20.0f, 20.0f),
        &sf_center, &muted_brush);

    hud_buttons_.has_catch_btn = false;
    hud_buttons_.multi_catch_btns.clear();

    if (!hud_state_.has_event) {
      g.DrawString(hud_state_.waiting_label.c_str(), -1, &font_name,
                   Gdiplus::RectF(14.0f, 34.0f, static_cast<float>(w - 28),
                                  36.0f),
                   &sf_left, &muted_brush);
    } else if (hud_state_.focus_entries.size() > 1) {
      wchar_t multi_hdr[64]{};
      swprintf_s(multi_hdr, L"Pok\u00E9Vault HUD  \u00B7  %d Gegner",
                 static_cast<int>(hud_state_.focus_entries.size()));
      Gdiplus::SolidBrush hdr_bg(Gdiplus::Color(242, 26, 27, 40));
      g.FillRectangle(&hdr_bg, 24.0f, 7.0f, 165.0f, 18.0f);
      Gdiplus::SolidBrush cyan_brush(Gdiplus::Color(255, 103, 232, 249));
      g.DrawString(multi_hdr, -1, &font_hdr,
                   Gdiplus::RectF(26.0f, 7.0f, 175.0f, 18.0f), &sf_left,
                   &cyan_brush);

      int row_y = 32;
      for (const auto& entry : hud_state_.focus_entries) {
        std::wstring line = entry.pokemon_name;
        if (entry.is_shiny) line = L"\u2728 " + line;
        if (entry.encounter_count > 1) {
          wchar_t cnt_buf[16]{};
          swprintf_s(cnt_buf, L" \u00D7%d", entry.encounter_count);
          line += cnt_buf;
        }
        if (entry.pokemon_id > 0) {
          wchar_t id_buf[16]{};
          swprintf_s(id_buf, L" #%03d", entry.pokemon_id);
          line += id_buf;
        }

        const bool can_catch = !entry.is_caught && entry.pokemon_id > 0;
        const float text_w = static_cast<float>(w - (can_catch ? 84 : 28));
        g.DrawString(line.c_str(), -1, &font_sub,
                     Gdiplus::RectF(14.0f, static_cast<float>(row_y), text_w, 16.0f),
                     &sf_left,
                     entry.is_shiny ? &shiny_brush : &white_brush);

        const wchar_t* st_text = entry.is_caught
                                     ? hud_state_.caught_label.c_str()
                                     : hud_state_.missing_label.c_str();
        Gdiplus::SolidBrush st_brush(
            entry.is_caught ? Gdiplus::Color(255, 110, 231, 183)
                            : Gdiplus::Color(255, 252, 211, 77));
        g.DrawString(st_text, -1, &font_hdr,
                     Gdiplus::RectF(14.0f, static_cast<float>(row_y + 15),
                                    text_w, 14.0f),
                     &sf_left, &st_brush);

        if (can_catch) {
          RECT btn_rc{w - 64, row_y + 2, w - 12, row_y + 28};
          hud_buttons_.multi_catch_btns.push_back({btn_rc, entry.pokemon_id});
          Gdiplus::SolidBrush catch_bg(Gdiplus::Color(255, 22, 163, 74));
          g.FillRectangle(&catch_bg, btn_rc.left, btn_rc.top, 52, 26);
          g.DrawString(
              L"+ Dex", -1, &font_sub,
              Gdiplus::RectF(static_cast<float>(btn_rc.left),
                             static_cast<float>(btn_rc.top), 52.0f, 26.0f),
              &sf_center, &white_brush);
        }
        row_y += 36;
      }

      if (!hud_state_.is_compact) {
        wchar_t footer[128]{};
        if (!hud_state_.footer_label.empty()) {
          wcsncpy_s(footer, hud_state_.footer_label.c_str(), _TRUNCATE);
        } else {
          swprintf_s(footer, L"Deckkraft: %d%%  \u00B7  Ziehen zum Verschieben",
                     static_cast<int>(std::lround(hud_state_.opacity * 100.0)));
        }
        g.DrawString(
            footer, -1, &font_hdr,
            Gdiplus::RectF(14.0f, static_cast<float>(h - 24),
                           static_cast<float>(w - 28), 18.0f),
            &sf_left, &muted_brush);
      }
    } else {
      std::wstring display_name = hud_state_.pokemon_name;
      if (!hud_state_.instance_label.empty()) {
        display_name = L"[" + hud_state_.instance_label + L"] " + display_name;
      }
      if (hud_state_.is_shiny) {
        display_name = L"\u2728 " + display_name;
      }

      const float name_max_w =
          static_cast<float>(w - (hud_state_.is_caught ? 28 : 88));
      g.DrawString(display_name.c_str(), -1, &font_name,
                   Gdiplus::RectF(14.0f, 32.0f, name_max_w, 22.0f), &sf_left,
                   hud_state_.is_shiny ? &shiny_brush : &white_brush);

      wchar_t status_line[128]{};
      const wchar_t* status_text = hud_state_.is_caught
                                       ? hud_state_.caught_label.c_str()
                                       : hud_state_.missing_label.c_str();
      if (hud_state_.pokemon_id > 0) {
        swprintf_s(status_line, L"%s  \u00B7  #%03d", status_text,
                   hud_state_.pokemon_id);
      } else {
        swprintf_s(status_line, L"%s", status_text);
      }

      Gdiplus::SolidBrush status_brush(
          hud_state_.is_caught ? Gdiplus::Color(255, 110, 231, 183)
                               : Gdiplus::Color(255, 252, 211, 77));
      g.DrawString(status_line, -1, &font_sub,
                   Gdiplus::RectF(14.0f, 55.0f, name_max_w, 19.0f), &sf_left,
                   &status_brush);

      if (!hud_state_.is_caught && hud_state_.pokemon_id > 0) {
        hud_buttons_.has_catch_btn = true;
        hud_buttons_.catch_btn = {w - 64, 38, w - 12, 70};
        Gdiplus::SolidBrush catch_bg(Gdiplus::Color(255, 22, 163, 74));
        g.FillRectangle(&catch_bg, hud_buttons_.catch_btn.left,
                        hud_buttons_.catch_btn.top, 52, 32);
        g.DrawString(
            L"+ Dex", -1, &font_sub,
            Gdiplus::RectF(static_cast<float>(hud_buttons_.catch_btn.left),
                           static_cast<float>(hud_buttons_.catch_btn.top),
                           52.0f, 32.0f),
            &sf_center, &white_brush);
      }

      if (!hud_state_.is_compact) {
        if (!hud_state_.evolution_summary.empty()) {
          Gdiplus::SolidBrush evo_brush(
              hud_state_.has_missing_evolutions
                  ? Gdiplus::Color(255, 103, 232, 249)
                  : Gdiplus::Color(255, 167, 243, 208));
          g.DrawString(
              hud_state_.evolution_summary.c_str(), -1, &font_sub,
              Gdiplus::RectF(14.0f, 75.0f, static_cast<float>(w - 28), 18.0f),
              &sf_left, &evo_brush);
        }

        wchar_t footer[128]{};
        if (!hud_state_.footer_label.empty()) {
          wcsncpy_s(footer, hud_state_.footer_label.c_str(), _TRUNCATE);
        } else {
          swprintf_s(footer, L"Deckkraft: %d%%  \u00B7  Ziehen zum Verschieben",
                     static_cast<int>(std::lround(hud_state_.opacity * 100.0)));
        }
        g.DrawString(
            footer, -1, &font_hdr,
            Gdiplus::RectF(14.0f, 99.0f, static_cast<float>(w - 28), 18.0f),
            &sf_left, &muted_brush);
      }
    }
  }

  POINT pt_dst{hud_state_.pos_x, hud_state_.pos_y};
  SIZE size_wnd{w, h};
  POINT pt_src{0, 0};
  BLENDFUNCTION blend{};
  blend.BlendOp = AC_SRC_OVER;
  blend.SourceConstantAlpha =
      static_cast<BYTE>(std::clamp(hud_state_.opacity * 255.0, 76.0, 255.0));
  blend.AlphaFormat = AC_SRC_ALPHA;

  UpdateLayeredWindow(hud_hwnd_, screen_dc, &pt_dst, &size_wnd, mem_dc,
                      &pt_src, 0, &blend, ULW_ALPHA);

  SelectObject(mem_dc, old_bmp);
  DeleteObject(bmp);
  DeleteDC(mem_dc);
  ReleaseDC(nullptr, screen_dc);
}

void DesktopTrackerPlugin::InvokeDartHudEvent(
    const std::string& method,
    const flutter::EncodableValue& args) {
  if (!channel_) return;
  channel_->InvokeMethod(method,
                         std::make_unique<flutter::EncodableValue>(args));
}

LRESULT CALLBACK DesktopTrackerPlugin::DispatcherWndProc(HWND hwnd,
                                                           UINT msg,
                                                           WPARAM wparam,
                                                           LPARAM lparam) {
  if (msg == WM_NCCREATE) {
    auto* cs = reinterpret_cast<CREATESTRUCTW*>(lparam);
    SetWindowLongPtrW(hwnd, GWLP_USERDATA,
                      reinterpret_cast<LONG_PTR>(cs->lpCreateParams));
    return TRUE;
  }

  if (msg == kMsgOcrComplete) {
    auto* payload = reinterpret_cast<OcrAsyncPayload*>(lparam);
    if (payload) {
      flutter::EncodableList lines_list;
      for (const auto& l : payload->lines) {
        lines_list.push_back(flutter::EncodableValue(l));
      }
      flutter::EncodableList avail_list;
      for (const auto& lang : payload->available_languages) {
        avail_list.push_back(flutter::EncodableValue(lang));
      }
      flutter::EncodableMap resp;
      resp[flutter::EncodableValue("lines")] =
          flutter::EncodableValue(std::move(lines_list));
      resp[flutter::EncodableValue("usedFallbackLanguage")] =
          flutter::EncodableValue(payload->used_fallback_language);
      resp[flutter::EncodableValue("resolvedLanguageTag")] =
          flutter::EncodableValue(payload->resolved_language_tag);
      resp[flutter::EncodableValue("requestedLanguageTag")] =
          flutter::EncodableValue(payload->requested_language_tag);
      resp[flutter::EncodableValue("availableLanguages")] =
          flutter::EncodableValue(std::move(avail_list));
      resp[flutter::EncodableValue("ocrSucceeded")] =
          flutter::EncodableValue(payload->success);
      resp[flutter::EncodableValue("ocrDurationMs")] =
          flutter::EncodableValue(payload->ocr_duration_ms);
      if (!payload->error_hint.empty()) {
        resp[flutter::EncodableValue("errorHint")] =
            flutter::EncodableValue(payload->error_hint);
      }
      if (payload->result) {
        payload->result->Success(flutter::EncodableValue(std::move(resp)));
      }
      delete payload;
    }
    return 0;
  }

  if (msg == kMsgCaptureComplete) {
    auto* payload = reinterpret_cast<CaptureAsyncPayload*>(lparam);
    if (payload) {
      if (payload->result) {
        if (payload->success) {
          flutter::EncodableMap out;
          out[flutter::EncodableValue("width")] =
              flutter::EncodableValue(payload->width);
          out[flutter::EncodableValue("height")] =
              flutter::EncodableValue(payload->height);
          out[flutter::EncodableValue("pixelFormat")] =
              flutter::EncodableValue("bgra8888");
          out[flutter::EncodableValue("captureMethod")] =
              flutter::EncodableValue(payload->capture_method);
          out[flutter::EncodableValue("bytes")] =
              flutter::EncodableValue(std::move(payload->bytes));
          payload->result->Success(flutter::EncodableValue(std::move(out)));
        } else {
          payload->result->Success(flutter::EncodableValue());
        }
      }
      delete payload;
    }
    return 0;
  }

  if (msg == kMsgCaptureAnalyzeComplete) {
    auto* payload = reinterpret_cast<CaptureAnalyzePayload*>(lparam);
    if (payload) {
      flutter::EncodableMap resp;
      resp[flutter::EncodableValue("captured")] =
          flutter::EncodableValue(payload->captured);
      resp[flutter::EncodableValue("ocrSkipped")] =
          flutter::EncodableValue(payload->ocr_skipped);
      flutter::EncodableList lines_list;
      for (const auto& l : payload->lines) {
        lines_list.push_back(flutter::EncodableValue(l));
      }
      resp[flutter::EncodableValue("lines")] =
          flutter::EncodableValue(std::move(lines_list));
      resp[flutter::EncodableValue("usedFallbackLanguage")] =
          flutter::EncodableValue(payload->used_fallback_language);
      resp[flutter::EncodableValue("resolvedLanguageTag")] =
          flutter::EncodableValue(payload->resolved_language_tag);
      resp[flutter::EncodableValue("requestedLanguageTag")] =
          flutter::EncodableValue(payload->requested_language_tag);
      flutter::EncodableList avail_list;
      for (const auto& lang : payload->available_languages) {
        avail_list.push_back(flutter::EncodableValue(lang));
      }
      resp[flutter::EncodableValue("availableLanguages")] =
          flutter::EncodableValue(std::move(avail_list));
      resp[flutter::EncodableValue("ocrSucceeded")] =
          flutter::EncodableValue(payload->ocr_succeeded);
      if (!payload->error_hint.empty()) {
        resp[flutter::EncodableValue("errorHint")] =
            flutter::EncodableValue(payload->error_hint);
      }
      resp[flutter::EncodableValue("captureDurationMs")] =
          flutter::EncodableValue(payload->capture_duration_ms);
      resp[flutter::EncodableValue("ocrDurationMs")] =
          flutter::EncodableValue(payload->ocr_duration_ms);
      resp[flutter::EncodableValue("frameWidth")] =
          flutter::EncodableValue(payload->frame_width);
      resp[flutter::EncodableValue("frameHeight")] =
          flutter::EncodableValue(payload->frame_height);
      resp[flutter::EncodableValue("captureMethod")] =
          flutter::EncodableValue(payload->capture_method);
      resp[flutter::EncodableValue("brightnessSummary")] =
          flutter::EncodableValue(payload->brightness_summary);
      if (payload->has_luma) {
        resp[flutter::EncodableValue("avgLuma")] =
            flutter::EncodableValue(payload->avg_luma);
        resp[flutter::EncodableValue("stdDev")] =
            flutter::EncodableValue(payload->std_dev);
      }
      if (payload->has_color_histogram) {
        flutter::EncodableList hist_list;
        for (double v : payload->color_histogram) {
          hist_list.push_back(flutter::EncodableValue(v));
        }
        resp[flutter::EncodableValue("colorHistogram")] =
            flutter::EncodableValue(std::move(hist_list));
      }
      resp[flutter::EncodableValue("selfWindowOverlaps")] =
          flutter::EncodableValue(payload->self_window_overlaps);
      if (!payload->thumbnail_png.empty() && payload->thumbnail_width > 0 &&
          payload->thumbnail_height > 0) {
        resp[flutter::EncodableValue("thumbnailPng")] =
            flutter::EncodableValue(std::move(payload->thumbnail_png));
        resp[flutter::EncodableValue("thumbnailWidth")] =
            flutter::EncodableValue(payload->thumbnail_width);
        resp[flutter::EncodableValue("thumbnailHeight")] =
            flutter::EncodableValue(payload->thumbnail_height);
      }
      if (payload->result) {
        payload->result->Success(flutter::EncodableValue(std::move(resp)));
      }
      delete payload;
    }
    return 0;
  }

  return DefWindowProcW(hwnd, msg, wparam, lparam);
}

LRESULT CALLBACK DesktopTrackerPlugin::SnippingWndProc(HWND hwnd,
                                                        UINT msg,
                                                        WPARAM wparam,
                                                        LPARAM lparam) {
  if (msg == WM_NCCREATE) {
    auto* cs = reinterpret_cast<CREATESTRUCTW*>(lparam);
    SetWindowLongPtrW(hwnd, GWLP_USERDATA,
                      reinterpret_cast<LONG_PTR>(cs->lpCreateParams));
    return TRUE;
  }

  auto* self = reinterpret_cast<DesktopTrackerPlugin*>(
      GetWindowLongPtrW(hwnd, GWLP_USERDATA));
  if (!self) return DefWindowProcW(hwnd, msg, wparam, lparam);

  switch (msg) {
    case WM_ERASEBKGND:
      return 1;

    case WM_PAINT:
      self->PaintSnippingOverlay(hwnd);
      return 0;

    case WM_KEYDOWN:
      if (wparam == VK_ESCAPE) {
        self->FinishSnipping(false);
        return 0;
      }
      if (wparam == VK_RETURN && self->snip_has_selection_) {
        self->FinishSnipping(true);
        return 0;
      }
      break;

    case WM_RBUTTONDOWN:
      self->FinishSnipping(false);
      return 0;

    case WM_LBUTTONDBLCLK: {
      if (self->snip_has_selection_) {
        POINT pt{static_cast<short>(LOWORD(lparam)),
                 static_cast<short>(HIWORD(lparam))};
        RECT sel = self->GetNormalizedSelection();
        if (PtInRect(&sel, pt)) {
          self->FinishSnipping(true);
          return 0;
        }
      }
      break;
    }

    case WM_LBUTTONDOWN: {
      POINT pt{static_cast<short>(LOWORD(lparam)),
               static_cast<short>(HIWORD(lparam))};
      if (self->snip_has_selection_) {
        if (PtInRect(&self->snip_confirm_btn_, pt)) {
          self->FinishSnipping(true);
          return 0;
        }
        if (PtInRect(&self->snip_cancel_btn_, pt)) {
          self->FinishSnipping(false);
          return 0;
        }
      }

      self->snip_is_dragging_ = true;
      self->snip_has_selection_ = false;
      self->snip_start_ = pt;
      self->snip_end_ = pt;
      SetCapture(hwnd);
      InvalidateRect(hwnd, nullptr, FALSE);
      return 0;
    }

    case WM_MOUSEMOVE:
      if (self->snip_is_dragging_) {
        self->snip_end_ = POINT{static_cast<short>(LOWORD(lparam)),
                                static_cast<short>(HIWORD(lparam))};
        InvalidateRect(hwnd, nullptr, FALSE);
        return 0;
      }
      break;

    case WM_LBUTTONUP:
      if (self->snip_is_dragging_) {
        self->snip_is_dragging_ = false;
        self->snip_end_ = POINT{static_cast<short>(LOWORD(lparam)),
                                static_cast<short>(HIWORD(lparam))};
        ReleaseCapture();
        RECT sel = self->GetNormalizedSelection();
        self->snip_has_selection_ =
            (sel.right - sel.left) >= 10 && (sel.bottom - sel.top) >= 10;
        InvalidateRect(hwnd, nullptr, FALSE);
        return 0;
      }
      break;
  }

  return DefWindowProcW(hwnd, msg, wparam, lparam);
}

LRESULT CALLBACK DesktopTrackerPlugin::HudWndProc(HWND hwnd,
                                                   UINT msg,
                                                   WPARAM wparam,
                                                   LPARAM lparam) {
  if (msg == WM_NCCREATE) {
    auto* cs = reinterpret_cast<CREATESTRUCTW*>(lparam);
    SetWindowLongPtrW(hwnd, GWLP_USERDATA,
                      reinterpret_cast<LONG_PTR>(cs->lpCreateParams));
    return TRUE;
  }

  auto* self = reinterpret_cast<DesktopTrackerPlugin*>(
      GetWindowLongPtrW(hwnd, GWLP_USERDATA));
  if (!self) return DefWindowProcW(hwnd, msg, wparam, lparam);

  switch (msg) {
    case WM_MOUSEACTIVATE:
      return MA_NOACTIVATE;

    case WM_LBUTTONDOWN: {
      POINT pt{static_cast<short>(LOWORD(lparam)),
               static_cast<short>(HIWORD(lparam))};

      if (PtInRect(&self->hud_buttons_.close_btn, pt)) {
        self->HideFloatingHud();
        self->InvokeDartHudEvent("onHudClose");
        return 0;
      }

      if (PtInRect(&self->hud_buttons_.compact_btn, pt)) {
        self->hud_state_.is_compact = !self->hud_state_.is_compact;
        self->RenderFloatingHud();
        const int hud_w = self->hud_state_.is_compact ? kHudWidthCompact
                                                      : kHudWidthNormal;
        const int hud_h = self->ComputeHudHeight();
        SetWindowPos(hwnd, nullptr, 0, 0, hud_w, hud_h,
                     SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE);
        self->RenderFloatingHud();
        flutter::EncodableMap args;
        args[flutter::EncodableValue("isCompact")] =
            flutter::EncodableValue(self->hud_state_.is_compact);
        self->InvokeDartHudEvent("onHudCompactChanged",
                                 flutter::EncodableValue(std::move(args)));
        return 0;
      }

      if (PtInRect(&self->hud_buttons_.pin_btn, pt)) {
        self->hud_state_.is_pinned = !self->hud_state_.is_pinned;
        SetWindowPos(
            hwnd,
            self->hud_state_.is_pinned ? HWND_TOPMOST : HWND_NOTOPMOST, 0, 0,
            0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
        self->RenderFloatingHud();
        flutter::EncodableMap args;
        args[flutter::EncodableValue("isPinned")] =
            flutter::EncodableValue(self->hud_state_.is_pinned);
        self->InvokeDartHudEvent("onHudPinnedChanged",
                                 flutter::EncodableValue(std::move(args)));
        return 0;
      }

      for (const auto& pair : self->hud_buttons_.multi_catch_btns) {
        if (PtInRect(&pair.first, pt)) {
          flutter::EncodableMap args;
          args[flutter::EncodableValue("pokemonId")] =
              flutter::EncodableValue(pair.second);
          self->InvokeDartHudEvent("onHudMarkCaught",
                                   flutter::EncodableValue(std::move(args)));
          return 0;
        }
      }

      if (self->hud_buttons_.has_catch_btn &&
          PtInRect(&self->hud_buttons_.catch_btn, pt)) {
        self->InvokeDartHudEvent("onHudMarkCaught");
        return 0;
      }

      self->hud_is_dragging_ = true;
      self->hud_drag_offset_ = pt;
      SetCapture(hwnd);
      return 0;
    }

    case WM_MOUSEMOVE:
      if (self->hud_is_dragging_) {
        POINT cursor{};
        GetCursorPos(&cursor);
        self->hud_state_.pos_x = cursor.x - self->hud_drag_offset_.x;
        self->hud_state_.pos_y = cursor.y - self->hud_drag_offset_.y;
        self->hud_user_moved_ = true;
        SetWindowPos(hwnd, nullptr, self->hud_state_.pos_x,
                     self->hud_state_.pos_y, 0, 0,
                     SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE);
        return 0;
      }
      break;

    case WM_LBUTTONUP:
      if (self->hud_is_dragging_) {
        self->hud_is_dragging_ = false;
        ReleaseCapture();
        flutter::EncodableMap args;
        args[flutter::EncodableValue("x")] =
            flutter::EncodableValue(static_cast<double>(self->hud_state_.pos_x));
        args[flutter::EncodableValue("y")] =
            flutter::EncodableValue(static_cast<double>(self->hud_state_.pos_y));
        self->InvokeDartHudEvent("onHudMoved",
                                 flutter::EncodableValue(std::move(args)));
        return 0;
      }
      break;
  }

  return DefWindowProcW(hwnd, msg, wparam, lparam);
}

void DesktopTrackerPlugin::ShowScanRegionBorder(
    const flutter::EncodableMap& args) {
  const int x = static_cast<int>(std::lround(GetDoubleArg(args, "x", 0.0)));
  const int y = static_cast<int>(std::lround(GetDoubleArg(args, "y", 0.0)));
  const int w = static_cast<int>(std::lround(GetDoubleArg(args, "width", 0.0)));
  const int h = static_cast<int>(std::lround(GetDoubleArg(args, "height", 0.0)));
  scan_border_active_ = GetBoolArg(args, "active", true);

  if (w < 8 || h < 8) {
    HideScanRegionBorder();
    return;
  }

  EnsureOverlayWindowClasses();

  constexpr int kThickness = 2;
  const int outer_x = x - kThickness;
  const int outer_y = y - kThickness;
  const int outer_w = w + kThickness * 2;
  const int outer_h = h + kThickness * 2;

  if (!scan_border_hwnd_) {
    scan_border_hwnd_ = CreateWindowExW(
        WS_EX_TOPMOST | WS_EX_TOOLWINDOW | WS_EX_TRANSPARENT |
            WS_EX_NOACTIVATE | WS_EX_LAYERED,
        kScanBorderClassName, L"Pok\u00E9Vault Scan Border", WS_POPUP, outer_x,
        outer_y, outer_w, outer_h, nullptr, nullptr, GetModuleHandleW(nullptr),
        this);
    if (!scan_border_hwnd_) return;
    SetLayeredWindowAttributes(scan_border_hwnd_, 0, 225, LWA_ALPHA);
  } else {
    SetWindowPos(scan_border_hwnd_, HWND_TOPMOST, outer_x, outer_y, outer_w,
                 outer_h, SWP_NOACTIVATE | SWP_SHOWWINDOW);
  }

  // Hollow perimeter region so zero pixels inside [x, y, w, h] are occluded.
  HRGN outer_rgn = CreateRectRgn(0, 0, outer_w, outer_h);
  HRGN inner_rgn =
      CreateRectRgn(kThickness, kThickness, outer_w - kThickness,
                    outer_h - kThickness);
  if (outer_rgn && inner_rgn) {
    CombineRgn(outer_rgn, outer_rgn, inner_rgn, RGN_DIFF);
    SetWindowRgn(scan_border_hwnd_, outer_rgn, TRUE);
    DeleteObject(inner_rgn);
  } else {
    if (outer_rgn) DeleteObject(outer_rgn);
    if (inner_rgn) DeleteObject(inner_rgn);
  }

  ShowWindow(scan_border_hwnd_, SW_SHOWNOACTIVATE);
  InvalidateRect(scan_border_hwnd_, nullptr, TRUE);
}

void DesktopTrackerPlugin::HideScanRegionBorder() {
  if (scan_border_hwnd_) {
    DestroyWindow(scan_border_hwnd_);
    scan_border_hwnd_ = nullptr;
  }
}

void DesktopTrackerPlugin::ClearOverlayBorders() {
  for (auto& kv : overlay_borders_) {
    if (kv.second.hwnd) {
      DestroyWindow(kv.second.hwnd);
      kv.second.hwnd = nullptr;
    }
  }
  overlay_borders_.clear();
}

void DesktopTrackerPlugin::SetOverlayBorders(
    const flutter::EncodableMap& args) {
  auto it = args.find(flutter::EncodableValue("borders"));
  if (it == args.end() ||
      !std::holds_alternative<flutter::EncodableList>(it->second)) {
    ClearOverlayBorders();
    return;
  }

  EnsureOverlayWindowClasses();
  const auto& list = std::get<flutter::EncodableList>(it->second);
  std::map<std::string, bool> keep_ids;

  for (const auto& item : list) {
    if (!std::holds_alternative<flutter::EncodableMap>(item)) continue;
    const auto& bmap = std::get<flutter::EncodableMap>(item);
    const std::string id = GetStringArg(bmap, "id", "");
    if (id.empty()) continue;
    const bool visible = GetBoolArg(bmap, "visible", true);
    if (!visible) continue;

    const int x = static_cast<int>(std::lround(GetDoubleArg(bmap, "x", 0.0)));
    const int y = static_cast<int>(std::lround(GetDoubleArg(bmap, "y", 0.0)));
    const int w =
        static_cast<int>(std::lround(GetDoubleArg(bmap, "width", 0.0)));
    const int h =
        static_cast<int>(std::lround(GetDoubleArg(bmap, "height", 0.0)));
    if (w < 8 || h < 8) continue;

    const int64_t argb =
        GetInt64Arg(bmap, "colorArgb", static_cast<int64_t>(0xFF10B981));
    const BYTE r = static_cast<BYTE>((argb >> 16) & 0xFF);
    const BYTE g_c = static_cast<BYTE>((argb >> 8) & 0xFF);
    const BYTE b = static_cast<BYTE>(argb & 0xFF);
    const COLORREF color = RGB(r, g_c, b);
    const std::wstring label = Utf8ToWide(GetStringArg(bmap, "label", ""));

    keep_ids[id] = true;
    auto& entry = overlay_borders_[id];
    entry.color = color;
    entry.label = label;

    constexpr int kThickness = 2;
    const bool has_tab = !label.empty() && y >= 18;
    const int tab_h = has_tab ? 16 : 0;
    const int outer_x = x - kThickness;
    const int outer_y = y - kThickness - tab_h;
    const int outer_w = w + kThickness * 2;
    const int outer_h = h + kThickness * 2 + tab_h;

    if (!entry.hwnd) {
      entry.hwnd = CreateWindowExW(
          WS_EX_TOPMOST | WS_EX_TOOLWINDOW | WS_EX_TRANSPARENT |
              WS_EX_NOACTIVATE | WS_EX_LAYERED,
          kScanBorderClassName, L"Pok\u00E9Vault Overlay Border", WS_POPUP,
          outer_x, outer_y, outer_w, outer_h, nullptr, nullptr,
          GetModuleHandleW(nullptr), this);
      if (!entry.hwnd) continue;
      SetLayeredWindowAttributes(entry.hwnd, 0, 230, LWA_ALPHA);
    } else {
      SetWindowPos(entry.hwnd, HWND_TOPMOST, outer_x, outer_y, outer_w,
                   outer_h, SWP_NOACTIVATE | SWP_SHOWWINDOW);
    }

    SetPropW(entry.hwnd, L"PV_BORDER_COLOR",
             reinterpret_cast<HANDLE>(static_cast<ULONG_PTR>(color)));
    auto* prev_lbl =
        reinterpret_cast<std::wstring*>(GetPropW(entry.hwnd, L"PV_BORDER_LABEL"));
    if (prev_lbl) {
      *prev_lbl = label;
    } else if (!label.empty()) {
      auto* lbl_ptr = new std::wstring(label);
      if (!SetPropW(entry.hwnd, L"PV_BORDER_LABEL",
                    reinterpret_cast<HANDLE>(lbl_ptr))) {
        delete lbl_ptr;
      }
    }
    SetPropW(entry.hwnd, L"PV_BORDER_TABH",
             reinterpret_cast<HANDLE>(static_cast<ULONG_PTR>(tab_h)));

    HRGN frame_rgn =
        CreateRectRgn(0, tab_h, outer_w, outer_h);
    HRGN inner_rgn = CreateRectRgn(
        kThickness, tab_h + kThickness, outer_w - kThickness,
        outer_h - kThickness);
    if (frame_rgn && inner_rgn) {
      CombineRgn(frame_rgn, frame_rgn, inner_rgn, RGN_DIFF);
      DeleteObject(inner_rgn);
      if (has_tab) {
        const int tab_w = min(outer_w, 64);
        HRGN tab_rgn = CreateRectRgn(0, 0, tab_w, tab_h + kThickness);
        if (tab_rgn) {
          CombineRgn(frame_rgn, frame_rgn, tab_rgn, RGN_OR);
          DeleteObject(tab_rgn);
        }
      }
      SetWindowRgn(entry.hwnd, frame_rgn, TRUE);
    } else {
      if (frame_rgn) DeleteObject(frame_rgn);
      if (inner_rgn) DeleteObject(inner_rgn);
    }

    ShowWindow(entry.hwnd, SW_SHOWNOACTIVATE);
    InvalidateRect(entry.hwnd, nullptr, TRUE);
  }

  for (auto map_it = overlay_borders_.begin();
       map_it != overlay_borders_.end();) {
    if (keep_ids.find(map_it->first) == keep_ids.end()) {
      if (map_it->second.hwnd) {
        DestroyWindow(map_it->second.hwnd);
      }
      map_it = overlay_borders_.erase(map_it);
    } else {
      ++map_it;
    }
  }
}

LRESULT CALLBACK DesktopTrackerPlugin::ScanBorderWndProc(HWND hwnd,
                                                          UINT msg,
                                                          WPARAM wparam,
                                                          LPARAM lparam) {
  if (msg == WM_NCCREATE) {
    auto* cs = reinterpret_cast<CREATESTRUCTW*>(lparam);
    SetWindowLongPtrW(hwnd, GWLP_USERDATA,
                      reinterpret_cast<LONG_PTR>(cs->lpCreateParams));
    return TRUE;
  }

  auto* self = reinterpret_cast<DesktopTrackerPlugin*>(
      GetWindowLongPtrW(hwnd, GWLP_USERDATA));
  if (!self) return DefWindowProcW(hwnd, msg, wparam, lparam);

  switch (msg) {
    case WM_NCDESTROY: {
      RemovePropW(hwnd, L"PV_BORDER_COLOR");
      RemovePropW(hwnd, L"PV_BORDER_TABH");
      auto* lbl =
          reinterpret_cast<std::wstring*>(RemovePropW(hwnd, L"PV_BORDER_LABEL"));
      delete lbl;
      break;
    }

    case WM_MOUSEACTIVATE:
      return MA_NOACTIVATE;

    case WM_NCHITTEST:
      return HTTRANSPARENT;

    case WM_ERASEBKGND:
      return 1;

    case WM_PAINT: {
      PAINTSTRUCT ps{};
      HDC hdc = BeginPaint(hwnd, &ps);
      if (hdc) {
        RECT rc{};
        GetClientRect(hwnd, &rc);
        HANDLE col_prop = GetPropW(hwnd, L"PV_BORDER_COLOR");
        COLORREF color = col_prop
                             ? static_cast<COLORREF>(
                                   reinterpret_cast<ULONG_PTR>(col_prop))
                             : (self->scan_border_active_ ? RGB(34, 197, 94)
                                                          : RGB(245, 158, 11));
        HBRUSH brush = CreateSolidBrush(color);
        FillRect(hdc, &rc, brush);
        DeleteObject(brush);

        const int tab_h = static_cast<int>(
            reinterpret_cast<ULONG_PTR>(GetPropW(hwnd, L"PV_BORDER_TABH")));
        auto* lbl =
            reinterpret_cast<std::wstring*>(GetPropW(hwnd, L"PV_BORDER_LABEL"));
        if (tab_h > 0 && lbl && !lbl->empty()) {
          RECT text_rc{4, 0, min(static_cast<int>(rc.right), 64), tab_h};
          SetBkMode(hdc, TRANSPARENT);
          SetTextColor(hdc, RGB(255, 255, 255));
          if (!self->scan_border_font_) {
            self->scan_border_font_ = CreateFontW(
                11, 0, 0, 0, FW_BOLD, FALSE, FALSE, FALSE, DEFAULT_CHARSET,
                OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY,
                DEFAULT_PITCH | FF_SWISS, L"Segoe UI");
          }
          HGDIOBJ old_font = self->scan_border_font_
                                 ? SelectObject(hdc, self->scan_border_font_)
                                 : nullptr;
          DrawTextW(hdc, lbl->c_str(), -1, &text_rc,
                    DT_LEFT | DT_VCENTER | DT_SINGLELINE | DT_END_ELLIPSIS);
          if (old_font) SelectObject(hdc, old_font);
        }
        EndPaint(hwnd, &ps);
      }
      return 0;
    }
  }

  return DefWindowProcW(hwnd, msg, wparam, lparam);
}
