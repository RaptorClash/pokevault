import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/dex_view_models.dart';
import '../../../models/user_dex.dart';
import '../../../models/ribbon.dart';
import '../../../providers/dex_provider.dart';
import '../../../l10n/app_translations.dart';
import '../../../services/database_service.dart';
import '../../../utils/ribbons_logic_helper.dart';
import '../../../widgets/universal_poke_image.dart';

class MarksWidget extends StatefulWidget {
  final DexDisplayEntry entry;
  final String dexId;
  final GlobalKey marksKey;

  const MarksWidget({
    super.key,
    required this.entry,
    required this.dexId,
    required this.marksKey,
  });

  @override
  State<MarksWidget> createState() => _MarksWidgetState();
}

class _MarksWidgetState extends State<MarksWidget> {
  List<Ribbon>? _marks;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMarks();
  }

  Future<void> _loadMarks() async {
    final allRibbons = await DatabaseService.instance.getAllRibbons();
    final availableGames = await DatabaseService.instance
        .getAvailableVersionGroups(widget.entry.pokemon.id);
    final baseId = await DatabaseService.instance.getBasePokemonId(
      widget.entry.pokemon.evolutionChainId,
    );

    if (baseId != -1 && baseId != widget.entry.pokemon.id) {
      final baseGames = await DatabaseService.instance
          .getAvailableVersionGroups(baseId);
      for (var game in baseGames) {
        if (!availableGames.contains(game)) {
          availableGames.add(game);
        }
      }
    }

    final displayItems = RibbonLogicHelper.getValidRibbonsForPokemon(
      widget.entry.pokemon,
      baseId,
      allRibbons,
      availableGames,
    );

    if (mounted) {
      setState(() {
        _marks = displayItems
            .where((r) => r.id.toLowerCase().contains('mark'))
            .toList();
      });
    }
  }

  void _showMarkInfo(BuildContext context, Ribbon mark, String lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            UniversalPokeImage(imageUrl: mark.imageUrl, width: 40, height: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mark.getName(lang),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mark.getDesc(lang),
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 16),
              if (mark.titleDe.isNotEmpty) ...[
                Text(
                  Translator.get('title', fallback: 'Titel:'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(mark.titleDe),
                const SizedBox(height: 12),
              ],
              if (mark.locationDe.isNotEmpty) ...[
                Text(
                  Translator.get('location', fallback: 'Fundort / Bedingung:'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(mark.locationDe),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(Translator.get('close', fallback: 'Schließen')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_marks == null) {
      return const SizedBox.shrink();
    }

    if (_marks!.isEmpty) {
      return const SizedBox.shrink();
    }

    final provider = context.watch<DexProvider>();
    final liveDex = provider.userDexes.firstWhere((d) => d.id == widget.dexId);

    List<String> earnedRibbons =
        liveDex.caughtRibbons[widget.entry.uniqueId] ?? [];
    final lang = Translator.currentLanguage;
    int earnedCount = _marks!.where((m) => earnedRibbons.contains(m.id)).length;

    final filteredMarks = _marks!
        .where(
          (m) => m
              .getName(lang)
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()),
        )
        .toList();

    return Card(
      key: widget.marksKey,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        maintainState: true,
        leading: const Icon(Icons.stars, color: Colors.deepPurpleAccent),
        title: Row(
          children: [
            Expanded(
              child: Text(
                Translator.get('marks', fallback: 'Zeichen'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$earnedCount / ${_marks!.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              decoration: InputDecoration(
                labelText: Translator.get('search', fallback: 'Suchen...'),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 95,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.8,
            ),
            itemCount: filteredMarks.length,
            itemBuilder: (context, index) {
              final m = filteredMarks[index];
              final isEarned = earnedRibbons.contains(m.id);
              return _buildItemCard(m, lang, isEarned, earnedRibbons, liveDex);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(
    Ribbon mark,
    String lang,
    bool isEarned,
    List<String> earnedRibbons,
    UserDex liveDex,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isEarned) {
            earnedRibbons.remove(mark.id);
          } else {
            earnedRibbons.add(mark.id);
          }
          liveDex.caughtRibbons[widget.entry.uniqueId] = earnedRibbons;
        });
        DatabaseService.instance.savePokemonStatus(
          widget.dexId,
          widget.entry.uniqueId,
          ribbons: earnedRibbons,
        );
      },
      onLongPress: () => _showMarkInfo(context, mark, lang),
      onSecondaryTap: () => _showMarkInfo(context, mark, lang),
      child: Container(
        decoration: BoxDecoration(
          color: isEarned
              ? Colors.green.withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: isEarned
              ? Border.all(color: Colors.green, width: 1.5)
              : Border.all(color: Colors.transparent, width: 1.5),
        ),
        child: Opacity(
          opacity: isEarned ? 1.0 : 0.4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: UniversalPokeImage(imageUrl: mark.imageUrl),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  bottom: 8.0,
                  left: 4.0,
                  right: 4.0,
                ),
                child: Text(
                  mark.getName(lang),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: isEarned ? FontWeight.bold : FontWeight.normal,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
