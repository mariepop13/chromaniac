import 'package:logging/logging.dart';

class LoggerUtil {
  static final Logger _logger = Logger('ChromaniacLogger');
  static bool _initialized = false;

  static void initialize() {
    if (_initialized) return;
    
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      // ignore: avoid_print
      print('${record.level.name}: ${record.time}: ${record.message}');
      if (record.error != null) {
        // ignore: avoid_print
        print('Error: ${record.error}\nStack trace:\n${record.stackTrace}');
      }
    });
    _initialized = true;
  }

  static void info(String message) => _logger.info(message);
  static void warning(String message) => _logger.warning(message);
  static void error(String message, [Object? error, StackTrace? stackTrace]) => 
      _logger.severe(message, error, stackTrace);
}
