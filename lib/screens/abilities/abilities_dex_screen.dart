import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_translations.dart';
import '../../models/special_dex_models.dart';
import '../../models/user_dex.dart';
import '../../services/database_service.dart';
import 'ability_detail_screen.dart';

class AbilitiesDexScreen extends StatefulWidget {
  final UserDex dex;
  const AbilitiesDexScreen({super.key, required this.dex});

  @override
  State<AbilitiesDexScreen> createState() => _AbilitiesDexScreenState();
}

class _AbilitiesDexScreenState extends State<AbilitiesDexScreen> {
  List<PokeAbility> _allAbilities = [];
  List<PokeAbility> _filteredAbilities = [];
  String _searchQuery = '';
  bool _isLoading = true;
  late bool _isGridView;

  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _isGridView = widget.dex.viewMode == 'grid';
    _loadAbilities();
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadAbilities() async {
    final abilities = await DatabaseService.instance.getAllAbilities();
    if (mounted) {
      setState(() {
        _allAbilities = abilities;
        _applyFiltersAndSort();
        _isLoading = false;
      });
    }
  }

  void _applyFiltersAndSort() {
    final lowerQuery = _searchQuery.toLowerCase();
    final lang = Translator.currentLanguage;

    var result = _allAbilities.where((a) {
      if (lowerQuery.isEmpty) return true;
      return a.getName(lang).toLowerCase().contains(lowerQuery);
    }).toList();

    result.sort((a, b) => a.getName(lang).compareTo(b.getName(lang)));

    setState(() {
      _filteredAbilities = result;
    });
  }

  Future<void> _toggleViewMode() async {
    setState(() {
      _isGridView = !_isGridView;
      widget.dex.viewMode = _isGridView ? 'grid' : 'list';
    });
    await DatabaseService.instance.saveUserDex(widget.dex);
  }

  void _toggleCaught(PokeAbility ability) {
    final uniqueId = 'ability_${ability.id}';
    setState(() {
      if (widget.dex.caughtIds.contains(uniqueId)) {
        widget.dex.caughtIds.remove(uniqueId);
        DatabaseService.instance.savePokemonStatus(
          widget.dex.id,
          uniqueId,
          isCaught: false,
        );
      } else {
        widget.dex.caughtIds.add(uniqueId);
        DatabaseService.instance.savePokemonStatus(
          widget.dex.id,
          uniqueId,
          isCaught: true,
        );
      }
    });
  }

  void _openDetails(PokeAbility ability) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AbilityDetailScreen(ability: ability),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Translator.currentLanguage;
    final caughtCount = widget.dex.caughtIds
        .where((id) => id.startsWith('ability_'))
        .length;

    return PopScope(
      canPop: !_searchFocusNode.hasFocus,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _searchFocusNode.unfocus();
        }
      },
      child: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.backspace ||
                event.logicalKey == LogicalKeyboardKey.browserBack) {
              if (_searchFocusNode.hasFocus) {
                return KeyEventResult.ignored;
              }
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
                return KeyEventResult.handled;
              }
            }
          }
          return KeyEventResult.ignored;
        },
        child: Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Translator.get('dex_abilities', fallback: 'Fähigkeiten-Dex'),
                ),
                Text(
                  '$caughtCount / ${_allAbilities.length} ${Translator.get('registered', fallback: 'Registriert')}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
                onPressed: _toggleViewMode,
                tooltip: 'Ansicht wechseln',
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  focusNode: _searchFocusNode,
                  onChanged: (val) {
                    _searchQuery = val;
                    _applyFiltersAndSort();
                  },
                  decoration: InputDecoration(
                    hintText: Translator.get('search', fallback: 'Suchen...'),
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _isGridView
              ? GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _filteredAbilities.length,
                  itemBuilder: (context, index) =>
                      _buildGridItem(_filteredAbilities[index], lang),
                )
              : ListView.separated(
                  itemCount: _filteredAbilities.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, indent: 56),
                  itemBuilder: (context, index) =>
                      _buildListItem(_filteredAbilities[index], lang),
                ),
        ),
      ),
    );
  }

  Widget _buildGridItem(PokeAbility ability, String lang) {
    final isCaught = widget.dex.caughtIds.contains('ability_${ability.id}');
    return GestureDetector(
      onSecondaryTap: () => _openDetails(ability),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: isCaught
            ? Colors.green.withValues(alpha: 0.15)
            : Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isCaught ? Colors.green : Colors.transparent,
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: () => _toggleCaught(ability),
          onLongPress: () => _openDetails(ability),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Icon(
                    isCaught ? Icons.check_circle : Icons.circle_outlined,
                    color: isCaught
                        ? Colors.green
                        : Colors.grey.withValues(alpha: 0.5),
                    size: 18,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      ability.getName(lang),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
                Text(
                  ability.getDesc(lang),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(PokeAbility ability, String lang) {
    final isCaught = widget.dex.caughtIds.contains('ability_${ability.id}');
    return GestureDetector(
      onSecondaryTap: () => _openDetails(ability),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: IconButton(
          icon: Icon(
            isCaught ? Icons.check_circle : Icons.circle_outlined,
            color: isCaught ? Colors.green : Colors.grey,
          ),
          onPressed: () => _toggleCaught(ability),
        ),
        title: Text(
          ability.getName(lang),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          ability.getDesc(lang),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
        ),
        onTap: () => _toggleCaught(ability),
        onLongPress: () => _openDetails(ability),
      ),
    );
  }
}
