import 'package:flutter/services.dart';

class RfidService {
  // باید دقیقاً همون اسمی باشه که تو Kotlin نوشتیم
  static const _methodChannel = MethodChannel('com.hitag.rfid/methods');
  static const _eventChannel = EventChannel('com.hitag.rfid/events');

  Stream<Map<String, String>>? _tagStream;

  // ── اتصال به ریدر ─────────────────────────────────────────────
  Future<bool> init() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('init');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  // ── شروع اسکن ────────────────────────────────────────────────
  Future<bool> startScan() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('startScan');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  // ── توقف اسکن ────────────────────────────────────────────────
  Future<bool> stopScan() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('stopScan');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  // ── قطع اتصال ────────────────────────────────────────────────
  Future<bool> free() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('free');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  // ── دریافت stream تگ‌ها ───────────────────────────────────────
  Stream<Map<String, String>> get tagStream {
    _tagStream ??= _eventChannel.receiveBroadcastStream().map(
      (event) => Map<String, String>.from(event as Map),
    );
    return _tagStream!;
  }
}
