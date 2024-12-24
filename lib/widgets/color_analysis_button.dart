import 'package:chromaniac/utils/logger/app_logger.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:chromaniac/utils/color/image_color_analyzer.dart';
import 'package:chromaniac/core/constants.dart';
import 'package:chromaniac/utils/color/contrast_color.dart';

class ColorAnalysisButton extends StatefulWidget {
  final Uint8List? imageBytes;
  final Function(ColorAnalysisResult) onAnalysisComplete;

  const ColorAnalysisButton({
    super.key,
    required this.imageBytes,
    required this.onAnalysisComplete,
  });

  @override
  State<ColorAnalysisButton> createState() => _ColorAnalysisButtonState();
}

class _ColorAnalysisButtonState extends State<ColorAnalysisButton> {
  bool _isLoading = false;

  void _showAnalysisDialog(BuildContext context, ColorAnalysisResult result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.dialogBorderRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.dialogPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Color Analysis Results',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spacingMedium),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: AppConstants.dialogMaxHeight,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: result.colorAnalysis.map((analysis) {
                        final color = Color(int.parse(
                          analysis['hexCode']!.replaceAll('#', '0xFF'),
                        ));
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppConstants.spacingSmall,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: AppConstants.colorPreviewSize,
                                height: AppConstants.colorPreviewSize,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.colorPreviewBorderRadius,
                                  ),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppConstants.spacingMedium),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      analysis['object']!,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(analysis['colorName']!),
                                  ],
                                ),
                              ),
                              Text(analysis['hexCode']!),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _analyzeColors(BuildContext context) async {
    if (widget.imageBytes == null) {
      const message = 'Please select an image first';
      AppLogger.w(message);
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

    setState(() {
      _isLoading = true;
    });

    try {
      final analyzer = ImageColorAnalyzer();
      final result = await analyzer.analyzeColoringImage(widget.imageBytes!);
      if (mounted) {
        widget.onAnalysisComplete(result);
        _showAnalysisDialog(context, result);
      }
    } catch (e, stackTrace) {
      AppLogger.e('Error analyzing colors', error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to analyze colors. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ContrastColorScheme.fromTheme(Theme.of(context));

    return ElevatedButton.icon(
      onPressed: _isLoading ? null : () => _analyzeColors(context),
      icon: _isLoading
          ? SizedBox(
              width: AppConstants.iconSize,
              height: AppConstants.iconSize,
              child: CircularProgressIndicator(
                strokeWidth: AppConstants.iconStrokeWidth,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.foregroundColor),
              ),
            )
          : Icon(Icons.palette, color: colorScheme.foregroundColor),
      label: Text(
        _isLoading ? 'Analyzing...' : 'Analyze Colors',
        style: TextStyle(color: colorScheme.foregroundColor),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.backgroundColor,
        foregroundColor: colorScheme.foregroundColor,
        padding: EdgeInsets.symmetric(
          horizontal: AppConstants.buttonHorizontalPadding,
          vertical: AppConstants.buttonVerticalPadding,
        ),
      ),
    );
  }
}
