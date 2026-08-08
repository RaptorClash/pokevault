import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dex_provider.dart';
import '../l10n/app_translations.dart';
import 'dex_screen.dart';

class IgnoredListScreen extends StatelessWidget {
  final String dexId;
  final List<DexDisplayEntry> allRawEntries;

  const IgnoredListScreen({
    super.key,
    required this.dexId,
    required this.allRawEntries,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DexProvider>();
    final liveDex = provider.userDexes.firstWhere((d) => d.id == dexId);
    
    final ignoredEntries = allRawEntries.where(
      (entry) => liveDex.ignoredIds.contains(entry.uniqueId)
    ).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(Translator.get('ignored_list_title')),
      ),
      body: ignoredEntries.isEmpty
          ? Center(child: Text(Translator.get('empty_ignored')))
          : ListView.builder(
              itemCount: ignoredEntries.length,
              itemBuilder: (context, index) {
                final entry = ignoredEntries[index];
                return ListTile(
                  leading: Image.network(
                    entry.imageUrl,
                    width: 50,
                    height: 50,
                  ),
                  title: Text(entry.pokemon.getName(provider.currentLanguage) + entry.displaySuffix),
                  subtitle: Text('#${entry.pokemon.id.toString().padLeft(3, '0')}'),
                  trailing: ElevatedButton.icon(
                    icon: const Icon(Icons.restore),
                    label: Text(Translator.get('restore_pokemon')),
                    onPressed: () {
                      provider.restorePokemon(dexId, entry.uniqueId);
                    },
                  ),
                );
              },
            ),
    );
  }
}