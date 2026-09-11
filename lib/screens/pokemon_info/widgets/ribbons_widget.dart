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

class RibbonsWidget extends StatefulWidget {
  final DexDisplayEntry entry;
  final String dexId;
  final GlobalKey ribbonsKey;

  const RibbonsWidget({
    super.key,
    required this.entry,
    required this.dexId,
    required this.ribbonsKey,
  });

  @override
  State<RibbonsWidget> createState() => _RibbonsWidgetState();
}

class _RibbonsWidgetState extends State<RibbonsWidget> {
  List<Ribbon>? _ribbons;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRibbons();
  }

  Future<void> _loadRibbons() async {
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
        _ribbons = displayItems
            .where((r) => !r.id.toLowerCase().contains('mark'))
            .toList();
      });
    }
  }

  void _showRibbonInfo(BuildContext context, Ribbon ribbon, String lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            UniversalPokeImage(
              imageUrl: ribbon.imageUrl,
              width: 40,
              height: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                ribbon.getName(lang),
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
                ribbon.getDesc(lang),
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 16),
              if (ribbon.titleDe.isNotEmpty) ...[
                Text(
                  Translator.get('title', fallback: 'Titel:'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(ribbon.titleDe),
                const SizedBox(height: 12),
              ],
              if (ribbon.locationDe.isNotEmpty) ...[
                Text(
                  Translator.get('location', fallback: 'Fundort / Bedingung:'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(ribbon.locationDe),
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
    if (_ribbons == null) {
      return const SizedBox.shrink();
    }

    if (_ribbons!.isEmpty) {
      return const SizedBox.shrink();
    }

    final provider = context.watch<DexProvider>();
    final liveDex = provider.userDexes.firstWhere((d) => d.id == widget.dexId);
    List<String> earnedRibbons =
        liveDex.caughtRibbons[widget.entry.uniqueId] ?? [];
    final lang = Translator.currentLanguage;

    int earnedCount = _ribbons!
        .where((r) => earnedRibbons.contains(r.id))
        .length;

    final filteredRibbons = _ribbons!
        .where(
          (r) => r
              .getName(lang)
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()),
        )
        .toList();

    return Card(
      key: widget.ribbonsKey,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        maintainState: true,
        leading: const Icon(Icons.workspace_premium, color: Colors.amber),
        title: Row(
          children: [
            Expanded(
              child: Text(
                Translator.get('ribbons', fallback: 'Bänder'),
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
                '$earnedCount / ${_ribbons!.length}',
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
            itemCount: filteredRibbons.length,
            itemBuilder: (context, index) {
              final r = filteredRibbons[index];
              final isEarned = earnedRibbons.contains(r.id);
              return _buildItemCard(r, lang, isEarned, earnedRibbons, liveDex);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(
    Ribbon ribbon,
    String lang,
    bool isEarned,
    List<String> earnedRibbons,
    UserDex liveDex,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isEarned) {
            earnedRibbons.remove(ribbon.id);
          } else {
            earnedRibbons.add(ribbon.id);
          }
          liveDex.caughtRibbons[widget.entry.uniqueId] = earnedRibbons;
        });

        DatabaseService.instance.savePokemonStatus(
          widget.dexId,
          widget.entry.uniqueId,
          ribbons: earnedRibbons,
        );
      },
      onLongPress: () => _showRibbonInfo(context, ribbon, lang),
      onSecondaryTap: () => _showRibbonInfo(context, ribbon, lang),
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
                  child: UniversalPokeImage(imageUrl: ribbon.imageUrl),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  bottom: 8.0,
                  left: 4.0,
                  right: 4.0,
                ),
                child: Text(
                  ribbon.getName(lang),
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
