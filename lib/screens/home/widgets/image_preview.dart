import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:chromaniac/utils/color/image_color_analyzer.dart';

class ImagePreviewDialog extends StatefulWidget {
  final File? image;
  final Uint8List imageBytes;
  final Function(ColorAnalysisResult) onAnalysisComplete;

  const ImagePreviewDialog({
    super.key,
    required this.image,
    required this.imageBytes,
    required this.onAnalysisComplete,
  });

  static void show(
    BuildContext context, {
    required File? image,
    required Uint8List imageBytes,
    required Function(ColorAnalysisResult) onAnalysisComplete,
  }) {
    showDialog(
      context: context,
      builder: (context) => ImagePreviewDialog(
        image: image,
        imageBytes: imageBytes,
        onAnalysisComplete: onAnalysisComplete,
      ),
    );
  }

  @override
  ImagePreviewDialogState createState() => ImagePreviewDialogState();
}

class ImagePreviewDialogState extends State<ImagePreviewDialog> {
  final TransformationController _transformationController =
      TransformationController();
  BoxFit _currentFit = BoxFit.contain;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: GestureDetector(
                  onDoubleTap: _cycleFitMode,
                  child: InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        color: Colors.black,
                      ),
                      child: kIsWeb
                          ? Image.memory(
                              widget.imageBytes,
                              fit: _currentFit,
                            )
                          : Image.file(
                              widget.image!,
                              fit: _currentFit,
                            ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.aspect_ratio),
                      onPressed: _cycleFitMode,
                      tooltip: 'Change Image Fit',
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _cycleFitMode() {
    setState(() {
      switch (_currentFit) {
        case BoxFit.contain:
          _currentFit = BoxFit.cover;
          break;
        case BoxFit.cover:
          _currentFit = BoxFit.fitWidth;
          break;
        case BoxFit.fitWidth:
          _currentFit = BoxFit.fitHeight;
          break;
        case BoxFit.fitHeight:
          _currentFit = BoxFit.none;
          break;
        case BoxFit.none:
          _currentFit = BoxFit.scaleDown;
          break;
        case BoxFit.scaleDown:
          _currentFit = BoxFit.contain;
          break;
        case BoxFit.fill:
          _currentFit = BoxFit.contain;
          break;
      }
      _transformationController.value = Matrix4.identity();
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }
}
