import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/dex_view_models.dart';
import '../../../providers/dex_provider.dart';
import '../../../services/database_service.dart';
import '../../../l10n/app_translations.dart';
import '../../../widgets/universal_poke_image.dart';

class MatchingBallsWidget extends StatelessWidget {
  final DexDisplayEntry entry;
  final GlobalKey matchingBallsKey;

  const MatchingBallsWidget({
    super.key,
    required this.entry,
    required this.matchingBallsKey,
  });

  Widget _buildBallCard(
    BuildContext context,
    IconData icon,
    String title,
    List<String> ballKeys,
    Color iconColor,
    Map<String, String> ballUrls,
  ) {
    bool isAny = ballKeys.isEmpty || ballKeys.contains('any_ball');

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          isAny
              ? Text(
                  Translator.get('any_ball'),
                  style: const TextStyle(fontSize: 15),
                )
              : Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: ballKeys.map((key) {
                    final imgUrl = ballUrls[key];
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (imgUrl != null)
                            UniversalPokeImage(
                              imageUrl: imgUrl,
                              width: 24,
                              height: 24,
                              errorIconSize: 24,
                            ),
                          if (imgUrl != null) const SizedBox(width: 8),
                          Text(
                            Translator.get('ball_$key'),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DexProvider>();

    return Card(
      key: matchingBallsKey,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: const Icon(Icons.catching_pokemon, color: Colors.redAccent),
        title: Text(
          Translator.get('matching_balls', fallback: 'Matching Balls'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          FutureBuilder<Map<String, dynamic>?>(
            future: DatabaseService.instance.getMatchingBalls(entry.uniqueId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final matchingBalls = snapshot.data;
              final List<String> normalBalls = List<String>.from(
                matchingBalls?['normal'] ?? [],
              );
              final List<String> shinyBalls = List<String>.from(
                matchingBalls?['shiny'] ?? [],
              );

              return Column(
                children: [
                  _buildBallCard(
                    context,
                    Icons.catching_pokemon,
                    Translator.get(
                      'matching_ball_normal',
                      fallback: 'Matching Ball (Normal)',
                    ),
                    normalBalls,
                    Theme.of(context).colorScheme.primary,
                    provider.ballUrls,
                  ),
                  _buildBallCard(
                    context,
                    Icons.star,
                    Translator.get(
                      'matching_ball_shiny',
                      fallback: 'Matching Ball (Shiny)',
                    ),
                    shinyBalls,
                    Colors.amber,
                    provider.ballUrls,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
