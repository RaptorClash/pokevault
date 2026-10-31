import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../i18n/strings.g.dart';
import '../../../../providers/settings_provider.dart';
import '../../../../providers/dex_provider.dart';
import '../../../../utils/notification_helper.dart';
import '../../../../utils/update_helper.dart';
import '../../../../services/dex_storage_service.dart';
import '../../../widgets/dialogs/update_dialog.dart';
import '../downgrade_screen.dart';
import '../controls_guide_screen.dart';
import '../tutorial_settings_screen.dart';
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
          t.updates,
          Icons.system_update,
        ),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.update),
                title: Text(t.check_for_updates),
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
                          t.up_to_date,
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context);
                      NotificationHelper.showError(
                        '${t.error} $e',
                      );
                    }
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.history, color: Colors.redAccent),
                title: Text(
                  t.downgrades_title,
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
          t.general,
          Icons.language,
        ),
        Card(
          child: Column(
            children: [
              ListTile(
                title: Text(t.language),
                subtitle: Text(t.current_language),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showLanguageDialog(context, settingsProvider),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.sports_esports_outlined,
                  color: Colors.blueAccent,
                ),
                title: Text(
                  t.controls_guide_title,
                ),
                subtitle: Text(
                  t.controls_guide_sub,
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ControlsGuideScreen(),
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.school_outlined,
                  color: Colors.amber,
                ),
                title: Text(
                  t.tutorial_center_title,
                ),
                subtitle: Text(
                  t.tutorial_center_subtitle,
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TutorialSettingsScreen(),
                  ),
                ),
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
          title: Text(t.language),
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
          t.data_management,
          Icons.save,
        ),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.download),
                title: Text(t.import_tooltip),
                onTap: () async => await dexProvider.importJsonData(),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.upload),
                title: Text(t.export_tooltip),
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
          t.community_support,
          Icons.people_alt,
        ),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.bug_report_outlined),
                title: Text(t.report_issue_title),
                subtitle: Text(t.report_issue_sub),
                trailing: const Icon(Icons.open_in_new, size: 16),
                onTap: () => SettingsHelper.launchURL(
                  'https://github.com/raptorclash/pokevault/issues/new/choose',
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.code),
                title: Text(t.contribute_title),
                subtitle: Text(t.contribute_sub),
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
          t.credits,
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
                'credit_shiny_silph_scope_title',
                'credit_shiny_silph_scope_sub',
                Icons.play_circle_filled,
                'https://youtu.be/2s6QxW-3BcE?is=T0lmNtgkVIMapARw',
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
                'credit_bulbapedia_title',
                'credit_bulbapedia_sub',
                Icons.menu_book_rounded,
                'https://bulbapedia.bulbagarden.net/wiki/Catch_rate',
              ),
              const Divider(height: 1),
              _buildCreditLink(
                'credit_ribbons_title',
                'credit_ribbons_sub',
                Icons.workspace_premium,
                'https://github.com/SlyAceZeta/Ribbons.Guide',
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
      title: Text(isDirectText ? titleKey : (t[titleKey] ?? titleKey)),
      subtitle: Text(isDirectText ? subKey : (t[subKey] ?? subKey)),
      trailing: const Icon(Icons.open_in_new, size: 16),
      onTap: () => SettingsHelper.launchURL(url),
    );
  }
}
