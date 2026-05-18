import 'package:flutter/material.dart';

class AppDialogs {
  static Future<bool> showConfirm({
    required BuildContext context,
    required String title,
    required String content,
    String cancelLabel = 'Cancel',
    String confirmLabel = 'Confirm',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              confirmLabel,
              style: TextStyle(
                color: isDestructive ? Colors.red : null,
                fontWeight: isDestructive ? FontWeight.bold : null,
              ),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}

