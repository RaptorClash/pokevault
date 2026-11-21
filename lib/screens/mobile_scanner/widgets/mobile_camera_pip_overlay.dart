import 'package:flutter/material.dart';
import '../../../i18n/strings.g.dart';
import '../../../services/mobile_scanner/camera_scan_region.dart';
import '../../../services/mobile_scanner/mobile_camera_tracker_service.dart';
import '../../../services/scanner_core/models/scanner_event.dart';

/// App-wide draggable Picture-in-Picture (PiP) camera overlay rendered inside
/// `MaterialApp.builder` so users can navigate PokéVault freely while scanning.
class MobileCameraPipOverlay extends StatelessWidget {
  final MobileCameraTrackerService service;
  final VoidCallback? onExpand;
  final VoidCallback? onClose;

  static const Size defaultPipSize = Size(172, 148);

  const MobileCameraPipOverlay({
    super.key,
    required this.service,
    this.onExpand,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: service.isPipVisibleNotifier,
      builder: (context, visible, _) {
        if (!visible) return const SizedBox.shrink();

        final screenSize = MediaQuery.sizeOf(context);
        final safePadding = MediaQuery.paddingOf(context);

        return ValueListenableBuilder<Offset>(
          valueListenable: service.pipPositionNotifier,
          builder: (context, pos, _) {
            final maxX = (screenSize.width - safePadding.right - defaultPipSize.width - 8)
                .clamp(safePadding.left + 8, screenSize.width);
            final maxY = (screenSize.height - safePadding.bottom - defaultPipSize.height - 8)
                .clamp(safePadding.top + 8, screenSize.height);
            final clampedX = pos.dx.clamp(safePadding.left + 8, maxX).toDouble();
            final clampedY = pos.dy.clamp(safePadding.top + 8, maxY).toDouble();

            return Positioned(
              left: clampedX,
              top: clampedY,
              width: defaultPipSize.width,
              height: defaultPipSize.height,
              child: Material(
                color: Colors.transparent,
                child: ValueListenableBuilder<ScannerEvent?>(
                  valueListenable: service.latestEventNotifier,
                  builder: (context, latestEvent, _) {
                    final isShiny = latestEvent?.isShiny ?? false;
                    return Container(
                      key: const Key('mobile_pip_window'),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141420),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isShiny
                              ? const Color(0xFFFBC02D)
                              : Colors.cyanAccent.withValues(alpha: 0.7),
                          width: isShiny ? 2.2 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.55),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              key: const Key('mobile_pip_drag_area'),
                              behavior: HitTestBehavior.opaque,
                              onPanUpdate: (details) {
                                service.updatePipPosition(
                                  Offset(clampedX, clampedY) + details.delta,
                                  screenSize: screenSize,
                                  safePadding: safePadding,
                                  pipSize: defaultPipSize,
                                );
                              },
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  _buildAspectAlignedStage(context),
                                  _buildTopControls(context, latestEvent),
                                  _buildBottomEventBadge(latestEvent),
                                ],
                              ),
                            ),
                          ),
                          _buildFooterBar(),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAspectAlignedStage(BuildContext context) {
    return ValueListenableBuilder<double?>(
      valueListenable: service.previewAspectRatioNotifier,
      builder: (context, aspect, _) {
        final content = Stack(
          fit: StackFit.expand,
          children: [
            _buildPreviewFeed(context),
            _buildMiniRectangles(),
          ],
        );
        if (aspect == null || aspect <= 0) {
          return content;
        }
        return Container(
          color: const Color(0xFF0E111A),
          child: Center(
            child: AspectRatio(
              aspectRatio: aspect,
              child: content,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreviewFeed(BuildContext context) {
    final builder = service.pipCameraPreviewBuilder;
    if (builder != null) {
      return ClipRect(child: builder(context));
    }
    return Container(
      color: const Color(0xFF191D2A),
      child: const Center(
        child: Icon(Icons.videocam, color: Colors.white24, size: 28),
      ),
    );
  }

  Widget _buildMiniRectangles() {
    return ValueListenableBuilder<MobileCameraScanMode>(
      valueListenable: service.scanModeNotifier,
      builder: (context, mode, _) {
        if (mode == MobileCameraScanMode.autoFull) {
          return IgnorePointer(
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.55),
                ),
              ),
            ),
          );
        }
        return ValueListenableBuilder<List<NormalizedScanRect>>(
          valueListenable: service.regionsNotifier,
          builder: (context, regions, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    for (final r in regions.where((e) => e.enabled))
                      Positioned(
                        left: r.left * constraints.maxWidth,
                        top: r.top * constraints.maxHeight,
                        width: r.width * constraints.maxWidth,
                        height: r.height * constraints.maxHeight,
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Color(r.colorHex), width: 1.3),
                              color: Color(r.colorHex).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTopControls(BuildContext context, ScannerEvent? latestEvent) {
    return Positioned(
      top: 4,
      left: 4,
      right: 4,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: service.isPausedNotifier,
            builder: (context, isPaused, _) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isPaused ? Colors.amber : Colors.greenAccent,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPaused
                          ? t.scanner_pause_suffix.toUpperCase()
                          : t.scanner_dock_live,
                      style: TextStyle(
                        color: isPaused ? Colors.amber : Colors.greenAccent,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _miniIconButton(
                key: const Key('btn_pip_expand'),
                icon: Icons.open_in_full,
                tooltip: t.scanner_mob_pip_enlarge,
                onTap: () {
                  if (onExpand != null) {
                    onExpand!();
                  } else {
                    service.triggerExpandFromPip();
                  }
                },
              ),
              const SizedBox(width: 4),
              _miniIconButton(
                key: const Key('btn_pip_close'),
                icon: Icons.close,
                iconColor: Colors.redAccent,
                tooltip: t.scanner_dock_close_tooltip,
                onTap: () {
                  if (onClose != null) {
                    onClose!();
                  } else {
                    service.stopSession();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomEventBadge(ScannerEvent? latestEvent) {
    final text = latestEvent != null
        ? '${latestEvent.isShiny ? '✨ ' : ''}${latestEvent.matchedName}'
        : t.scanner_mob_pip_scanning;
    return Positioned(
      left: 4,
      right: 4,
      bottom: 4,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.76),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: (latestEvent?.isShiny ?? false)
                ? const Color(0xFFFDD835)
                : Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildFooterBar() {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: const Color(0xFF1A1A28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.drag_indicator, size: 13, color: Colors.white54),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Bewegbar',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white60, fontSize: 9),
              ),
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: service.torchEnabledNotifier,
            builder: (context, torchOn, _) {
              return InkWell(
                key: const Key('btn_pip_torch'),
                onTap: () => service.toggleTorchFromPip(),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Icon(
                    torchOn ? Icons.flashlight_on : Icons.flashlight_off,
                    size: 13,
                    color: torchOn ? Colors.amber : Colors.white60,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
          ValueListenableBuilder<bool>(
            valueListenable: service.isPausedNotifier,
            builder: (context, isPaused, _) {
              return InkWell(
                key: const Key('btn_pip_toggle_pause'),
                onTap: service.togglePause,
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Icon(
                    isPaused ? Icons.play_arrow : Icons.pause,
                    size: 14,
                    color: isPaused ? Colors.greenAccent : Colors.amber,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _miniIconButton({
    required Key key,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        key: key,
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 13, color: iconColor),
        ),
      ),
    );
  }
}
