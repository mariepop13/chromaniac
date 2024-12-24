import 'dart:async';
import 'dart:convert';
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
  static bool _isInitialized = false;
  
  static bool get isInitialized => _isInitialized;
  

  static void enableTestMode() {
    if (_isInitialized) return;
    
    _logger = Logger(
      printer: SimpleLogPrinter(),
      output: ConsoleOutput(),
    );
    
    _isInitialized = true;
  }

  static Future<String> _getAppLogsDirectory() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return Directory.systemTemp.path;
    }
    
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final logsDir = Directory('${appDir.path}/debug_logs');
      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }
      return logsDir.path;
    } catch (e) {
      _logger.w('Failed to create primary log directories: $e');
      return Directory.systemTemp.path;
    }
  }

  static Future<String> _getLocalLogsDirectory() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return Directory.systemTemp.path;
    }
    
    try {
      final cacheDir = await getTemporaryDirectory();
      final logsDir = Directory('${cacheDir.path}/app_logs');
      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }
      return logsDir.path;
    } catch (e) {
      _logger.w('Failed to create local log directories: $e');
      return Directory.systemTemp.path;
    }
  }

  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      final appLogsDirectory = await _getAppLogsDirectory();
      final localLogsDirectory = await _getLocalLogsDirectory();
      
      _startTime = _fileNameFormat.format(DateTime.now());
      final logFileName = 'debug_logs_$_startTime.txt';
      _logFile = File('$appLogsDirectory/$logFileName');
      _localLogFile = File('$localLogsDirectory/$logFileName');

      _logger = Logger(
        printer: SimpleLogPrinter(),
        output: MultiOutput([
          ConsoleOutput(),
          FileOutput(_logFile),
          FileOutput(_localLogFile),
        ]),
      );

      _isInitialized = true;

      final timestamp = _dateFormat.format(DateTime.now());
      final initialMessage = '[$timestamp] ✨ Log file created: $logFileName\n';
      await _logFile.writeAsString(initialMessage, encoding: utf8, flush: true);
      await _localLogFile.writeAsString(initialMessage, encoding: utf8, flush: true);
      
      await _writeToFiles('✨ Application initialized at $timestamp');
      debugPrint('✅ Logger initialized successfully');

      debugPrint('📁 App logs directory: $appLogsDirectory');
      debugPrint('📁 Local logs directory: $localLogsDirectory');
    } catch (e, stackTrace) {
      _isInitialized = false;
      debugPrint('❌ Error initializing logger: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }


  static void _checkInitialized() {
    if (!_isInitialized) {
      throw StateError('AppLogger must be initialized by calling init() before use');
    }
  }

  static Future<void> _writeToFiles(String message) async {
    _checkInitialized();
    try {
      final timestamp = _dateFormat.format(DateTime.now());
      final logMessage = '[$timestamp] $message\n';
      await _logFile.writeAsString(logMessage, 
          mode: FileMode.append, 
          encoding: utf8,
          flush: true);
      await _localLogFile.writeAsString(logMessage, 
          mode: FileMode.append, 
          encoding: utf8,
          flush: true);
    } catch (e, stackTrace) {
      debugPrint('❌ Error writing to log files: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  static void i(String message) {
    _checkInitialized();
    _logger.i(message);
    unawaited(_writeToFiles('ℹ️ $message'));
  }

  static void d(String message) {
    _checkInitialized();
    _logger.d(message);
    unawaited(_writeToFiles('🔍 $message'));
  }

  static void w(String message) {
    _checkInitialized();
    _logger.w(message);
    unawaited(_writeToFiles('⚠️ $message'));
  }

  static void e(String message, {Object? error, StackTrace? stackTrace}) {
    _checkInitialized();
    _logger.e(message, error: error, stackTrace: stackTrace);
    unawaited(_writeToFiles('❌ $message${error != null ? '\nError: $error' : ''}${stackTrace != null ? '\nStack: $stackTrace' : ''}'));
  }

  static String get currentLogFile => _logFile.path;
  static String get localLogFile => _localLogFile.path;
  static String get logsDirectory => _logsDirectory.path;
  static String get localLogsDirectory => _localLogsDirectory.path;
}

class SimpleLogPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    final List<String> lines = [];
    

    lines.add(event.message);
    

    if (event.error != null) {
      lines.add(event.error.toString());
    }
    

    if (event.stackTrace != null) {
      final frames = event.stackTrace.toString().trim().split('\n')
        .map((line) => line.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '')) // Remove ANSI color codes
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty);
      lines.addAll(frames);
    }
    
    return lines;
  }
}

class FileOutput extends LogOutput {
  final File file;

  FileOutput(this.file);

  @override
  void output(OutputEvent event) {
    final message = '${event.lines.join('\n')}\n';
    file.writeAsStringSync(message, 
        mode: FileMode.append, 
        encoding: utf8,
        flush: true);
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
