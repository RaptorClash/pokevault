import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dex_view_models.dart';
import '../../models/user_dex.dart';
import '../../providers/dex_provider.dart';
import '../../services/database_service.dart';
import '../../l10n/app_translations.dart';

class RouteTrackerScreen extends StatefulWidget {
  final UserDex liveDex;
  final List<DexDisplayEntry> displayEntries;

  const RouteTrackerScreen({
    super.key,
    required this.liveDex,
    required this.displayEntries,
  });

  @override
  State<RouteTrackerScreen> createState() => _RouteTrackerScreenState();
}

class _RouteTrackerScreenState extends State<RouteTrackerScreen> {
  bool _isLoading = true;
  Map<String, List<DexDisplayEntry>> _routesMap = {};

  @override
  void initState() {
    super.initState();
    _loadRouteData();
  }

  Future<void> _loadRouteData() async {
    Map<String, List<DexDisplayEntry>> tempRoutes = {};

    for (var entry in widget.displayEntries) {
      final enc = await DatabaseService.instance.getEncounters(
        entry.pokemon.id,
      );
      if (enc != null) {
        for (var genMap in enc.values) {
          for (var locList in genMap.values) {
            for (var locStr in locList) {
              String baseLoc = locStr
                  .split('|||')[0]
                  .replaceAll(RegExp(r'\s*\(.*\)'), '')
                  .trim();
              if (baseLoc.isNotEmpty) {
                tempRoutes.putIfAbsent(baseLoc, () => []);
                if (!tempRoutes[baseLoc]!.any(
                  (e) => e.uniqueId == entry.uniqueId,
                )) {
                  tempRoutes[baseLoc]!.add(entry);
                }
              }
            }
          }
        }
      }
    }

    if (mounted) {
      setState(() {
        _routesMap = tempRoutes;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DexProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          Translator.get('route_tracker_title') != 'route_tracker_title'
              ? Translator.get('route_tracker_title')
              : 'Routen-Tracker',
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _routesMap.isEmpty
          ? Center(
              child: Text(
                Translator.get('no_encounters_found') != 'no_encounters_found'
                    ? Translator.get('no_encounters_found')
                    : 'Keine Fundorte für diesen Dex gefunden.',
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _routesMap.keys.length,
              itemBuilder: (context, index) {
                final routeName = _routesMap.keys.elementAt(index);
                final entries = _routesMap[routeName]!;
                int caughtCount = entries
                    .where((e) => widget.liveDex.caughtIds.contains(e.uniqueId))
                    .length;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    title: Text(
                      routeName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '$caughtCount / ${entries.length} ${Translator.get('caught') != 'caught' ? Translator.get('caught') : 'gefangen'}',
                      style: TextStyle(
                        color: caughtCount == entries.length
                            ? Colors.green
                            : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    children: entries.map((entry) {
                      bool isCaught = widget.liveDex.caughtIds.contains(
                        entry.uniqueId,
                      );
                      return ListTile(
                        leading: Image.network(
                          entry.imageUrl,
                          width: 40,
                          height: 40,
                        ),
                        title: Text(
                          entry.pokemon.getName(provider.currentLanguage) +
                              entry.displaySuffix,
                        ),
                        subtitle: Text(
                          '#${entry.pokemon.id.toString().padLeft(3, '0')}',
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.catching_pokemon,
                            color: isCaught ? Colors.green : Colors.grey,
                          ),
                          onPressed: () {
                            provider.togglePokemon(
                              widget.liveDex.id,
                              entry.uniqueId,
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
    );
  }
}
