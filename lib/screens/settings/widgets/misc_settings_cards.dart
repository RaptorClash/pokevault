import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_translations.dart';
import '../../../../providers/settings_provider.dart';
import '../../../../providers/tutorial_provider.dart';
import '../../../../providers/dex_provider.dart';
import '../../../../utils/notification_helper.dart';
import '../../../../utils/update_helper.dart';
import '../../../../services/dex_storage_service.dart';
import '../../../widgets/dialogs/update_dialog.dart';
import '../downgrade_screen.dart';
import 'settings_helper.dart';

class UpdatesCard extends StatelessWidget {
  const UpdatesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SettingsHelper.buildSectionHeader(
          context,
          Translator.get('updates'),
          Icons.system_update,
        ),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.update),
                title: Text(Translator.get('check_for_updates')),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) =>
                        const Center(child: CircularProgressIndicator()),
                  );
                  try {
                    final updateInfo = await UpdateHelper.checkForUpdate();
                    if (context.mounted) {
                      Navigator.pop(context);
                      if (updateInfo != null) {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) =>
                              UpdateDialog(updateInfo: updateInfo),
                        );
                      } else {
                        NotificationHelper.showInfo(
                          Translator.get('up_to_date'),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context);
                      NotificationHelper.showError(
                        '${Translator.get('error')} $e',
                      );
                    }
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.history, color: Colors.redAccent),
                title: Text(
                  Translator.get(
                    'downgrades_title',
                    fallback: 'Vorherige Versionen (Downgrades)',
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DowngradeScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class GeneralCard extends StatelessWidget {
  const GeneralCard({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SettingsHelper.buildSectionHeader(
          context,
          Translator.get('general'),
          Icons.language,
        ),
        Card(
          child: Column(
            children: [
              ListTile(
                title: Text(Translator.get('language')),
                subtitle: Text(Translator.get('current_language')),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showLanguageDialog(context, settingsProvider),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.lightbulb_outline,
                  color: Colors.amber,
                ),
                title: Text(
                  Translator.get(
                    'tutorial_reset_title',
                    fallback: 'Tutorial neustarten',
                  ),
                ),
                subtitle: Text(
                  Translator.get(
                    'tutorial_reset_sub',
                    fallback: 'Setzt alle Hilfen zurück',
                  ),
                ),
                onTap: () async {
                  try {
                    final tutProvider = Provider.of<TutorialProvider>(
                      context,
                      listen: false,
                    );
                    await tutProvider.resetAllTutorials();
                    NotificationHelper.showSuccess(
                      Translator.get(
                        'tutorial_reset_success',
                        fallback: 'Tutorial wurde zurückgesetzt!',
                      ),
                    );
                  } catch (e) {
                    NotificationHelper.showError(
                      '${Translator.get('error')} $e',
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showLanguageDialog(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(Translator.get('language')),
          children: [
            SimpleDialogOption(
              onPressed: () {
                provider.setLanguage('de');
                Navigator.pop(context);
              },
              child: const Text('  Deutsch (DE)'),
            ),
            SimpleDialogOption(
              onPressed: () {
                provider.setLanguage('en');
                Navigator.pop(context);
              },
              child: const Text('  English (EN)'),
            ),
          ],
        );
      },
    );
  }
}

class DataManagementCard extends StatelessWidget {
  const DataManagementCard({super.key});

  @override
  Widget build(BuildContext context) {
    final dexProvider = context.watch<DexProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SettingsHelper.buildSectionHeader(
          context,
          Translator.get('data_management'),
          Icons.save,
        ),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.download),
                title: Text(Translator.get('import_tooltip')),
                onTap: () async => await dexProvider.importJsonData(),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.upload),
                title: Text(Translator.get('export_tooltip')),
                onTap: () async {
                  if (dexProvider.userDexes.isNotEmpty) {
                    await DexStorageService.exportDexes(
                      dexProvider.userDexes,
                      dexProvider,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CommunityCard extends StatelessWidget {
  const CommunityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SettingsHelper.buildSectionHeader(
          context,
          Translator.get('community_support'),
          Icons.people_alt,
        ),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.bug_report_outlined),
                title: Text(Translator.get('report_issue_title')),
                subtitle: Text(Translator.get('report_issue_sub')),
                trailing: const Icon(Icons.open_in_new, size: 16),
                onTap: () => SettingsHelper.launchURL(
                  'https://github.com/raptorclash/pokevault/issues/new/choose',
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.code),
                title: Text(Translator.get('contribute_title')),
                subtitle: Text(Translator.get('contribute_sub')),
                trailing: const Icon(Icons.open_in_new, size: 16),
                onTap: () => SettingsHelper.launchURL(
                  'https://github.com/raptorclash/pokevault',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CreditsCard extends StatelessWidget {
  const CreditsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SettingsHelper.buildSectionHeader(
          context,
          Translator.get('credits'),
          Icons.favorite_rounded,
        ),
        Card(
          child: Column(
            children: [
              _buildCreditLink(
                'credit_api_title',
                'credit_api_sub',
                Icons.api_rounded,
                'https://pokeapi.co/',
              ),
              const Divider(height: 1),
              _buildCreditLink(
                'credit_inspi_title',
                'credit_inspi_sub',
                Icons.lightbulb_outline_rounded,
                'https://drive.google.com/drive/folders/1jgopfeGuNA8oJX6mnYearpnNti4a8W-v',
              ),
              const Divider(height: 1),
              _buildCreditLink(
                'credit_pokewiki_title',
                'credit_pokewiki_sub',
                Icons.menu_book,
                'https://www.pokewiki.de/',
              ),
              const Divider(height: 1),
              _buildCreditLink(
                'credit_bisafans_title',
                'credit_bisafans_sub',
                Icons.article,
                'https://www.bisafans.de/',
              ),
              const Divider(height: 1),
              _buildCreditLink(
                'credit_shiny_gen1_title',
                'credit_shiny_gen1_sub',
                Icons.auto_awesome,
                'https://bluemoonfalls.com/pages/shinies/gen-1-shiny-hunting',
              ),
              const Divider(height: 1),
              _buildCreditLink(
                'credit_glitch_gen2_title',
                'credit_glitch_gen2_sub',
                Icons.bug_report_rounded,
                'https://glitchcity.wiki/wiki/Guides:Mail_Writer_Codes',
              ),
              const Divider(height: 1),
              _buildCreditLink(
                'credit_balls_title',
                'credit_balls_sub',
                Icons.catching_pokemon,
                'https://docs.google.com/spreadsheets/d/1bvIx7Q2Lxp7efHRrUh48WkuwirNlKardwSHVz_R8kA0/edit',
              ),
              const Divider(height: 1),
              _buildCreditLink(
                'Bulbapedia (Catch Rates)',
                'Mechaniken für Legends Z-A und Max Raids',
                Icons.menu_book_rounded,
                'https://bulbapedia.bulbagarden.net/wiki/Catch_rate',
                isDirectText: true,
              ),
              const Divider(height: 1),
              _buildCreditLink(
                'credit_ai_title',
                'credit_ai_sub',
                Icons.memory,
                'https://gemini.google.com/',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreditLink(
    String titleKey,
    String subKey,
    IconData icon,
    String url, {
    bool isDirectText = false,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(isDirectText ? titleKey : Translator.get(titleKey)),
      subtitle: Text(isDirectText ? subKey : Translator.get(subKey)),
      trailing: const Icon(Icons.open_in_new, size: 16),
      onTap: () => SettingsHelper.launchURL(url),
    );
  }
}
