import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/pokemon.dart';
import '../../../models/shiny_hunt.dart';
import '../../../providers/dex_provider.dart';
import '../../../providers/shiny_hunt_provider.dart';
import '../../../l10n/app_translations.dart';
import '../../../widgets/universal_poke_image.dart';

class RecordPhaseDialog extends StatefulWidget {
  final ShinyHunt hunt;

  const RecordPhaseDialog({super.key, required this.hunt});

  @override
  State<RecordPhaseDialog> createState() => _RecordPhaseDialogState();
}

class _RecordPhaseDialogState extends State<RecordPhaseDialog> {
  final TextEditingController _pokemonNameController = TextEditingController();
  int? _selectedPokemonId;
  String? _selectedPokemonName;

  bool _syncToDex = false;
  String? _selectedDexId;

  @override
  void initState() {
    super.initState();
    _selectedDexId = widget.hunt.targetDexId;
  }

  @override
  void dispose() {
    _pokemonNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dexProvider = Provider.of<DexProvider>(context);
    final userDexes = dexProvider.userDexes;
    final allPokemon = dexProvider.allPokemon;
    final lang = Translator.currentLanguage;
    final effectiveDexId = userDexes.any((d) => d.id == _selectedDexId)
        ? _selectedDexId
        : (userDexes.isNotEmpty ? userDexes.first.id : null);

    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history_toggle_off, color: Colors.blueAccent, size: 28),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        Translator.get('shiny_hunt_phase_dialog_title'),
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Phase ${widget.hunt.phase}: ${widget.hunt.currentEncounters} Begegnungen werden in der Chronik gesichert und der Phasenzähler wird genullt.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),

                // Pokémon-Suche / Autocomplete
                Autocomplete<Pokemon>(
                  displayStringForOption: (option) => option.getName(lang),
                  optionsBuilder: (textEditingValue) {
                    final query = textEditingValue.text.trim().toLowerCase();
                    if (query.isEmpty) return const Iterable<Pokemon>.empty();
                    return allPokemon.where((p) {
                      final de = p.nameDe.toLowerCase();
                      final en = p.nameEn.toLowerCase();
                      final id = p.id.toString();
                      return de.contains(query) || en.contains(query) || id == query;
                    }).take(10);
                  },
                  onSelected: (selection) {
                    setState(() {
                      _selectedPokemonId = selection.id;
                      _selectedPokemonName = selection.getName(lang);
                      _pokemonNameController.text = _selectedPokemonName!;
                    });
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: Translator.get('shiny_hunt_phase_pokemon_name'),
                        hintText: 'Z. B. Taubsi, Zubat, Garados...',
                        border: const OutlineInputBorder(),
                        prefixIcon: _selectedPokemonId != null
                            ? Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: UniversalPokeImage(
                                  imageUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/shiny/$_selectedPokemonId.png',
                                  width: 32,
                                  height: 32,
                                ),
                              )
                            : const Icon(Icons.search),
                      ),
                      onChanged: (val) {
                        _selectedPokemonName = val;
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Dex-Sync Checkbox & Dropdown
                if (userDexes.isNotEmpty) ...[
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _syncToDex,
                    onChanged: (val) => setState(() => _syncToDex = val ?? false),
                    title: Text(Translator.get('shiny_hunt_save_phase_to_dex')),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  if (_syncToDex) ...[
                    DropdownButtonFormField<String>(
                      initialValue: effectiveDexId,
                      decoration: InputDecoration(
                        labelText: Translator.get('shiny_hunt_target_dex'),
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: userDexes.map((d) {
                        return DropdownMenuItem<String>(
                          value: d.id,
                          child: Text(d.title),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedDexId = val),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],

                // Aktionen
                Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(Translator.get('cancel', fallback: 'Abbrechen')),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        final huntProvider = Provider.of<ShinyHuntProvider>(context, listen: false);
                        final effectiveDexId = userDexes.any((d) => d.id == _selectedDexId)
                            ? _selectedDexId
                            : (userDexes.isNotEmpty ? userDexes.first.id : null);
                        await huntProvider.recordPhaseShiny(
                          widget.hunt.id,
                          caughtPokemonId: _selectedPokemonId,
                          caughtPokemonName: _selectedPokemonName ?? _pokemonNameController.text.trim(),
                          syncToDex: _syncToDex,
                          targetDexId: _syncToDex ? effectiveDexId : null,
                          dexProvider: dexProvider,
                        );
                        if (context.mounted) {
                          Navigator.of(context).pop(true);
                        }
                      },
                      child: Text(Translator.get('confirm', fallback: 'Phase abschließen')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
