import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chromaniac/utils/logger/app_logger.dart';

class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  final _picker = ImagePicker();

  Future<(File?, Uint8List?)> pickImage(BuildContext context) async {
    try {
      AppLogger.d('Attempting to pick image from gallery');
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        AppLogger.i('Image picked successfully: ${pickedFile.path}');
        final bytes = await pickedFile.readAsBytes();
        return (File(pickedFile.path), bytes);
      } else {
        AppLogger.w('No image selected');
        return (null, null);
      }
    } catch (e, stackTrace) {
      AppLogger.e('Error picking image', error: e, stackTrace: stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return (null, null);
    }
  }
}
