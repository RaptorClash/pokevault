import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tutorial_provider.dart';
import '../../l10n/app_translations.dart';

class TutorialSettingsScreen extends StatelessWidget {
  const TutorialSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tutorialProvider = context.watch<TutorialProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(Translator.get('tutorial_menu_title'))),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.refresh, color: Colors.amber),
                  title: Text(Translator.get('tutorial_replay_all')),
                  onTap: () async {
                    await tutorialProvider.resetAllTutorials();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.home),
                  title: Text(Translator.get('tutorial_feature_home')),
                  trailing: tutorialProvider.hasSeenFeature('home_screen')
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.circle_outlined),
                  onTap: () {
                    tutorialProvider.resetTutorial('home_screen');
                    Navigator.pop(context);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.analytics),
                  title: Text(Translator.get('tutorial_feature_details')),
                  trailing: tutorialProvider.hasSeenFeature('pokemon_details')
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.circle_outlined),
                  onTap: () {
                    tutorialProvider.resetTutorial('pokemon_details');
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
