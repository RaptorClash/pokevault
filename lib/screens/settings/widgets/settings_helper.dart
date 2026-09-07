import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../l10n/app_translations.dart';
import '../../../../utils/notification_helper.dart';

class SettingsHelper {
  static Future<void> launchURL(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        NotificationHelper.showError(
          "${Translator.get('error_launch_url')} $urlString",
        );
      }
    } catch (e) {
      NotificationHelper.showError("${Translator.get('error_launch_url')} $e");
    }
  }

  static Widget buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
