import 'package:flutter/foundation.dart';
import 'dart:html' as html;

class WebConfig {
  static void configureWebInputHandling() {
    if (kIsWeb) {
      // Prevent default touch behaviors that might interfere with Flutter's event handling
      html.document.addEventListener('touchstart', (event) {
        event.preventDefault();
      });

      html.document.addEventListener('touchmove', (event) {
        event.preventDefault();
      });
    }
  }
} 