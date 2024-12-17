import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
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

Future<String> getSwatchesFilePath() async {
  Directory directory = await getApplicationDocumentsDirectory();
  return '${directory.path}/palette.swatches';
}

Future<void> writeSwatchesFile(String filePath, Uint8List content) async {
  File file = File(filePath);
  await file.writeAsBytes(content);
}

Future<Uint8List> createSwatchesFile(String name, List colors, {String format = 'uint8array'}) async {
  final swatchesData = [{
    'name': name,
    'swatches': colors.take(30).map((entry) {
      if (entry == null) return null;
      if (entry is! List || entry.length != 2) {
        throw ProcreateSwatchesError('Invalid entry format: $entry. Expected a list with 2 elements.');
      }
      final List rawColor = entry[0];
      final space = entry[1];
      
      if (!rawColor.every((e) => e is num)) {
        throw ProcreateSwatchesError('Color values must be numbers');
      }
      
      var color = rawColor.map((e) => (e as num).toDouble()).toList();
      
      if (space != 'hsv') {
        checkColorSpaceSupport(space);
        try {
          color = convertColor(color, from: space, to: 'hsv');
        } catch (error) {
          throw ProcreateSwatchesError('$color is not a valid $space color');
        }
      }
      
      return {
        'hue': color[0] / 360,
        'saturation': color[1] / 100,
        'brightness': color[2] / 100,
        'alpha': 1,
        'colorSpace': 0,
      };
    }).toList(),
  }];

  final encoder = ZipEncoder();
  final archive = Archive();
  archive.addFile(ArchiveFile('Swatches.json', utf8.encode(jsonEncode(swatchesData)).length, utf8.encode(jsonEncode(swatchesData))));

  return Uint8List.fromList(encoder.encode(archive));
}

void checkColorSpaceSupport(String space) {
  if (!getSupportedColorSpaces().contains(space)) {
    throw ProcreateSwatchesError('Color space $space is not supported.');
  }
}

List<String> getSupportedColorSpaces() {
  return ['hsv', 'rgb'];
}

List<double> convertColor(List<num> color, {required String from, required String to}) {
  if (color.length != 3) {
    throw ProcreateSwatchesError('Color must have exactly 3 components');
  }
  final values = color.map((e) => e.toDouble()).toList();
  
  if (from == 'rgb' && to == 'hsv') {
    // Add conversion logic here
    return values;
  }
  // Add more conversions as needed
  return values;
}

class ProcreateSwatchesError implements Exception {
  final String message;
  ProcreateSwatchesError(this.message);

  @override
  String toString() => 'ProcreateSwatchesError: $message';
}