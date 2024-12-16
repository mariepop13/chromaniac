import 'dart:typed_data';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';

class ProcreateSwatchesError implements Exception {
  final String message;
  ProcreateSwatchesError(this.message);

  @override
  String toString() => 'ProcreateSwatchesError: $message';
}

void checkColorSpaceSupport(String space) {
  const supportedSpaces = ['hsv']; // Add other supported spaces if needed
  if (!supportedSpaces.contains(space)) {
    throw ProcreateSwatchesError('Color space $space is not supported.');
  }
}

Future<Map<String, dynamic>> readSwatchesFile(Uint8List data, [String space = 'hsv']) async {
  checkColorSpaceSupport(space);
  try {
    final archive = ZipDecoder().decodeBytes(data);
    final swatchesFile = archive.files.firstWhere((file) => file.name == 'Swatches.json');
    final swatchesRawString = utf8.decode(swatchesFile.content as List<int>);
    var swatchesData = jsonDecode(swatchesRawString);

    if (swatchesData is List) {
      swatchesData = swatchesData[0];
    }

    final name = swatchesData['name'];
    final swatches = swatchesData['swatches'];

    return {
      'name': name,
      'colors': swatches.map((swatch) {
        if (swatch == null) return null;
        final hue = swatch['hue'] * 360;
        final saturation = swatch['saturation'] * 100;
        final brightness = swatch['brightness'] * 100;
        var color = [hue, saturation, brightness];
        if (space != 'hsv') {
        }
        return [color, space];
      }).toList(),
    };
  } catch (error) {
    throw ProcreateSwatchesError('Invalid .swatches file.');
  }
}

Future<Uint8List> createSwatchesFile(String name, List colors, [String format = 'uint8array']) async {
  final swatchesData = {
    'name': name,
    'swatches': colors.map((entry) {
      if (entry == null) return null;
      if (entry is! List || entry.length != 2) {
        throw TypeError();
      }
      var color = entry[0];
      final space = entry[1];
      if (space != 'hsv') {
        checkColorSpaceSupport(space);
      }
      final h = color[0] / 360;
      final s = color[1] / 100;
      final v = color[2] / 100;
      return {
        'hue': h,
        'saturation': s,
        'brightness': v,
        'alpha': 1,
        'colorSpace': 0,
      };
    }).take(30).toList(),
  };

  final encoder = ZipEncoder();
  final zipData = encoder.encode(Archive()
    ..addFile(ArchiveFile('Swatches.json', utf8.encode(jsonEncode(swatchesData)).length, utf8.encode(jsonEncode(swatchesData)))));

  return Uint8List.fromList(zipData);
}

void exportPalette(BuildContext context, List<Color> palette) async {
  if (kIsWeb) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Export not supported on web')),
    );
    return;
  }

  final swatchesContent = _createSwatchesContent(palette);

  Directory directory = await getApplicationDocumentsDirectory();
  String filePath = '${directory.path}/palette.swatches';

  File file = File(filePath);
  await file.writeAsBytes(swatchesContent);

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

Uint8List _createSwatchesContent(List<Color> palette) {
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

Future<void> exportSwatches(
    BuildContext context, String paletteName, List<Color> colors) async {
  final List<Map<String, String>> swatches = colors.map((color) {
    return {"color": "#${color.value.toRadixString(16).substring(2)}", "type": "color"};
  }).toList();

  final jsonContent = jsonEncode({
    "name": paletteName,
    "swatches": swatches,
  });

  final directory = await getTemporaryDirectory();
  final jsonFile = File('${directory.path}/Swatches.json');
  await jsonFile.writeAsString(jsonContent);

  final encoder = ZipFileEncoder();
  final swatchesPath = '${directory.path}/$paletteName.swatches';
  encoder.create(swatchesPath);
  encoder.addFile(jsonFile);
  encoder.close();

  try {
    await Share.shareXFiles([XFile(swatchesPath)]);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing file: $e')),
      );
    }
  }
}