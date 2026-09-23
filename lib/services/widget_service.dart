import 'package:flutter/services.dart';

class WidgetService {
  static const MethodChannel _channel = MethodChannel('com.worldradio.app/widget');

  static Future<void> updateWidget({
    required String name,
    required String country,
    required bool isPlaying,
  }) async {
    try {
      await _channel.invokeMethod('updateWidget', {
        'name': name,
        'country': country,
        'isPlaying': isPlaying,
      });
    } catch (_) {}
  }

  static Future<void> enterPip() async {
    try {
      await _channel.invokeMethod('enterPip');
    } catch (_) {}
  }

  static void setWidgetListener(Function() onToggle) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onWidgetTogglePlay') {
        onToggle();
      }
    });
  }
}
