import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';

class ProcreateSwatchesError implements Exception {
  final String message;
  ProcreateSwatchesError(this.message);

  @override
  String toString() => 'ProcreateSwatchesError: $message';
}

void checkColorSpaceSupport(String space) {
  if (!getSupportedColorSpaces().contains(space)) {
    throw ProcreateSwatchesError('Color space $space is not supported.');
  }
}

Future<Map<String, dynamic>> readSwatchesFile(Uint8List data, {String space = 'hsv'}) async {
  checkColorSpaceSupport(space);
  try {
    final ZipDecoder zipDecoder = ZipDecoder();
    final Archive archive = zipDecoder.decodeBytes(data);
    final ArchiveFile swatchesFile = archive.files.firstWhere((file) => file.name == 'Swatches.json');
    final String swatchesRawString = utf8.decode(swatchesFile.content);

    dynamic swatchesData = jsonDecode(swatchesRawString);
    if (swatchesData is List) {
      swatchesData = swatchesData[0];
    }

    final name = swatchesData['name'];
    final swatches = swatchesData['swatches'];

    return {
      'name': name,
      'colors': swatches.map((swatch) {
        if (swatch == null) return null;
        final hue = swatch['hue'];
        final saturation = swatch['saturation'];
        final brightness = swatch['brightness'];
        List<double> color = [hue * 360, saturation * 100, brightness * 100];
        if (space != 'hsv') {
          color = convert(color, from: 'hsv', to: space);
        }
        return [color, space];
      }).toList(),
    };
  } catch (error) {
    throw ProcreateSwatchesError('Invalid .swatches file.');
  }
}

Future<Uint8List> createSwatchesFile(String name, List colors, {String format = 'uint8array'}) async {
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
        try {
          color = convert(color, from: space, to: 'hsv');
        } catch (error) {
          throw ProcreateSwatchesError('$color is not a valid $space color');
        }
      }
      final h = color[0];
      final s = color[1];
      final v = color[2];
      return {
        'hue': h / 360,
        'saturation': s / 100,
        'brightness': v / 100,
        'alpha': 1,
        'colorSpace': 0,
      };
    }).toList().sublist(0, 30),
  };

  final encoder = ZipEncoder();
  final archive = Archive();
  archive.addFile(ArchiveFile('Swatches.json', utf8.encode(jsonEncode(swatchesData)).length, utf8.encode(jsonEncode(swatchesData))));

  return Uint8List.fromList(encoder.encode(archive));
}

List<String> getSupportedColorSpaces() {
  return ['hsv', 'rgb'];
}

List<double> convert(List<double> color, {required String from, required String to}) {
  if (from == 'hsv' && to == 'rgb') {
    // Add conversion logic here
  }
  // Add more conversions as needed
  return color;
}
