import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../l10n/app_translations.dart';
import '../../providers/tutorial_provider.dart';
import '../../models/tutorial_step.dart';
import '../../widgets/tutorial/tutorial_overlay.dart';
import 'widgets/appearance_card.dart';
import 'widgets/cloud_sync_card.dart';
import 'widgets/misc_settings_cards.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final GlobalKey _appearanceKey = GlobalKey();
  final GlobalKey _updatesKey = GlobalKey();
  final GlobalKey _generalKey = GlobalKey();
  final GlobalKey _dataKey = GlobalKey();
  final GlobalKey _cloudKey = GlobalKey();
  final GlobalKey _communityKey = GlobalKey();
  final GlobalKey _creditsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTutorialIfNeeded();
    });
  }

  void _showTutorialIfNeeded() {
    final tutProvider = Provider.of<TutorialProvider>(context, listen: false);
    if (!tutProvider.hasSeenFeature('settings_screen')) {
      TutorialOverlay.show(
        context,
        TutorialFeature(
          id: 'settings_screen',
          nameKey: 'settings',
          steps: [
            TutorialStep(
              targetKey: _appearanceKey,
              titleKey: 'tutorial_settings_appearance_title',
              textKey: 'tutorial_settings_appearance_text',
            ),
            TutorialStep(
              targetKey: _updatesKey,
              titleKey: 'tutorial_settings_updates_title',
              textKey: 'tutorial_settings_updates_text',
            ),
            TutorialStep(
              targetKey: _generalKey,
              titleKey: 'tutorial_settings_general_title',
              textKey: 'tutorial_settings_general_text',
            ),
            TutorialStep(
              targetKey: _dataKey,
              titleKey: 'tutorial_settings_data_title',
              textKey: 'tutorial_settings_data_text',
            ),
            TutorialStep(
              targetKey: _cloudKey,
              titleKey: 'tutorial_settings_cloud_title',
              textKey: 'tutorial_settings_cloud_text',
            ),
            TutorialStep(
              targetKey: _communityKey,
              titleKey: 'tutorial_settings_community_title',
              textKey: 'tutorial_settings_community_text',
            ),
            TutorialStep(
              targetKey: _creditsKey,
              titleKey: 'tutorial_settings_credits_title',
              textKey: 'tutorial_settings_credits_text',
            ),
          ],
        ),
        () => tutProvider.markFeatureAsSeen('settings_screen'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(Translator.get('settings'))),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Container(key: _appearanceKey, child: const AppearanceCard()),
          const SizedBox(height: 24),
          Container(key: _updatesKey, child: const UpdatesCard()),
          const SizedBox(height: 24),
          Container(key: _generalKey, child: const GeneralCard()),
          const SizedBox(height: 24),
          Container(key: _dataKey, child: const DataManagementCard()),
          const SizedBox(height: 24),
          Container(key: _cloudKey, child: const CloudSyncCard()),
          const SizedBox(height: 24),
          Container(key: _communityKey, child: const CommunityCard()),
          const SizedBox(height: 24),
          Container(key: _creditsKey, child: const CreditsCard()),
          const SizedBox(height: 32),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final packageInfo = snapshot.data!;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Center(
                    child: Text(
                      'Version ${packageInfo.version} (Build ${packageInfo.buildNumber})',
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
