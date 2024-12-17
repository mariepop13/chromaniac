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
  
  if (data.isEmpty) {
    throw ProcreateSwatchesError('Invalid .swatches file: empty data');
  }

  try {
    final Archive archive = _decodeArchive(data);
    if (archive.isEmpty) {
      throw ProcreateSwatchesError('Invalid .swatches file: empty archive');
    }

    final String swatchesRawString = _extractSwatchesJson(archive);
    if (swatchesRawString.isEmpty) {
      throw ProcreateSwatchesError('Invalid .swatches file: no Swatches.json found');
    }

    final Map<String, dynamic> swatchesData = _parseSwatchesData(swatchesRawString);
    if (swatchesData['name'] == null || swatchesData['swatches'] == null) {
      throw ProcreateSwatchesError('Invalid .swatches file: missing required fields');
    }

    final result = _processSwatchesData(swatchesData, space);
    
    if (result['colors'].any((color) => color == null)) {
      result['colors'].removeWhere((color) => color == null);
    }

    return result;
  } on ArchiveException catch (e) {
    throw ProcreateSwatchesError('Invalid .swatches file: corrupted archive - ${e.message}');
  } on FormatException catch (e) {
    throw ProcreateSwatchesError('Invalid .swatches file: invalid JSON format - ${e.message}');
  } catch (error) {
    throw ProcreateSwatchesError('Invalid .swatches file: ${error.toString()}');
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
      
      final double hue = (swatch['hue'] ?? 0.0).toDouble();
      final double saturation = (swatch['saturation'] ?? 0.0).toDouble();
      final double brightness = (swatch['brightness'] ?? 0.0).toDouble();
      
      List<double> color = [hue * 360, saturation * 100, brightness * 100];
      
      if (space == 'rgb') {
        color = _hsvToRgb(color[0], color[1], color[2]);
      }
      
      return [color, space];
    }).toList()..removeWhere((color) => color == null),
  };
}

List<double> _hsvToRgb(double h, double s, double v) {
  h = h / 360;
  s = s / 100;
  v = v / 100;
  
  final i = (h * 6).floor();
  final f = h * 6 - i;
  final p = v * (1 - s);
  final q = v * (1 - f * s);
  final t = v * (1 - (1 - f) * s);
  
  double r, g, b;
  
  switch (i % 6) {
    case 0: r = v; g = t; b = p; break;
    case 1: r = q; g = v; b = p; break;
    case 2: r = p; g = v; b = t; break;
    case 3: r = p; g = q; b = v; break;
    case 4: r = t; g = p; b = v; break;
    case 5: r = v; g = p; b = q; break;
    default: r = 0; g = 0; b = 0;
  }
  
  return [r * 255, g * 255, b * 255];
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
