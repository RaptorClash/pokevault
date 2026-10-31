import 'package:flutter/material.dart';
import '../../../../i18n/strings.g.dart';

class Gen3ShinyGuide extends StatelessWidget {
  final Future<void> Function(String) onLaunchUrl;

  const Gen3ShinyGuide({super.key, required this.onLaunchUrl});

  @override
  Widget build(BuildContext context) {
    List<Widget> content = [];

    content.add(
      Text(
        t.shiny_gen3_huntable_yes,
        style: const TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    content.add(const SizedBox(height: 16));
    content.add(
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                t.shiny_gen3_rs_note,
                style: const TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    content.add(const SizedBox(height: 8));
    content.add(
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.errorContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.error,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                t.shiny_gen3_emerald_note,
                style: const TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    content.add(const SizedBox(height: 8));
    content.add(
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.tertiaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.tertiary.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Theme.of(context).colorScheme.tertiary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                t.shiny_gen3_frbg_note,
                style: const TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    content.add(const SizedBox(height: 24));
    content.add(
      Text(
        t.shiny_gen3_links_title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
    content.add(const SizedBox(height: 12));

    Widget buildLinkBtn(IconData icon, String titleKey, String url) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: Icon(icon),
            label: Text(
              (t[titleKey] ?? titleKey) != titleKey
                  ? (t[titleKey] ?? titleKey)
                  : titleKey,
              textAlign: TextAlign.center,
            ),
            onPressed: () => onLaunchUrl(url),
          ),
        ),
      );
    }

    content.add(
      buildLinkBtn(
        Icons.person,
        'shiny_gen3_link_blisy_channel',
        'https://www.youtube.com/@imablisy',
      ),
    );
    content.add(
      buildLinkBtn(
        Icons.play_circle_filled,
        'shiny_gen3_link_blisy_playlist',
        'https://www.youtube.com/watch?v=5feON9zDy6g&list=PL4o9bTT3px_h08zUFb3oChEFku_jG6zyt',
      ),
    );
    content.add(
      buildLinkBtn(
        Icons.play_circle_filled,
        'shiny_gen3_link_blisy_rs_video',
        'https://www.youtube.com/watch?v=_8qxkkGeXok',
      ),
    );
    content.add(
      buildLinkBtn(
        Icons.article,
        'shiny_gen3_link_smogon',
        'https://www.smogon.com/ingame/rng/rs_nonbredrng',
      ),
    );
    content.add(
      buildLinkBtn(
        Icons.article,
        'shiny_gen3_link_retail_rng',
        'https://retailrng.com/emerald/',
      ),
    );
    content.add(
      buildLinkBtn(
        Icons.forum,
        'shiny_gen3_link_reddit_emerald',
        'https://www.reddit.com/r/pokemonrng/comments/idxt27/rng_manipulation_in_emerald/',
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: content,
    );
  }
}
