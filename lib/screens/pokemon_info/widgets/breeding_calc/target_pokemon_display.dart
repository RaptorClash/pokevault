import 'package:flutter/material.dart';

class TargetPokemonDisplay extends StatelessWidget {
  final int targetId;
  final String targetName;

  const TargetPokemonDisplay({
    super.key,
    required this.targetId,
    required this.targetName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
            ),
            child: Image.network(
              'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/shiny/$targetId.png',
              width: 56,
              height: 56,
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) =>
                  const Icon(Icons.catching_pokemon, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '#${targetId.toString().padLeft(3, '0')} $targetName',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const Icon(Icons.flag, color: Colors.green, size: 28),
        ],
      ),
    );
  }
}
