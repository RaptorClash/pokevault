import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../i18n/strings.g.dart';
import '../../utils/update_helper.dart';

/// Shared Markdown renderer for update and downgrade release notes.
class ReleaseNotesMarkdown extends StatelessWidget {
  final String releaseNotes;

  const ReleaseNotesMarkdown({
    super.key,
    required this.releaseNotes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bodyMedium = theme.textTheme.bodyMedium;
    final bodyStyle = bodyMedium?.copyWith(fontSize: 14) ??
        const TextStyle(fontSize: 14);

    return MarkdownBody(
      data: UpdateHelper.filterReleaseNotes(
        releaseNotes,
        LocaleSettings.currentLocale.languageCode,
      ),
      selectable: true,
      softLineBreak: true,
      styleSheet: MarkdownStyleSheet(
        a: TextStyle(color: theme.colorScheme.primary),
        p: bodyStyle,
        pPadding: EdgeInsets.zero,
        code: bodyStyle.copyWith(
          backgroundColor: theme.cardTheme.color ?? theme.cardColor,
          fontFamily: 'monospace',
          fontSize: 12,
        ),
        h1: theme.textTheme.titleLarge?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ) ??
            const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        h1Padding: EdgeInsets.zero,
        h2: theme.textTheme.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ) ??
            const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        h2Padding: EdgeInsets.zero,
        h3: theme.textTheme.titleSmall?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ) ??
            const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        h3Padding: EdgeInsets.zero,
        em: const TextStyle(fontStyle: FontStyle.italic),
        strong: const TextStyle(fontWeight: FontWeight.bold),
        del: const TextStyle(decoration: TextDecoration.lineThrough),
        blockquote: bodyStyle,
        blockquotePadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
        blockquoteDecoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(3),
          border: Border(
            left: BorderSide(color: theme.colorScheme.primary, width: 3),
          ),
        ),
        codeblockPadding: const EdgeInsets.all(8.0),
        codeblockDecoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.cardColor,
          borderRadius: BorderRadius.circular(2.0),
        ),
        blockSpacing: 8.0,
        listIndent: 24.0,
        listBullet: bodyStyle,
        listBulletPadding: const EdgeInsets.only(right: 4),
      ),
      onTapLink: (text, href, title) async {
        if (href == null) return;
        final uri = Uri.tryParse(href);
        if (uri == null) return;
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (e) {
          debugPrint('Could not launch URL: $e');
        }
      },
    );
  }
}
