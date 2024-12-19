import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class AppLogger {
  static late Logger _logger;
  static late File _logFile;
  static late File _localLogFile;
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  static final DateFormat _fileNameFormat = DateFormat('yyyy-MM-dd_HH-mm-ss');
  static late String _startTime;
  static late Directory _logsDirectory;
  static late Directory _localLogsDirectory;
  
  // Local project directory path
  static const String _localLogsPath = '/Users/marie/chromaniac/debug_logs';

  static Future<void> init() async {
    try {
      _startTime = _fileNameFormat.format(DateTime.now());
      final logFileName = 'debug_logs_$_startTime.txt';
      
      // Setup app documents directory logging
      final appDir = await getApplicationDocumentsDirectory();
      _logsDirectory = Directory('${appDir.path}/logs');
      await _logsDirectory.create(recursive: true);
      _logFile = File('${_logsDirectory.path}/$logFileName');
      
      // Setup local project directory logging
      _localLogsDirectory = Directory(_localLogsPath);
      await _localLogsDirectory.create(recursive: true);
      _localLogFile = File('${_localLogsDirectory.path}/$logFileName');
      
      debugPrint('📁 App logs directory: ${_logsDirectory.path}');
      debugPrint('📁 Local logs directory: ${_localLogsDirectory.path}');
      
      // Initialize logger
      _logger = Logger(
        printer: PrettyPrinter(
          methodCount: 0,
          errorMethodCount: 8,
          lineLength: 120,
          colors: true,
          printEmojis: true,
        ),
        output: MultiOutput([
          ConsoleOutput(),
          FileOutput(_logFile),
          FileOutput(_localLogFile),
        ]),
      );

      // Write initial log entries
      final timestamp = _dateFormat.format(DateTime.now());
      final initialMessage = '[$timestamp] 🚀 Log file created: $logFileName\n';
      await _logFile.writeAsString(initialMessage);
      await _localLogFile.writeAsString(initialMessage);
      
      await _writeToFiles('🚀 Application initialized at $timestamp');
      debugPrint('✅ Logger initialized successfully');
      
    } catch (e, stackTrace) {
      debugPrint('❌ Error initializing logger: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<void> _writeToFiles(String message) async {
    try {
      final timestamp = _dateFormat.format(DateTime.now());
      final logMessage = '[$timestamp] $message\n';
      await _logFile.writeAsString(logMessage, mode: FileMode.append);
      await _localLogFile.writeAsString(logMessage, mode: FileMode.append);
    } catch (e, stackTrace) {
      debugPrint('❌ Error writing to log files: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  static void i(String message) async {
    _logger.i(message);
    await _writeToFiles('ℹ️ $message');
  }

  static void d(String message) async {
    _logger.d(message);
    await _writeToFiles('🔍 $message');
  }

  static void w(String message) async {
    _logger.w(message);
    await _writeToFiles('⚠️ $message');
  }

  static void e(String message, {Object? error, StackTrace? stackTrace}) async {
    _logger.e(message, error: error, stackTrace: stackTrace);
    await _writeToFiles('❌ $message${error != null ? '\nError: $error' : ''}${stackTrace != null ? '\nStack: $stackTrace' : ''}');
  }

  static String get currentLogFile => _logFile.path;
  static String get localLogFile => _localLogFile.path;
  static String get logsDirectory => _logsDirectory.path;
  static String get localLogsDirectory => _localLogsDirectory.path;
}

class FileOutput extends LogOutput {
  final File file;

  FileOutput(this.file);

  @override
  void output(OutputEvent event) {
    try {
      for (var line in event.lines) {
        file.writeAsStringSync('$line\n', mode: FileMode.append);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error in FileOutput: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }
}

class MultiOutput extends LogOutput {
  final List<LogOutput> outputs;

  MultiOutput(this.outputs);

  @override
  void output(OutputEvent event) {
    for (var output in outputs) {
      output.output(event);
    }
  }
}
