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
