import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart' show getApplicationDocumentsDirectory;

Future<void> shareFile(BuildContext context, String filePath) async {
  try {
    await Share.shareXFiles([XFile(filePath)]);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing file: $e')),
      );
    }
  }
}

Future<void> exportPalette(BuildContext context, List<Color> palette) async {
  if (kIsWeb || Platform.isMacOS) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Export not supported on web or macOS')),
    );
    return;
  }

  final swatchesContent = createSwatchesContent(palette);
  final filePath = await getSwatchesFilePath();
  await writeSwatchesFile(filePath, swatchesContent);

  if (!context.mounted) return;

  await shareFile(context, filePath);
}

Uint8List createSwatchesContent(List<Color> palette) {
  final int colorCount = palette.length;

  final List<int> metadata = [
    0x53, 0x57, 0x41, 0x54,
    0x01, 0x00, 0x00, 0x00,
    colorCount, 0x00, 0x00, 0x00,
  ];

  final List<int> colorData = [];
  for (Color color in palette) {
    colorData.addAll([
      color.red,
      color.green,
      color.blue,
      color.alpha,
    ]);
  }

  return Uint8List.fromList(metadata + colorData);
}

Future<String> getSwatchesFilePath() async {
  Directory directory = await getApplicationDocumentsDirectory();
  return '${directory.path}/palette.swatches';
}

Future<void> writeSwatchesFile(String filePath, Uint8List content) async {
  File file = File(filePath);
  await file.writeAsBytes(content);
}