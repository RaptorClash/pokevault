import 'package:flutter/material.dart';
import '../../../../l10n/app_translations.dart';

class PokemonAutocompleteField extends StatelessWidget {
  final int startId;
  final Iterable<int> validStartIds;
  final String Function(int) getDisplayName;
  final ValueChanged<int> onSelected;

  const PokemonAutocompleteField({
    super.key,
    required this.startId,
    required this.validStartIds,
    required this.getDisplayName,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Autocomplete<int>(
          initialValue: TextEditingValue(text: getDisplayName(startId)),
          displayStringForOption: getDisplayName,
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return validStartIds;
            }
            final query = textEditingValue.text.toLowerCase();
            return validStartIds.where((id) {
              return getDisplayName(id).toLowerCase().contains(query);
            });
          },
          onSelected: onSelected,
          fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: Translator.get('search_hint'),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 22,
                  horizontal: 16,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 12.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.search, size: 26),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Image.network(
                          'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/shiny/$startId.png',
                          width: 36,
                          height: 36,
                          fit: BoxFit.contain,
                          errorBuilder: (c, e, s) =>
                              const SizedBox(width: 36, height: 36),
                        ),
                      ),
                    ],
                  ),
                ),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          controller.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 250,
                    maxWidth: constraints.maxWidth,
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final int option = options.elementAt(index);
                      return ListTile(
                        leading: Image.network(
                          'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/shiny/$option.png',
                          width: 40,
                          height: 40,
                          errorBuilder: (c, e, s) =>
                              const Icon(Icons.catching_pokemon),
                        ),
                        title: Text(getDisplayName(option)),
                        onTap: () {
                          onSelected(option);
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
