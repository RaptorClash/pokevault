import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_translations.dart';
import '../../models/special_dex_models.dart';
import '../../models/user_dex.dart';
import '../../services/database_service.dart';
import 'move_detail_screen.dart';

class MovesDexScreen extends StatefulWidget {
  final UserDex dex;
  const MovesDexScreen({super.key, required this.dex});

  @override
  State<MovesDexScreen> createState() => _MovesDexScreenState();
}

class _MovesDexScreenState extends State<MovesDexScreen> {
  List<PokeMove> _allMoves = [];
  List<PokeMove> _filteredMoves = [];
  String _searchQuery = '';
  String _sortMode = 'az';
  bool _isLoading = true;
  late bool _isGridView;

  final FocusNode _searchFocusNode = FocusNode();

  final List<String> _types = [
    'all',
    'normal',
    'fire',
    'water',
    'electric',
    'grass',
    'ice',
    'fighting',
    'poison',
    'ground',
    'flying',
    'psychic',
    'bug',
    'rock',
    'ghost',
    'dragon',
    'dark',
    'steel',
    'fairy',
  ];

  @override
  void initState() {
    super.initState();
    _isGridView = widget.dex.viewMode == 'grid';
    _loadMoves();
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadMoves() async {
    final moves = await DatabaseService.instance.getAllMoves();
    if (mounted) {
      setState(() {
        _allMoves = moves;
        _applyFiltersAndSort();
        _isLoading = false;
      });
    }
  }

  void _applyFiltersAndSort() {
    final lowerQuery = _searchQuery.toLowerCase();
    final lang = Translator.currentLanguage;

    var result = _allMoves.where((m) {
      if (lowerQuery.isEmpty) return true;
      final typeName = Translator.get(
        'type_${m.type.toLowerCase()}',
        fallback: m.type,
      ).toLowerCase();
      return m.getName(lang).toLowerCase().contains(lowerQuery) ||
          typeName.contains(lowerQuery);
    }).toList();

    if (_sortMode == 'type') {
      result.sort((a, b) {
        final typeA = Translator.get(
          'type_${a.type.toLowerCase()}',
          fallback: a.type,
        );
        final typeB = Translator.get(
          'type_${b.type.toLowerCase()}',
          fallback: b.type,
        );
        int typeCmp = typeA.compareTo(typeB);
        if (typeCmp != 0) return typeCmp;
        return a.getName(lang).compareTo(b.getName(lang));
      });
    } else {
      result.sort((a, b) => a.getName(lang).compareTo(b.getName(lang)));
    }

    setState(() {
      _filteredMoves = result;
    });
  }

  Future<void> _toggleViewMode() async {
    setState(() {
      _isGridView = !_isGridView;
      widget.dex.viewMode = _isGridView ? 'grid' : 'list';
    });
    await DatabaseService.instance.saveUserDex(widget.dex);
  }

  void _toggleCaught(PokeMove move) {
    final uniqueId = 'move_${move.id}';
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

  void _openDetails(PokeMove move) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MoveDetailScreen(move: move)),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'normal':
        return const Color(0xFFA8A77A);
      case 'fire':
        return const Color(0xFFEE8130);
      case 'water':
        return const Color(0xFF6390F0);
      case 'electric':
        return const Color(0xFFF7D02C);
      case 'grass':
        return const Color(0xFF7AC74C);
      case 'ice':
        return const Color(0xFF96D9D6);
      case 'fighting':
        return const Color(0xFFC22E28);
      case 'poison':
        return const Color(0xFFA33EA1);
      case 'ground':
        return const Color(0xFFE2BF65);
      case 'flying':
        return const Color(0xFFA98FF3);
      case 'psychic':
        return const Color(0xFFF95587);
      case 'bug':
        return const Color(0xFFA6B91A);
      case 'rock':
        return const Color(0xFFB6A136);
      case 'ghost':
        return const Color(0xFF735797);
      case 'dragon':
        return const Color(0xFF6F35FC);
      case 'dark':
        return const Color(0xFF705848);
      case 'steel':
        return const Color(0xFFB7B7CE);
      case 'fairy':
        return const Color(0xFFD685AD);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Translator.currentLanguage;
    final caughtCount = widget.dex.caughtIds
        .where((id) => id.startsWith('move_'))
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
                Text(Translator.get('dex_moves', fallback: 'Attacken-Dex')),
                Text(
                  '$caughtCount / ${_allMoves.length} ${Translator.get('registered', fallback: 'Registriert')}',
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
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort),
                tooltip: Translator.get('sort_by', fallback: 'Sortieren'),
                onSelected: (val) {
                  _sortMode = val;
                  _applyFiltersAndSort();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'az',
                    child: Text(
                      Translator.get('sort_az', fallback: 'A - Z'),
                      style: TextStyle(
                        fontWeight: _sortMode == 'az'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'type',
                    child: Text(
                      Translator.get(
                        'sort_type',
                        fallback: 'Nach Typ gruppieren',
                      ),
                      style: TextStyle(
                        fontWeight: _sortMode == 'type'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
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
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _filteredMoves.length,
                  itemBuilder: (context, index) =>
                      _buildGridItem(_filteredMoves[index], lang),
                )
              : ListView.separated(
                  itemCount: _filteredMoves.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, indent: 56),
                  itemBuilder: (context, index) =>
                      _buildListItem(_filteredMoves[index], lang),
                ),
        ),
      ),
    );
  }

  Widget _buildGridItem(PokeMove move, String lang) {
    final isCaught = widget.dex.caughtIds.contains('move_${move.id}');
    return GestureDetector(
      onSecondaryTap: () => _openDetails(move),
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
          onTap: () => _toggleCaught(move),
          onLongPress: () => _openDetails(move),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
                      move.getName(lang),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getTypeColor(move.type),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    Translator.get(
                      'type_${move.type.toLowerCase()}',
                      fallback: move.type.toUpperCase(),
                    ),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${Translator.get('power_short', fallback: 'Stärke')}: ${move.power > 0 ? move.power : '-'}',
                  style: TextStyle(
                    fontSize: 11,
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

  Widget _buildListItem(PokeMove move, String lang) {
    final isCaught = widget.dex.caughtIds.contains('move_${move.id}');
    final typeStr = Translator.get(
      'type_${move.type.toLowerCase()}',
      fallback: move.type.toUpperCase(),
    );

    return GestureDetector(
      onSecondaryTap: () => _openDetails(move),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: IconButton(
          icon: Icon(
            isCaught ? Icons.check_circle : Icons.circle_outlined,
            color: isCaught ? Colors.green : Colors.grey,
          ),
          onPressed: () => _toggleCaught(move),
        ),
        title: Text(
          move.getName(lang),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          'Typ: $typeStr | Stärke: ${move.power > 0 ? move.power : '-'}',
          style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
        ),
        onTap: () => _toggleCaught(move),
        onLongPress: () => _openDetails(move),
      ),
    );
  }
}
