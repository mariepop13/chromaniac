import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../utils/color/image_color_analyzer.dart';
import '../utils/logger/logger_util.dart';

class ColorAnalysisButton extends StatelessWidget {
  final Uint8List? imageBytes;
  final Function(ColorAnalysisResult) onAnalysisComplete;
  final bool isLoading;

  const ColorAnalysisButton({
    super.key,
    required this.imageBytes,
    required this.onAnalysisComplete,
    this.isLoading = false,
  });

  Future<void> _analyzeColors(BuildContext context) async {
    if (imageBytes == null) {
      const message = 'Please select an image first';
      LoggerUtil.warning(message);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(message),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      final analyzer = ImageColorAnalyzer();
      final result = await analyzer.analyzeColoringImage(imageBytes!);
      if (context.mounted) {
        onAnalysisComplete(result);
      }
    } catch (e, stackTrace) {
      LoggerUtil.error('Error analyzing colors', e, stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to analyze colors. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : () => _analyzeColors(context),
      icon: isLoading 
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : const Icon(Icons.palette),
      label: Text(isLoading ? 'Analyzing...' : 'Analyze Colors'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
