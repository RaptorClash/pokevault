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
#include <chrono>
#include <cmath>
#include <cstring>
#include <thread>

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
      if (y <= 85) {
        mapped = 0;
      } else if (y <= 115) {
        mapped = (y - 85) * 4;
      } else if (y <= 195) {
        // Compress DS pixel-font grey drop shadows toward crisp background white.
        mapped = 185 + ((y - 115) * 70) / 80;
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

bool RunWindowsMediaOcr(const std::vector<uint8_t>& bgra_bytes,
                        int width,
                        int height,
                        const std::string& language_tag,
                        const std::string& preprocess_profile,
                        std::vector<std::string>* out_lines,
                        bool* out_used_fallback,
                        std::string* out_resolved_tag,
                        std::vector<std::string>* out_available_languages,
                        std::string* out_error_hint) {
  if (!out_lines || width <= 0 || height <= 0 ||
      bgra_bytes.size() < static_cast<size_t>(width) * height * 4) {
    if (out_error_hint) *out_error_hint = "Invalid frame buffer or dimensions";
    return false;
  }

  HRESULT ro_hr = RoInitialize(RO_INIT_MULTITHREADED);
  const bool ro_inited = SUCCEEDED(ro_hr);

  auto cleanup_ro = [&]() {
    if (ro_inited) {
      RoUninitialize();
    }
  };

  using namespace Microsoft::WRL;
  using namespace Microsoft::WRL::Wrappers;

  ComPtr<ABI::Windows::Media::Ocr::IOcrEngineStatics> ocr_statics;
  HRESULT hr = RoGetActivationFactory(
      HStringReference(RuntimeClass_Windows_Media_Ocr_OcrEngine).Get(),
      IID_PPV_ARGS(&ocr_statics));
  if (FAILED(hr) || !ocr_statics) {
    if (out_error_hint) *out_error_hint = "OcrEngine factory init failed";
    cleanup_ro();
    return false;
  }

  if (out_available_languages) {
    ComPtr<ABI::Windows::Foundation::Collections::IVectorView<
        ABI::Windows::Globalization::Language*>>
        avail_langs;
    if (SUCCEEDED(ocr_statics->get_AvailableRecognizerLanguages(&avail_langs)) &&
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
              out_available_languages->push_back(
                  WideToUtf8(std::wstring(raw, len)));
            }
            WindowsDeleteString(h_tag);
          }
        }
      }
    }
  }

  ComPtr<ABI::Windows::Media::Ocr::IOcrEngine> ocr_engine;
  bool used_fallback = false;
  std::string resolved_tag = language_tag;

  if (!language_tag.empty()) {
    ComPtr<ABI::Windows::Globalization::ILanguageFactory> lang_factory;
    if (SUCCEEDED(RoGetActivationFactory(
            HStringReference(RuntimeClass_Windows_Globalization_Language).Get(),
            IID_PPV_ARGS(&lang_factory))) &&
        lang_factory) {
      std::wstring wtag = Utf8ToWide(language_tag);
      HString htag;
      if (SUCCEEDED(htag.Set(wtag.c_str()))) {
        ComPtr<ABI::Windows::Globalization::ILanguage> lang;
        if (SUCCEEDED(lang_factory->CreateLanguage(htag.Get(), &lang)) &&
            lang) {
          ocr_statics->TryCreateFromLanguage(lang.Get(), &ocr_engine);
        }
      }
    }
  }

  if (!ocr_engine) {
    used_fallback = !language_tag.empty();
    hr = ocr_statics->TryCreateFromUserProfileLanguages(&ocr_engine);
    if (FAILED(hr) || !ocr_engine) {
      if (out_error_hint) {
        *out_error_hint = "No Windows OCR language pack available";
      }
      cleanup_ro();
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

  ComPtr<ABI::Windows::Graphics::Imaging::ISoftwareBitmapStatics> bmp_statics;
  hr = RoGetActivationFactory(
      HStringReference(RuntimeClass_Windows_Graphics_Imaging_SoftwareBitmap)
          .Get(),
      IID_PPV_ARGS(&bmp_statics));
  if (FAILED(hr) || !bmp_statics) {
    if (out_error_hint) *out_error_hint = "SoftwareBitmap factory init failed";
    cleanup_ro();
    return false;
  }

  const std::vector<uint8_t> preprocessed_bytes =
      PreprocessFrameBytes(bgra_bytes, width, height, preprocess_profile);

  ComPtr<BgraWinRtBuffer> winrt_buf;
  int ocr_width = width;
  int ocr_height = height;
  const int max_dim = (std::max)(width, height);
  int scale_factor = 1;
  bool use_nearest_neighbor = false;
  if (preprocess_profile == "pixelArtDs") {
    use_nearest_neighbor = true;
    if (max_dim <= 1000) {
      scale_factor = 3;
    } else if (max_dim <= 1800) {
      scale_factor = 2;
    }
  } else if (width > 0 && height > 0 && max_dim <= 1600) {
    scale_factor = 2;
  }

  if (scale_factor > 1) {
    const int scaled_w = width * scale_factor;
    const int scaled_h = height * scale_factor;
    Gdiplus::Bitmap src_bmp(
        width, height, width * 4, PixelFormat32bppRGB,
        const_cast<BYTE*>(
            reinterpret_cast<const BYTE*>(preprocessed_bytes.data())));
    if (src_bmp.GetLastStatus() == Gdiplus::Ok) {
      Gdiplus::Bitmap dst_bmp(scaled_w, scaled_h, PixelFormat32bppRGB);
      if (dst_bmp.GetLastStatus() == Gdiplus::Ok) {
        Gdiplus::Graphics graphics(&dst_bmp);
        graphics.SetInterpolationMode(
            use_nearest_neighbor
                ? Gdiplus::InterpolationModeNearestNeighbor
                : Gdiplus::InterpolationModeHighQualityBicubic);
        graphics.SetPixelOffsetMode(
            use_nearest_neighbor
                ? Gdiplus::PixelOffsetModeHalf
                : Gdiplus::PixelOffsetModeHighQuality);
        graphics.SetCompositingQuality(
            Gdiplus::CompositingQualityHighQuality);
        if (graphics.DrawImage(&src_bmp, Gdiplus::Rect(0, 0, scaled_w, scaled_h),
                               0, 0, width, height, Gdiplus::UnitPixel) ==
            Gdiplus::Ok) {
          Gdiplus::BitmapData locked{};
          Gdiplus::Rect lock_rect(0, 0, scaled_w, scaled_h);
          if (dst_bmp.LockBits(&lock_rect, Gdiplus::ImageLockModeRead,
                               PixelFormat32bppRGB, &locked) == Gdiplus::Ok) {
            std::vector<uint8_t> scaled_bytes(
                static_cast<size_t>(scaled_w) * scaled_h * 4);
            const auto* base_ptr =
                static_cast<const uint8_t*>(locked.Scan0);
            const int row_bytes = scaled_w * 4;
            for (int row = 0; row < scaled_h; ++row) {
              const uint8_t* src_row = base_ptr + row * locked.Stride;
              uint8_t* dst_row =
                  scaled_bytes.data() + static_cast<size_t>(row) * row_bytes;
              std::memcpy(dst_row, src_row, static_cast<size_t>(row_bytes));
              for (int col = 0; col < scaled_w; ++col) {
                dst_row[col * 4 + 3] = 255;
              }
            }
            dst_bmp.UnlockBits(&locked);
            winrt_buf = Make<BgraWinRtBuffer>(std::move(scaled_bytes));
            ocr_width = scaled_w;
            ocr_height = scaled_h;
          }
        }
      }
    }
  }
  if (!winrt_buf) {
    winrt_buf = Make<BgraWinRtBuffer>(preprocessed_bytes);
  }
  if (!winrt_buf) {
    if (out_error_hint) *out_error_hint = "BgraWinRtBuffer allocation failed";
    cleanup_ro();
    return false;
  }

  ComPtr<ABI::Windows::Storage::Streams::IBuffer> ibuf;
  if (FAILED(winrt_buf.As(&ibuf)) || !ibuf) {
    if (out_error_hint) *out_error_hint = "IBuffer cast failed";
    cleanup_ro();
    return false;
  }

  ComPtr<ABI::Windows::Graphics::Imaging::ISoftwareBitmap> software_bmp;
  hr = bmp_statics->CreateCopyFromBuffer(
      ibuf.Get(),
      ABI::Windows::Graphics::Imaging::BitmapPixelFormat_Bgra8,
      static_cast<INT32>(ocr_width),
      static_cast<INT32>(ocr_height),
      &software_bmp);
  if (FAILED(hr) || !software_bmp) {
    if (out_error_hint) *out_error_hint = "CreateCopyFromBuffer failed";
    cleanup_ro();
    return false;
  }

  ComPtr<ABI::Windows::Foundation::IAsyncOperation<
      ABI::Windows::Media::Ocr::OcrResult*>>
      async_op;
  hr = ocr_engine->RecognizeAsync(software_bmp.Get(), &async_op);
  if (FAILED(hr) || !async_op) {
    if (out_error_hint) *out_error_hint = "RecognizeAsync call failed";
    cleanup_ro();
    return false;
  }

  HANDLE done_event = CreateEventW(nullptr, TRUE, FALSE, nullptr);
  if (!done_event) {
    if (out_error_hint) *out_error_hint = "CreateEventW failed";
    cleanup_ro();
    return false;
  }

  auto completed_cb = Callback<ABI::Windows::Foundation::IAsyncOperationCompletedHandler<
      ABI::Windows::Media::Ocr::OcrResult*>>(
      [done_event](
          ABI::Windows::Foundation::IAsyncOperation<
              ABI::Windows::Media::Ocr::OcrResult*>* /*op*/,
          ABI::Windows::Foundation::AsyncStatus /*status*/) -> HRESULT {
        SetEvent(done_event);
        return S_OK;
      });

  hr = async_op->put_Completed(completed_cb.Get());
  if (FAILED(hr)) {
    if (out_error_hint) *out_error_hint = "put_Completed failed";
    CloseHandle(done_event);
    cleanup_ro();
    return false;
  }

  DWORD wait_res = WaitForSingleObject(done_event, 4000);
  CloseHandle(done_event);
  if (wait_res == WAIT_TIMEOUT) {
    if (out_error_hint) *out_error_hint = "Windows OCR timeout (>4s)";
    cleanup_ro();
    return false;
  }

  ComPtr<ABI::Windows::Media::Ocr::IOcrResult> ocr_result;
  hr = async_op->GetResults(&ocr_result);
  if (FAILED(hr) || !ocr_result) {
    if (out_error_hint) *out_error_hint = "GetResults failed";
    cleanup_ro();
    return false;
  }

  ComPtr<ABI::Windows::Foundation::Collections::IVectorView<
      ABI::Windows::Media::Ocr::OcrLine*>>
      lines_view;
  hr = ocr_result->get_Lines(&lines_view);
  if (FAILED(hr) || !lines_view) {
    cleanup_ro();
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

  cleanup_ro();
  return true;
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
  CleanupSnippingOverlay();
  HideScanRegionBorder();
  ClearOverlayBorders();
  HideFloatingHud();
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
    StartDesktopSnipping(std::move(result));
    return;
  }

  if (method == "captureRegion") {
    const auto* args =
        std::get_if<flutter::EncodableMap>(call.arguments());
    if (!args) {
      result->Success(flutter::EncodableValue());
      return;
    }
    result->Success(CaptureRegion(*args));
    return;
  }

  if (method == "captureWindow") {
    const auto* args =
        std::get_if<flutter::EncodableMap>(call.arguments());
    if (!args) {
      result->Success(flutter::EncodableValue());
      return;
    }
    result->Success(CaptureWindow(*args));
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
    const int vx = GetSystemMetrics(SM_XVIRTUALSCREEN);
    const int vy = GetSystemMetrics(SM_YVIRTUALSCREEN);
    const int vw = GetSystemMetrics(SM_CXVIRTUALSCREEN);
    const int vh = GetSystemMetrics(SM_CYVIRTUALSCREEN);
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
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (pending_snip_result_ || snip_hwnd_) {
    result->Success(flutter::EncodableValue());
    return;
  }

  virtual_x_ = GetSystemMetrics(SM_XVIRTUALSCREEN);
  virtual_y_ = GetSystemMetrics(SM_YVIRTUALSCREEN);
  virtual_w_ = GetSystemMetrics(SM_CXVIRTUALSCREEN);
  virtual_h_ = GetSystemMetrics(SM_CYVIRTUALSCREEN);
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
        L"Live-OCR-Bereich aufziehen: Bereich wird laufend gescannt  \u00B7  ESC = Abbrechen",
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
            L"\u2713 Live-OCR starten (Enter)", -1, &font_bold,
            Gdiplus::RectF(static_cast<float>(confirm_x),
                           static_cast<float>(btn_y),
                           static_cast<float>(confirm_w),
                           static_cast<float>(btn_h)),
            &sf, &white_brush);

        g.FillRectangle(&pill_bg, cancel_x, btn_y, cancel_w, btn_h);
        g.DrawRectangle(&pill_border, cancel_x, btn_y, cancel_w, btn_h);
        g.DrawString(
            L"Abbrechen", -1, &font_bold,
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

flutter::EncodableValue DesktopTrackerPlugin::CaptureRegion(
    const flutter::EncodableMap& args) {
  const int x = static_cast<int>(std::lround(GetDoubleArg(args, "x", 0.0)));
  const int y = static_cast<int>(std::lround(GetDoubleArg(args, "y", 0.0)));
  const int width =
      static_cast<int>(std::lround(GetDoubleArg(args, "width", 0.0)));
  const int height =
      static_cast<int>(std::lround(GetDoubleArg(args, "height", 0.0)));

  if (width <= 0 || height <= 0) {
    return flutter::EncodableValue();
  }

  HDC screen_dc = GetDC(nullptr);
  if (!screen_dc) return flutter::EncodableValue();

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
    return flutter::EncodableValue();
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
    return flutter::EncodableValue();
  }

  const size_t byte_count =
      static_cast<size_t>(width) * static_cast<size_t>(height) * 4;
  std::vector<uint8_t> bytes(byte_count);
  std::memcpy(bytes.data(), bits, byte_count);
  DeleteObject(dib);

  flutter::EncodableMap out;
  out[flutter::EncodableValue("width")] = flutter::EncodableValue(width);
  out[flutter::EncodableValue("height")] = flutter::EncodableValue(height);
  out[flutter::EncodableValue("pixelFormat")] =
      flutter::EncodableValue("bgra8888");
  out[flutter::EncodableValue("captureMethod")] =
      flutter::EncodableValue("bitblt_screen");
  out[flutter::EncodableValue("bytes")] =
      flutter::EncodableValue(std::move(bytes));
  return flutter::EncodableValue(std::move(out));
}

flutter::EncodableValue DesktopTrackerPlugin::CaptureWindow(
    const flutter::EncodableMap& args) {
  const int64_t hwnd_val = GetInt64Arg(args, "hwnd", 0);
  if (hwnd_val == 0) {
    return flutter::EncodableValue();
  }
  HWND target = reinterpret_cast<HWND>(hwnd_val);
  if (!IsWindow(target) || IsIconic(target)) {
    return flutter::EncodableValue();
  }

  RECT win_rect{};
  if (!GetWindowRect(target, &win_rect)) {
    return flutter::EncodableValue();
  }

  const int full_w = win_rect.right - win_rect.left;
  const int full_h = win_rect.bottom - win_rect.top;
  if (full_w <= 0 || full_h <= 0) {
    return flutter::EncodableValue();
  }

  int crop_x = 0;
  int crop_y = 0;
  int crop_w = full_w;
  int crop_h = full_h;

  auto crop_it = args.find(flutter::EncodableValue("cropRegion"));
  if (crop_it != args.end() &&
      std::holds_alternative<flutter::EncodableMap>(crop_it->second)) {
    const auto& cmap = std::get<flutter::EncodableMap>(crop_it->second);
    crop_x = max(0, static_cast<int>(std::lround(GetDoubleArg(cmap, "x", 0.0))));
    crop_y = max(0, static_cast<int>(std::lround(GetDoubleArg(cmap, "y", 0.0))));
    crop_w = static_cast<int>(
        std::lround(GetDoubleArg(cmap, "width", static_cast<double>(full_w))));
    crop_h = static_cast<int>(
        std::lround(GetDoubleArg(cmap, "height", static_cast<double>(full_h))));
    crop_w = min(crop_w, full_w - crop_x);
    crop_h = min(crop_h, full_h - crop_y);
  }

  if (crop_w <= 0 || crop_h <= 0) {
    return flutter::EncodableValue();
  }

  HDC screen_dc = GetDC(nullptr);
  if (!screen_dc) return flutter::EncodableValue();

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
    return flutter::EncodableValue();
  }

  HDC full_dc = CreateCompatibleDC(screen_dc);
  HGDIOBJ old_full = SelectObject(full_dc, full_dib);

  // PW_RENDERFULLCONTENT = 2 (Windows 8.1+) captures DWM/hardware surfaces cleanly
  std::string capture_method = "printwindow_pw2";
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
    return flutter::EncodableValue();
  }

  const size_t out_bytes_len =
      static_cast<size_t>(crop_w) * static_cast<size_t>(crop_h) * 4;
  std::vector<uint8_t> out_bytes(out_bytes_len);

  const auto* src_bytes = static_cast<const uint8_t*>(full_bits);
  const size_t src_stride = static_cast<size_t>(full_w) * 4;
  const size_t dst_stride = static_cast<size_t>(crop_w) * 4;
  for (int row = 0; row < crop_h; ++row) {
    const size_t src_off =
        static_cast<size_t>(crop_y + row) * src_stride +
        static_cast<size_t>(crop_x) * 4;
    std::memcpy(out_bytes.data() + static_cast<size_t>(row) * dst_stride,
                src_bytes + src_off, dst_stride);
  }

  SelectObject(full_dc, old_full);
  DeleteDC(full_dc);
  DeleteObject(full_dib);
  ReleaseDC(nullptr, screen_dc);

  flutter::EncodableMap out;
  out[flutter::EncodableValue("width")] = flutter::EncodableValue(crop_w);
  out[flutter::EncodableValue("height")] = flutter::EncodableValue(crop_h);
  out[flutter::EncodableValue("pixelFormat")] =
      flutter::EncodableValue("bgra8888");
  out[flutter::EncodableValue("captureMethod")] =
      flutter::EncodableValue(capture_method);
  out[flutter::EncodableValue("bytes")] =
      flutter::EncodableValue(std::move(out_bytes));
  return flutter::EncodableValue(std::move(out));
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
  HWND notify_hwnd = dispatcher_hwnd_;
  auto* payload = new OcrAsyncPayload();
  payload->result = std::move(result);
  payload->resolved_language_tag = language_tag;
  payload->requested_language_tag = language_tag;

  std::thread([notify_hwnd, payload, bytes = std::move(bytes), width, height,
               language_tag, preprocess_profile]() mutable {
    const auto t0 = std::chrono::steady_clock::now();
    payload->success = RunWindowsMediaOcr(
        bytes, width, height, language_tag, preprocess_profile, &payload->lines,
        &payload->used_fallback_language, &payload->resolved_language_tag,
        &payload->available_languages, &payload->error_hint);
    const auto t1 = std::chrono::steady_clock::now();
    payload->ocr_duration_ms =
        std::chrono::duration_cast<std::chrono::milliseconds>(t1 - t0).count();
    if (!PostMessageW(notify_hwnd, kMsgOcrComplete, 0,
                      reinterpret_cast<LPARAM>(payload))) {
      delete payload;
    }
  }).detach();
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

void DesktopTrackerPlugin::PositionHudFromAnchor() {
  const int hud_w = hud_state_.is_compact ? kHudWidthCompact : kHudWidthNormal;
  const int hud_h =
      hud_state_.is_compact ? kHudHeightCompact : kHudHeightNormal;

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
    const int hud_h =
        hud_state_.is_compact ? kHudHeightCompact : kHudHeightNormal;

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
  const int hud_h =
      hud_state_.is_compact ? kHudHeightCompact : kHudHeightNormal;
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
  const int h = hud_state_.is_compact ? kHudHeightCompact : kHudHeightNormal;

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

    if (!hud_state_.has_event) {
      g.DrawString(L"Warte auf Spiel-Ereignis...", -1, &font_name,
                   Gdiplus::RectF(14.0f, 34.0f, static_cast<float>(w - 28),
                                  36.0f),
                   &sf_left, &muted_brush);
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
      if (hud_state_.pokemon_id > 0) {
        swprintf_s(status_line, L"%s  \u00B7  #%03d",
                   hud_state_.is_caught ? L"\u2714 Gefangen"
                                        : L"\u26A0 Fehlt im Ziel-Dex",
                   hud_state_.pokemon_id);
      } else {
        swprintf_s(status_line, L"%s",
                   hud_state_.is_caught ? L"\u2714 Gefangen"
                                        : L"\u26A0 Fehlt im Ziel-Dex");
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

        wchar_t footer[64]{};
        swprintf_s(footer, L"Deckkraft: %d%%  \u00B7  Ziehen zum Verschieben",
                   static_cast<int>(std::lround(hud_state_.opacity * 100.0)));
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
        const int hud_h = self->hud_state_.is_compact ? kHudHeightCompact
                                                      : kHudHeightNormal;
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
      SetPropW(entry.hwnd, L"PV_BORDER_LABEL",
               reinterpret_cast<HANDLE>(new std::wstring(label)));
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
          HFONT font = CreateFontW(
              11, 0, 0, 0, FW_BOLD, FALSE, FALSE, FALSE, DEFAULT_CHARSET,
              OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY,
              DEFAULT_PITCH | FF_SWISS, L"Segoe UI");
          HGDIOBJ old_font = font ? SelectObject(hdc, font) : nullptr;
          DrawTextW(hdc, lbl->c_str(), -1, &text_rc,
                    DT_LEFT | DT_VCENTER | DT_SINGLELINE | DT_END_ELLIPSIS);
          if (old_font) SelectObject(hdc, old_font);
          if (font) DeleteObject(font);
        }
        EndPaint(hwnd, &ps);
      }
      return 0;
    }
  }

  return DefWindowProcW(hwnd, msg, wparam, lparam);
}
