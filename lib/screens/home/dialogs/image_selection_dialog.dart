import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:chromaniac/services/image_service.dart';
import 'package:chromaniac/utils/logger/app_logger.dart';

class ImageSelectionDialog extends StatefulWidget {
  final Function(File?, Uint8List?) onImageSelected;

  const ImageSelectionDialog({
    super.key,
    required this.onImageSelected,
  });

  @override
  ImageSelectionDialogState createState() => ImageSelectionDialogState();
}

class ImageSelectionDialogState extends State<ImageSelectionDialog> {
  final List<String> _exampleImages = [
    'assets/coloring_page/gameboy_cats.png',
    'assets/coloring_page/xmas_bed.png',
  ];

  Future<void> _pickImageFromGallery() async {
    final (File? file, Uint8List? bytes) =
        await ImageService().pickImage(context);

    if (!mounted) return;

    if (file != null || bytes != null) {
      Navigator.of(context).pop();
      widget.onImageSelected(file, bytes);
    }
  }

  Future<void> _selectExampleImage(String imagePath) async {
    try {
      final ByteData imageData = await rootBundle.load(imagePath);
      final Uint8List bytes = imageData.buffer.asUint8List();

      // For web, we'll pass null as the file
      final File? file = kIsWeb ? null : File(imagePath);

      if (!mounted) return;

      Navigator.of(context).pop();
      widget.onImageSelected(file, bytes);
    } catch (e) {
      if (!mounted) return;

      AppLogger.e('Error loading example image', error: e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Image',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickImageFromGallery,
              icon: const Icon(Icons.photo_library),
              label: const Text('Choose from Gallery'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Or choose an example image:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _exampleImages.map((imagePath) {
                return GestureDetector(
                  onTap: () => _selectExampleImage(imagePath),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
