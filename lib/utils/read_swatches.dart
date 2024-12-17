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
    final Archive archive = _decodeArchive(data);
    final String swatchesRawString = _extractSwatchesJson(archive);
    final Map<String, dynamic> swatchesData = _parseSwatchesData(swatchesRawString);

    return _processSwatchesData(swatchesData, space);
  } catch (error) {
    throw ProcreateSwatchesError('Invalid .swatches file.');
  }
}

Archive _decodeArchive(Uint8List data) {
  final ZipDecoder zipDecoder = ZipDecoder();
  return zipDecoder.decodeBytes(data);
}

String _extractSwatchesJson(Archive archive) {
  final ArchiveFile swatchesFile = archive.files.firstWhere((file) => file.name == 'Swatches.json');
  return utf8.decode(swatchesFile.content);
}

Map<String, dynamic> _parseSwatchesData(String swatchesRawString) {
  dynamic swatchesData = jsonDecode(swatchesRawString);
  if (swatchesData is List) {
    swatchesData = swatchesData[0];
  }
  return swatchesData;
}

Map<String, dynamic> _processSwatchesData(Map<String, dynamic> swatchesData, String space) {
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
