import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/dex_view_models.dart';
import '../../../models/tutorial_step.dart';
import '../../../providers/dex_provider.dart';
import '../../../providers/tutorial_provider.dart';
import '../../../widgets/tutorial/tutorial_overlay.dart';
import '../../../l10n/app_translations.dart';

class IgnorePokemonDialog {
  static void show(
    BuildContext context, {
    required DexProvider provider,
    required DexDisplayEntry entry,
    required String dexId,
    bool showTutorial = false,
  }) {
    final GlobalKey confirmKey = GlobalKey();

    showDialog(
      context: context,
      builder: (ctx) {
        if (showTutorial) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            TutorialProvider? tutProvider;
            try {
              tutProvider = Provider.of<TutorialProvider>(ctx, listen: false);
            } catch (_) {}
            if (tutProvider == null) return;
            TutorialOverlay.show(
              ctx,
              TutorialFeature(
                id: 'ignore_confirm',
                nameKey: 'tutorial_feature_details',
                steps: [
                  TutorialStep(
                    targetKey: confirmKey,
                    titleKey: 'tutorial_info_ignore_confirm_title',
                    textKey: 'tutorial_info_ignore_confirm_text',
                    requireTargetTap: true,
                    onTargetTap: () {
                      provider.ignorePokemon(dexId, entry.uniqueId);
                      tutProvider?.markFeatureAsSeen('ignore_confirm');
                      tutProvider?.markFeatureAsSeen('pokemon_details');
                      tutProvider?.markFeatureAsSeen('gender_differences');
                      tutProvider?.markFeatureAsSeen('special_obtainable');
                      TutorialOverlay.resetShowing();
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              () {
                tutProvider?.markFeatureAsSeen('ignore_confirm');
                tutProvider?.markFeatureAsSeen('pokemon_details');
                tutProvider?.markFeatureAsSeen('gender_differences');
                tutProvider?.markFeatureAsSeen('special_obtainable');
              },
            );
          });
        }
        return AlertDialog(
          title: Text(
            Translator.get(
              'ignore_confirm_title',
              fallback: 'Pokémon entfernen?',
            ),
          ),
          content: Text(
            Translator.get(
              'ignore_confirm_text',
              fallback:
                  'Möchtest du dieses Pokémon ausblenden? Du kannst es im Menü jederzeit wiederherstellen.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(Translator.get('cancel')),
            ),
            ElevatedButton(
              key: confirmKey,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () {
                TutorialProvider? tutProvider;
                try {
                  tutProvider = Provider.of<TutorialProvider>(ctx, listen: false);
                } catch (_) {}
                provider.ignorePokemon(dexId, entry.uniqueId);
                tutProvider?.markFeatureAsSeen('ignore_confirm');
                tutProvider?.markFeatureAsSeen('pokemon_details');
                tutProvider?.markFeatureAsSeen('gender_differences');
                tutProvider?.markFeatureAsSeen('special_obtainable');
                TutorialOverlay.resetShowing();
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: Text(
                Translator.get('ignore_pokemon', fallback: 'Entfernen'),
              ),
            ),
          ],
        );
      },
    );
  }
}
