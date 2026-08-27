import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../l10n/app_translations.dart';
import '../../utils/update_helper.dart';
import '../../widgets/dialogs/downgrade_dialog.dart';

class DowngradeScreen extends StatefulWidget {
  const DowngradeScreen({super.key});

  @override
  State<DowngradeScreen> createState() => _DowngradeScreenState();
}

class _DowngradeScreenState extends State<DowngradeScreen> {
  late Future<List<UpdateInfo>> _releasesFuture;

  @override
  void initState() {
    super.initState();
    _releasesFuture = _fetchDowngrades();
  }

  Future<List<UpdateInfo>> _fetchDowngrades() async {
    final allReleases = await UpdateHelper.getAllReleases();
    final packageInfo = await PackageInfo.fromPlatform();

    String currentVersion = packageInfo.version.replaceAll(
      RegExp(r'[^0-9.]'),
      '',
    );

    return allReleases.where((release) {
      String releaseVersion = release.version.replaceAll(
        RegExp(r'[^0-9.]'),
        '',
      );
      return releaseVersion != currentVersion;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          Translator.get('downgrades_title') != 'downgrades_title'
              ? Translator.get('downgrades_title')
              : 'Vorherige Versionen (Downgrades)',
        ),
      ),
      body: FutureBuilder<List<UpdateInfo>>(
        future: _releasesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('${Translator.get('error')} ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Keine älteren Versionen gefunden.'),
            );
          }

          final releases = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: releases.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final release = releases[index];
              return Card(
                elevation: 0,
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                child: ListTile(
                  leading: const Icon(Icons.history, color: Colors.redAccent),
                  title: Text(
                    release.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Version ${release.version}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) =>
                          DowngradeDialog(releaseInfo: release),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
