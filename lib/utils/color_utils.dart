import 'dart:typed_data';
import 'dart:convert';
import 'package:archive/archive.dart';

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
    return values;
  }
  return values;
}

class ProcreateSwatchesError implements Exception {
  final String message;
  ProcreateSwatchesError(this.message);

  @override
  String toString() => 'ProcreateSwatchesError: $message';
}
