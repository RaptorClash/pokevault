import 'package:flutter/material.dart';

class NotificationHelper {
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void showError(String message) {
    _showSnackBar(message, Colors.redAccent.shade700, Icons.error_outline);
  }

  static void showSuccess(String message) {
    _showSnackBar(message, Colors.green.shade700, Icons.check_circle_outline);
  }

  static void showInfo(String message) {
    _showSnackBar(message, Colors.blue.shade700, Icons.info_outline);
  }

  static void showWarning(String message) {
    _showSnackBar(message, Colors.orange.shade800, Icons.warning_amber_rounded);
  }

  static void _showSnackBar(
    String message,
    Color backgroundColor,
    IconData icon,
  ) {
    scaffoldMessengerKey.currentState?.hideCurrentSnackBar();

    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
