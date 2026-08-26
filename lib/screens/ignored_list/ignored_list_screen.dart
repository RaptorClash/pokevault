import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dex_view_models.dart';
import '../../providers/dex_provider.dart';
import '../../providers/tutorial_provider.dart';
import '../../models/tutorial_step.dart';
import '../../widgets/tutorial/tutorial_overlay.dart';
import '../../l10n/app_translations.dart';

class IgnoredListScreen extends StatefulWidget {
  final String dexId;
  final List<DexDisplayEntry> allRawEntries;

  const IgnoredListScreen({
    super.key,
    required this.dexId,
    required this.allRawEntries,
  });

  @override
  State<IgnoredListScreen> createState() => _IgnoredListScreenState();
}

class _IgnoredListScreenState extends State<IgnoredListScreen> {
  final GlobalKey _restoreBtnKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTutorialIfNeeded();
    });
  }

  void _showTutorialIfNeeded() {
    final tutProvider = Provider.of<TutorialProvider>(context, listen: false);

    if (!tutProvider.hasSeenFeature('ignored_restore')) {
      TutorialOverlay.show(
        context,
        TutorialFeature(
          id: 'ignored_restore',
          nameKey: 'tutorial_feature_details',
          steps: [
            TutorialStep(
              targetKey: _restoreBtnKey,
              titleKey: 'tutorial_ignored_restore_title',
              textKey: 'tutorial_ignored_restore_text',
              requireTargetTap: true,
              onTargetTap: () {
                final provider = context.read<DexProvider>();
                final liveDex = provider.userDexes.firstWhere(
                  (d) => d.id == widget.dexId,
                );
                final ignoredEntries = widget.allRawEntries
                    .where(
                      (entry) => liveDex.ignoredIds.contains(entry.uniqueId),
                    )
                    .toList();

                if (ignoredEntries.isNotEmpty) {
                  provider.restorePokemon(
                    widget.dexId,
                    ignoredEntries.first.uniqueId,
                  );
                }

                tutProvider.markFeatureAsSeen('ignored_restore');
                Navigator.pop(context);
              },
            ),
          ],
        ),
        () => tutProvider.markFeatureAsSeen('ignored_restore'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DexProvider>();
    final liveDex = provider.userDexes.firstWhere((d) => d.id == widget.dexId);
    final ignoredEntries = widget.allRawEntries
        .where((entry) => liveDex.ignoredIds.contains(entry.uniqueId))
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(Translator.get('ignored_list_title'))),
      body: ignoredEntries.isEmpty
          ? Center(child: Text(Translator.get('empty_ignored')))
          : ListView.builder(
              itemCount: ignoredEntries.length,
              itemBuilder: (context, index) {
                final entry = ignoredEntries[index];
                return ListTile(
                  leading: Image.network(entry.imageUrl, width: 50, height: 50),
                  title: Text(
                    entry.pokemon.getName(provider.currentLanguage) +
                        entry.displaySuffix,
                  ),
                  subtitle: Text(
                    '#${entry.pokemon.id.toString().padLeft(3, '0')}',
                  ),
                  trailing: ElevatedButton.icon(
                    key: index == 0
                        ? _restoreBtnKey
                        : null,
                    icon: const Icon(Icons.restore),
                    label: Text(Translator.get('restore_pokemon')),
                    onPressed: () {
                      provider.restorePokemon(widget.dexId, entry.uniqueId);
                    },
                  ),
                );
              },
            ),
    );
  }
}
