import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

void exportPalette(BuildContext context, List<Color> palette) async {
  if (kIsWeb) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Export not supported on web')),
    );
    return;
  }

  final swatchesPalette = _convertToSwatchesPalette(palette);

  final swatchesContent = [
    'SwatchesPalette',
    'Version: 1.0',
    ...swatchesPalette
  ].join('\n');

  Directory directory = await getApplicationDocumentsDirectory();
  String filePath = '${directory.path}/palette.swatches';

  File file = File(filePath);
  await file.writeAsString(swatchesContent);

  if (!context.mounted) return;

  try {
    await Share.shareXFiles([XFile(filePath)]);
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error sharing file: $e')),
    );
  }
}

List<String> _convertToSwatchesPalette(List<Color> palette) {
  return palette.map((color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }).toList();
}
