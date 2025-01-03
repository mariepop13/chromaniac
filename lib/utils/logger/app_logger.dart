import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';

// Conditional import for platform-specific functionality
import 'app_logger_mobile.dart' if (dart.library.html) 'app_logger_web.dart';

class AppLogger {
  static late Logger _logger;
  static bool _isInitialized = false;
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  
  static bool get isInitialized => _isInitialized;

  static void enableTestMode() {
    if (_isInitialized) return;
    
    _logger = Logger(
      printer: SimpleLogPrinter(),
      output: ConsoleOutput(),
    );
    
    _isInitialized = true;
  }

  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Platform-specific initialization
      await initializePlatformLogger();

      _logger = Logger(
        printer: SimpleLogPrinter(),
        output: ConsoleOutput(),
      );

      _isInitialized = true;

      final timestamp = _dateFormat.format(DateTime.now());
      debugPrint('✅ Logger initialized successfully at $timestamp');
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

  static void i(String message) {
    _checkInitialized();
    _logger.i(message);
  }

  static void d(String message) {
    _checkInitialized();
    _logger.d(message);
  }

  static void w(String message) {
    _checkInitialized();
    _logger.w(message);
  }

  static void e(String message, {Object? error, StackTrace? stackTrace}) {
    _checkInitialized();
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
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
        .map((line) => line.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), ''))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty);
      lines.addAll(frames);
    }
    
    return lines;
  }
}
