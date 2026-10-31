import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/dex_view_models.dart';
import '../../../providers/dex_provider.dart';
import '../../../services/database_service.dart';
import '../../../i18n/strings.g.dart';
import '../../../widgets/universal_poke_image.dart';
import 'lazy_expansion_card.dart';

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
                  t.any_ball,
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
                            (t['ball_$key'] ?? key),
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

    return LazyExpansionCard(
      key: matchingBallsKey,
      leading: const Icon(Icons.catching_pokemon, color: Colors.redAccent),
      title: Text(
        t.matching_balls,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      builder: (context) {
        return FutureBuilder<Map<String, dynamic>?>(
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
                  t.matching_ball_normal,
                  normalBalls,
                  Theme.of(context).colorScheme.primary,
                  provider.ballUrls,
                ),
                _buildBallCard(
                  context,
                  Icons.star,
                  t.matching_ball_shiny,
                  shinyBalls,
                  Colors.amber,
                  provider.ballUrls,
                ),
              ],
            );
          },
        );
      },
    );
  }
}
