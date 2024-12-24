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
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageWidth = constraints.maxWidth;
        final imageHeight = imageWidth * 0.4;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(
              image,
              height: imageHeight,
              width: imageWidth,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding,
                vertical: AppConstants.smallPadding,
              ),
              child: ColorAnalysisButton(
                imageBytes: imageBytes,
                onAnalysisComplete: onAnalysisComplete,
              ),
            ),
          ],
        );
      },
    );
  }
}
