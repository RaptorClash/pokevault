import 'package:flutter/material.dart';
import '../../../data/national_dex_data.dart';
import '../../../l10n/app_translations.dart';

class PokemonAvatar extends StatelessWidget {
  final int id;
  final bool isShiny;
  final String gender;
  final bool isHighlight;
  final bool isCarrier;
  final double sizeScale;

  const PokemonAvatar({
    super.key,
    required this.id,
    required this.isShiny,
    required this.gender,
    this.isHighlight = false,
    this.isCarrier = false,
    this.sizeScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    bool showAsShiny = isShiny && !isCarrier;
    final String imgUrl =
        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${showAsShiny ? "shiny/" : ""}$id.png';
    final p = nationalPokemonDatabase.firstWhere((p) => p.id == id);
    final String name = p.getName(Translator.currentLanguage);

    IconData genderIcon = Icons.transgender;
    Color genderColor = Colors.grey;

    if (gender == 'm') {
      genderIcon = Icons.male;
      genderColor = Colors.blueAccent;
    } else if (gender == 'f') {
      genderIcon = Icons.female;
      genderColor = Colors.pinkAccent;
    }

    return SizedBox(
      width: 80 * sizeScale,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                width: (isHighlight ? 60 : 52) * sizeScale,
                height: (isHighlight ? 60 : 52) * sizeScale,
                decoration: BoxDecoration(
                  color: showAsShiny
                      ? Colors.amber.withOpacity(0.15)
                      : (isCarrier
                            ? Colors.blue.withOpacity(0.15)
                            : Theme.of(context).colorScheme.surface),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: showAsShiny
                        ? Colors.amber
                        : (isCarrier
                              ? Colors.blue
                              : Theme.of(
                                  context,
                                ).dividerColor.withOpacity(0.5)),
                    width: isHighlight ? 2 : 1,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(4.0 * sizeScale),
                  child: Image.network(
                    imgUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) => Icon(
                      Icons.catching_pokemon,
                      color: Colors.grey,
                      size: 24 * sizeScale,
                    ),
                  ),
                ),
              ),
              if (showAsShiny)
                Container(
                  padding: EdgeInsets.all(2 * sizeScale),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 14 * sizeScale,
                  ),
                ),
            ],
          ),
          SizedBox(height: 6 * sizeScale),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (gender != 'any')
                Icon(genderIcon, color: genderColor, size: 14 * sizeScale),
              if (gender != 'any') SizedBox(width: 2 * sizeScale),
              Flexible(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: (12 * sizeScale).clamp(9.0, 14.0),
                    fontWeight: isHighlight
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          if (isCarrier)
            Text(
              Translator.get('carrier') != 'carrier'
                  ? Translator.get('carrier')
                  : '(Trägerin)',
              style: TextStyle(
                fontSize: 10 * sizeScale,
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}
