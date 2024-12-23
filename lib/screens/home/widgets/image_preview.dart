import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:chromaniac/core/constants.dart';
import 'package:chromaniac/widgets/color_analysis_button.dart';
import 'package:chromaniac/utils/color/image_color_analyzer.dart';

class ImagePreview extends StatelessWidget {
  final File image;
  final Uint8List imageBytes;
  final Function(ColorAnalysisResult) onAnalysisComplete;

  const ImagePreview({
    super.key,
    required this.image,
    required this.imageBytes,
    required this.onAnalysisComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.file(
          image,
          height: AppConstants.colorPreviewHeight,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
        Padding(
          padding: EdgeInsets.all(AppConstants.defaultPadding),
          child: ColorAnalysisButton(
            imageBytes: imageBytes,
            onAnalysisComplete: onAnalysisComplete,
          ),
        ),
      ],
    );
  }
}
