import 'dart:typed_data';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart' show getApplicationDocumentsDirectory;
import 'package:archive/archive.dart';
import 'dart:convert';

Future<String> getSwatchesFilePath() async {
  Directory directory = await getApplicationDocumentsDirectory();
  return '${directory.path}/palette.swatches';
}

Future<void> writeSwatchesFile(String filePath, Uint8List content) async {
  File file = File(filePath);
  await file.writeAsBytes(content);
}

Uint8List createSwatchesContent(List<Color> palette) {
  final swatchesData = [{
    'name': 'Palette',
    'swatches': palette.map((color) {
      final HSVColor hsvColor = HSVColor.fromColor(color);
      
      return {
        'hue': hsvColor.hue / 360,
        'saturation': hsvColor.saturation,
        'brightness': hsvColor.value,
        'alpha': hsvColor.alpha,
        'colorSpace': 0
      };
    }).toList()
  }];

  final encoder = ZipEncoder();
  final archive = Archive();
  
  archive.addFile(
    ArchiveFile(
      'Swatches.json',
      utf8.encode(jsonEncode(swatchesData)).length,
      utf8.encode(jsonEncode(swatchesData))
    )
  );

  return Uint8List.fromList(encoder.encode(archive));
}
