import 'package:flutter/material.dart';
import '../../../../i18n/strings.g.dart';

/// Action buttons footer (Copy text, Share, Save PNG) for [DexCompletionCardDialog].
class CompletionCardActionsBar extends StatelessWidget {
  final bool isExporting;
  final VoidCallback onCopyText;
  final VoidCallback? onShare;
  final VoidCallback? onSavePng;
  final Color borderColor;
  final bool isDark;

  const CompletionCardActionsBar({
    super.key,
    required this.isExporting,
    required this.onCopyText,
    required this.onShare,
    required this.onSavePng,
    required this.borderColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B222E) : Colors.grey.shade100,
        border: Border(top: BorderSide(color: borderColor)),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // 1. Text kopieren
            OutlinedButton.icon(
              key: const Key('btn_copy_text'),
              icon: const Icon(Icons.copy, size: 16),
              label: Text(
                t.dex_card_copy_text,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              onPressed: onCopyText,
            ),
            const SizedBox(width: 8),

            // 2. Teilen (WhatsApp, Twitter/X, Discord)
            OutlinedButton.icon(
              key: const Key('btn_share'),
              icon: const Icon(Icons.share, size: 16),
              label: Text(
                t.dex_card_share,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              onPressed: isExporting ? null : onShare,
            ),
            const SizedBox(width: 8),

            // 3. Als PNG speichern (Download)
            ElevatedButton.icon(
              key: const Key('btn_save_png'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
              icon: isExporting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download, size: 16),
              label: Text(
                t.dex_card_save_png,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              onPressed: isExporting ? null : onSavePng,
            ),
          ],
        ),
      ),
    );
  }
}
