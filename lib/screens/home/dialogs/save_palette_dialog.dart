import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../models/color_palette.dart';
import '../../../services/database_service.dart';
import '../../../services/auth_service.dart';
import '../../../utils/logger/app_logger.dart';
import '../../auth/login_screen.dart';

void showSavePaletteDialog(BuildContext context, List<Color> palette) {
  final authService = AuthService();
  final textController = TextEditingController();

  // Check if user is authenticated
  if (authService.currentUser == null) {
    // Show login/signup dialog
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Authentication Required'),
        content: const Text('Please log in or sign up to save palettes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // Navigate to login screen
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
            child: const Text('Log In / Sign Up'),
          ),
        ],
      ),
    );
    return;
  }

  // Existing save palette dialog logic
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Save Palette'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${palette.length} colors selected'),
          const SizedBox(height: 16),
          TextField(
            controller: textController,
            decoration: const InputDecoration(
              labelText: 'Palette Name',
              hintText: 'Enter a name for this palette',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              Navigator.pop(dialogContext, value);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(dialogContext);
            try {
              AppLogger.d('Saving palette with name: ${textController.text}');
              final now = DateTime.now();
              final colorPalette = ColorPalette(
                id: const Uuid().v4(),
                name: textController.text.isEmpty
                    ? 'Palette ${now.toIso8601String()}'
                    : textController.text,
                colors: List<Color>.from(palette),
                createdAt: now,
                updatedAt: now,
              );

              AppLogger.d('Created palette object: ${colorPalette.name}');
              await DatabaseService().savePalette(colorPalette);

              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Palette saved successfully')),
                );
              }
            } catch (e, stackTrace) {
              AppLogger.e('Error saving palette',
                  error: e, stackTrace: stackTrace);
              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                      content: Text('Error saving palette: ${e.toString()}')),
                );
              }
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
