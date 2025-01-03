import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

Future<void> initializePlatformLogger() async {
  if (kIsWeb) return;

  try {
    final appDir = await getApplicationDocumentsDirectory();
    final logsDir = Directory('${appDir.path}/debug_logs');
    if (!await logsDir.exists()) {
      await logsDir.create(recursive: true);
    }

    final cacheDir = await getTemporaryDirectory();
    final localLogsDir = Directory('${cacheDir.path}/app_logs');
    if (!await localLogsDir.exists()) {
      await localLogsDir.create(recursive: true);
    }

    debugPrint('📁 App logs directory: ${logsDir.path}');
    debugPrint('📁 Local logs directory: ${localLogsDir.path}');
  } catch (e) {
    debugPrint('❌ Error creating log directories: $e');
  }
} 