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
  static bool _isTestMode = false;
  
  static bool get isInitialized => _isInitialized;
  
  static const String _localLogsPath = 'debug_logs';
  static const String _testLogsPath = 'test/debug_logs';

  static void enableTestMode() {
    _isTestMode = true;
  }

  static Future<Directory> get _projectDir async {
    final currentDir = Directory.current;
    return currentDir;
  }

  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      _startTime = _fileNameFormat.format(DateTime.now());
      final logFileName = 'debug_logs_$_startTime.txt';
      final projectDir = await _projectDir;

      if (_isTestMode) {
        _logsDirectory = Directory('${projectDir.path}/$_testLogsPath');
        _localLogsDirectory = _logsDirectory;
      } else {
        if (!kIsWeb && !Platform.isIOS && !Platform.isAndroid) {
          // For desktop platforms, use project directory
          _logsDirectory = Directory('${projectDir.path}/$_localLogsPath');
          _localLogsDirectory = _logsDirectory;
        } else {
          // For mobile platforms, use app support directory
          final appDir = await getApplicationSupportDirectory();
          _logsDirectory = Directory('${appDir.path}/logs');
          _localLogsDirectory = Directory('${projectDir.path}/$_localLogsPath');
        }
      }

      await _ensureDirectoriesExist();

      _logFile = File('${_logsDirectory.path}/$logFileName');
      _localLogFile = File('${_localLogsDirectory.path}/$logFileName');

      debugPrint('📁 App logs directory: ${_logsDirectory.path}');
      debugPrint('📁 Local logs directory: ${_localLogsDirectory.path}');

      _logger = Logger(
        printer: PrettyPrinter(
          methodCount: 0,
          errorMethodCount: 8,
          lineLength: 120,
          colors: false,
          printEmojis: true,
        ),
        output: MultiOutput([
          ConsoleOutput(),
          FileOutput(_logFile),
          if (!_isTestMode) FileOutput(_localLogFile),
        ]),
      );

      _isInitialized = true;

      final timestamp = _dateFormat.format(DateTime.now());
      final initialMessage = '[$timestamp] ✨ Log file created: $logFileName\n';
      await _logFile.writeAsString(initialMessage, encoding: utf8, flush: true);
      if (!_isTestMode) {
        await _localLogFile.writeAsString(initialMessage, encoding: utf8, flush: true);
      }
      
      await _writeToFiles('✨ Application initialized at $timestamp');
      debugPrint('✅ Logger initialized successfully');

    } catch (e, stackTrace) {
      _isInitialized = false;
      debugPrint('❌ Error initializing logger: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<void> _ensureDirectoriesExist() async {
    try {
      if (!_logsDirectory.existsSync()) {
        await _logsDirectory.create(recursive: true);
      }
      if (!_isTestMode && !_localLogsDirectory.existsSync()) {
        await _localLogsDirectory.create(recursive: true);
      }
    } catch (e) {
      debugPrint('⚠️ Failed to create primary log directories: $e');
      debugPrint('↪️ Falling back to temporary directory');
      
      final tempDir = await getTemporaryDirectory();
      final fallbackDir = Directory('${tempDir.path}/app_logs');
      if (!fallbackDir.existsSync()) {
        await fallbackDir.create(recursive: true);
      }
      _logsDirectory = fallbackDir;
      _localLogsDirectory = fallbackDir;
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
      if (!_isTestMode) {
        await _localLogFile.writeAsString(logMessage, 
            mode: FileMode.append, 
            encoding: utf8,
            flush: true);
      }
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
