import 'package:flutter/material.dart';

class DialogWidget {
  static Future<void> mostraDialog({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onOpen,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Annulla"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onOpen();
            },
            child: const Text("Apri"),
          ),
        ],
      ),
    );
  }
}
