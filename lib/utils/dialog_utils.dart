import 'package:flutter/material.dart';

void showDelayedDialog<T>(BuildContext context, Function(BuildContext) dialogBuilder) {
  Future.delayed(const Duration(milliseconds: 50), () {
    if (context.mounted) {
      dialogBuilder(context);
    }
  });
}

void showCopySnackBar(BuildContext context, String value) {
  showSnackBar(context, 'Copied $value to clipboard');
}

void showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
