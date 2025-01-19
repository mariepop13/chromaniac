import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart'
    show getApplicationDocumentsDirectory;
import 'read_swatches.dart';
import 'package:chromaniac/utils/logger/app_logger.dart';

Future<void> shareFile(BuildContext context, String filePath,
    {RenderBox? originBox}) async {
  try {
    final sharePosition = originBox != null
        ? originBox.localToGlobal(Offset.zero) & originBox.size
        : null;

    await Share.shareXFiles(
      [XFile(filePath)],
      sharePositionOrigin: sharePosition,
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing file: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

Future<void> exportPalette(BuildContext context, List<Color> palette,
    {RenderBox? originBox}) async {
  try {
    final swatchesContent = createSwatchesContent(palette);

    if (kIsWeb) {
      final base64Content = base64Encode(swatchesContent);
      final dataUri = 'data:application/zip;base64,$base64Content';

      downloadFile(dataUri, 'Palette.swatches');

      _showSuccessSnackBar(context);
    } else if (Platform.isMacOS) {
      _showUnsupportedSnackBar(context);
      return;
    } else {
      if (!context.mounted) return;

      final filePath = await getSwatchesFilePath();
      await writeSwatchesFile(filePath, swatchesContent);

      if (!context.mounted) return;

      await shareFile(context, filePath, originBox: originBox);
    }
  } catch (e) {
    if (context.mounted) {
      _showErrorSnackBar(context, e);
    }
  }
}

void _showSuccessSnackBar(BuildContext context) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Palette exported successfully. Check your downloads.'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.green,
        ),
      );
    }
  });
}

void _showUnsupportedSnackBar(BuildContext context) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Export is not supported on macOS'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  });
}

void _showErrorSnackBar(BuildContext context, Object error) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during export: $error'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  });
}

void downloadFile(String dataUri, String filename) {
  AppLogger.d('Downloading: $filename from $dataUri');
}

Uint8List createSwatchesContent(List<Color> palette) {
  final swatchesData = [
    {
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
    }
  ];

  final encoder = ZipEncoder();
  final archive = Archive();

  archive.addFile(ArchiveFile(
      'Swatches.json',
      utf8.encode(jsonEncode(swatchesData)).length,
      utf8.encode(jsonEncode(swatchesData))));

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

Future<Uint8List> createSwatchesFile(String name, List colors,
    {String format = 'uint8array'}) async {
  final swatchesData = [
    {
      'name': name,
      'swatches': colors.take(30).map((entry) {
        if (entry == null) return null;
        if (entry is! List || entry.length != 2) {
          throw ProcreateSwatchesError(
              'Invalid entry format: $entry. Expected a list with 2 elements.');
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
    }
  ];

  final encoder = ZipEncoder();
  final archive = Archive();
  archive.addFile(ArchiveFile(
      'Swatches.json',
      utf8.encode(jsonEncode(swatchesData)).length,
      utf8.encode(jsonEncode(swatchesData))));

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

List<double> convertColor(List<num> color,
    {required String from, required String to}) {
  if (color.length != 3) {
    throw ProcreateSwatchesError('Color must have exactly 3 components');
  }
  final values = color.map((e) => e.toDouble()).toList();

  if (from == 'rgb' && to == 'hsv') {
    return values;
  }
  return values;
}
