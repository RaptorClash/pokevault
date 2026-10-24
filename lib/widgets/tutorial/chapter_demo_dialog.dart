import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../models/tutorial_step.dart';
import '../../providers/tutorial_provider.dart';
import '../../l10n/app_translations.dart';
import '../../constants/app_vectors.dart';

class ChapterDemoDialog extends StatefulWidget {
  final TutorialChapter chapter;
  final VoidCallback? onTryInScreen;

  const ChapterDemoDialog({
    super.key,
    required this.chapter,
    this.onTryInScreen,
  });

  static Future<void> show(
    BuildContext context,
    TutorialChapter chapter, {
    VoidCallback? onTryInScreen,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ChapterDemoDialog(
        chapter: chapter,
        onTryInScreen: onTryInScreen,
      ),
    );
  }

  @override
  State<ChapterDemoDialog> createState() => _ChapterDemoDialogState();
}

class _ChapterDemoDialogState extends State<ChapterDemoDialog> {
  int _currentStepIndex = 0;

  List<TutorialStep> get _steps => widget.chapter.demoSteps.isNotEmpty
      ? widget.chapter.demoSteps
      : [
          TutorialStep(
            titleKey: widget.chapter.titleKey,
            textKey: widget.chapter.descKey,
            rotomMood: RotomMood.explaining,
          ),
        ];

  TutorialStep get _currentStep => _steps[_currentStepIndex];

  bool get _isLast => _currentStepIndex == _steps.length - 1;

  void _next() {
    if (!_isLast) {
      setState(() => _currentStepIndex++);
    } else {
      final tutProvider = Provider.of<TutorialProvider>(context, listen: false);
      tutProvider.markChapterSeen(widget.chapter.id);
      Navigator.of(context).pop();
    }
  }

  void _prev() {
    if (_currentStepIndex > 0) {
      setState(() => _currentStepIndex--);
    }
  }

  Widget _buildStepVisual(BuildContext context) {
    final theme = Theme.of(context);
    final chId = widget.chapter.id;

    Widget visual;

    if (chId == 'module_shiny_hunt') {
      visual = Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Translator.get('shiny_hunt_active', fallback: 'Aktiver Hunt: Encounters'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    '1 / 4096 (1 / 1365 mit Schillerpin)',
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (chId == 'module_box_management') {
      visual = Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (int i = 1; i <= 4; i++)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.4)),
                ),
                child: Center(
                  child: Icon(Icons.catching_pokemon, size: 22, color: theme.colorScheme.primary),
                ),
              ),
          ],
        ),
      );
    } else if (chId == 'module_stats_share') {
      visual = Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.teal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.verified, color: Colors.teal, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Translator.get('dex_card_mastered', fallback: 'Mastered: 100% Complete'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    Translator.get('dex_card_registered_pkv', fallback: 'Living Dex Diplome & PNG Share'),
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (chId == 'module_controls') {
      visual = Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.pinkAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3)),
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            for (final key in ['[LEERTASTE] +1 Counter', '[← / →] Box-Wechsel', '[STRG + F] Suchen', '[LONGPRESS] Details'])
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Text(
                  key,
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      );
    } else if (chId == 'module_backup_sync') {
      visual = Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.cyan.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_sync, color: Colors.cyan, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Google Drive Cloud & Auto-Backup',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    'Automatische Sicherung & SQLite Export',
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (chId == 'module_route_tracker') {
      visual = Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.indigoAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.indigoAccent.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map, color: Colors.indigoAccent, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Route 1 (Kanto) • 8 / 10 Gefangen',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    'Gebiets-Fortschritt & Fundort-Tracker',
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (chId == 'module_pokemon_info') {
      visual = Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.purple.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.male, color: Colors.blue, size: 22),
            const Icon(Icons.female, color: Colors.pink, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Geschlechtsunterschiede & Varianten',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    'Zucht, Bälle, Tera-Typen & Event-Status',
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (chId == 'module_home') {
      visual = Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_copy_outlined, color: Colors.amber, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sammlungen & Ordnerstruktur',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    'Dexe frei verschieben, sortieren & gruppieren',
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (chId == 'module_create_dex') {
      visual = Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle, color: Colors.orange, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Editions- & Filter-Auswahl',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    'Unter-Dexe, Shinys, Formen & Megas wählen',
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (chId == 'module_dex_screen') {
      visual = Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fang-Status & Ansichtsmodi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    'Listen- vs. Boxansicht, Tap zum Fangen',
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      visual = Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.chapter.icon, size: 24, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Text(
              'PokéVault Guide & Demo',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
            ),
          ],
        ),
      );
    }

    return visual;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _steps.length;
    final progress = total > 0 ? ((_currentStepIndex + 1) / total) : 1.0;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      backgroundColor: theme.colorScheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.chapter.icon, color: theme.colorScheme.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Translator.get(widget.chapter.titleKey),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Demo Modus • Schritt ${_currentStepIndex + 1} von $total',
                          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                ),
              ),

              const SizedBox(height: 16),

              // Rotom & Step content
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: SvgPicture.string(AppVectors.rotomDex),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Translator.get(_currentStep.titleKey),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          Translator.get(_currentStep.textKey),
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Visual demonstration
              _buildStepVisual(context),

              const SizedBox(height: 20),

              // Action row
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_currentStepIndex > 0)
                    TextButton.icon(
                      onPressed: _prev,
                      icon: const Icon(Icons.arrow_back, size: 14),
                      label: Text(Translator.get('previous', fallback: 'Zurück')),
                    )
                  else
                    const SizedBox.shrink(),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      if (_isLast && widget.onTryInScreen != null)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.onTryInScreen!();
                          },
                          icon: const Icon(Icons.rocket_launch_outlined, size: 14),
                          label: Text(
                            Translator.get('tutorial_try_now', fallback: 'Jetzt ausprobieren'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _next,
                        icon: Icon(_isLast ? Icons.check : Icons.arrow_forward, size: 14),
                        label: Text(
                          Translator.get(_isLast ? 'tutorial_finish' : 'tutorial_next', fallback: _isLast ? 'Abschließen' : 'Weiter'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
