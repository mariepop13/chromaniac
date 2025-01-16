import 'package:chromaniac/utils/logger/app_logger.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:chromaniac/utils/color/image_color_analyzer.dart';
import 'package:chromaniac/core/constants.dart';
import 'package:chromaniac/utils/color/contrast_color.dart';
// import 'package:chromaniac/services/auth_service.dart';

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
  // final _authService = AuthService();

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

    // Removed authentication check
    // if (_authService.currentUser == null) {
    //   _showAuthenticationRequiredDialog();
    //   return;
    // }

    setState(() {
      _isLoading = true;
    });

    try {
      final analyzer = ImageColorAnalyzer();
      final result = await analyzer.analyzeColoringImage(widget.imageBytes!);
      if (context.mounted) {
        widget.onAnalysisComplete(result);
        _showAnalysisDialog(context, result);
      }
    } catch (error, stackTrace) {
      AppLogger.e('Error analyzing colors',
          error: error, stackTrace: stackTrace);
      if (context.mounted) {
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

  void _showAnalysisDialog(BuildContext context, ColorAnalysisResult result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppConstants.dialogBorderRadius),
          ),
          child: OrientationBuilder(
            builder: (context, orientation) {
              final isLandscape = orientation == Orientation.landscape;
              return LayoutBuilder(
                builder: (context, constraints) {
                  final maxDialogHeight = isLandscape
                      ? MediaQuery.of(context).size.height * 0.8
                      : constraints.maxHeight - 100;
                  final maxDialogWidth = isLandscape
                      ? MediaQuery.of(context).size.width * 0.8
                      : constraints.maxWidth;

                  return Container(
                    width: maxDialogWidth,
                    constraints: BoxConstraints(
                      maxHeight: maxDialogHeight,
                    ),
                    padding: const EdgeInsets.all(AppConstants.dialogPadding),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Palette Results',
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
                        Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
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
                                            AppConstants
                                                .colorPreviewBorderRadius,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                          width: AppConstants.spacingMedium),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ContrastColorScheme.fromTheme(Theme.of(context));

    return Stack(
      alignment: Alignment.topRight,
      clipBehavior: Clip.none,
      children: [
        ElevatedButton.icon(
          onPressed: _isLoading ? null : () => _analyzeColors(context),
          icon: _isLoading
              ? SizedBox(
                  width: AppConstants.iconSize,
                  height: AppConstants.iconSize,
                  child: CircularProgressIndicator(
                    strokeWidth: AppConstants.iconStrokeWidth,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.foregroundColor),
                  ),
                )
              : Icon(Icons.palette_outlined,
                  color: colorScheme.foregroundColor),
          label: Text(
            _isLoading ? 'Generating...' : 'Smart Palette',
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
        ),
      ],
    );
  }
}
