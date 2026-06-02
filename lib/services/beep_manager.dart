import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class BeepManager extends ChangeNotifier {
  // سینگلتون برای ماندگاری (گلوبال شدن) در کل اپ
  static final BeepManager _instance = BeepManager._internal();
  factory BeepManager() => _instance;
  BeepManager._internal();

  final List<Map<String, dynamic>> trustList = [];
  int? alertTimeInMinutes = 1;
  bool isMuted = false;

  final AudioPlayer _player = AudioPlayer();
  Timer? _timer;
  bool _isPlaying = false;

  // این رو باید توی main.dart فقط یک بار صدا بزنی
  void startMonitoring() {
    if (_timer != null && _timer!.isActive) return;
    print("--- BeepManager Started ---");
    // تایمر هر ۱ ثانیه اجرا میشه
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkAndBeep();
      notifyListeners(); // باعث میشه ثانیه‌شمار توی UI آپدیت بشه!
    });
  }

  void addItem(Map<String, dynamic> item) {
    if (trustList.any((e) => e['epc'] == item['epc'])) return;
    trustList.add({...item, 'start_time': DateTime.now()});
    notifyListeners();
  }

  void removeItem(int index) {
    trustList.removeAt(index);
    notifyListeners();
  }

  void setAlertTime(int? minutes) {
    alertTimeInMinutes = minutes;
    notifyListeners();
  }

  void toggleMute() {
    isMuted = !isMuted;
    notifyListeners();
  }

  Future<void> _checkAndBeep() async {
    if (isMuted || alertTimeInMinutes == null || trustList.isEmpty) return;

    bool shouldBeep = false;
    final now = DateTime.now();

    for (var item in trustList) {
      if (item['start_time'] != null) {
        final duration = now.difference(item['start_time']);
        if (duration.inMinutes >= alertTimeInMinutes!) {
          shouldBeep = true;
          break; // یکی هم گذشته باشه کافیه
        }
      }
    }

    if (shouldBeep) {
      playBeep();
    }
  }

  // پخش صدای بیپ
  Future<void> playBeep() async {
    if (_isPlaying || isMuted) return;
    _isPlaying = true;
    try {
      await _player.play(
        AssetSource('sounds/beep.mp3'),
      ); // مطمئن شو این فایل رو داری
    } catch (e) {
      print("Error playing beep: $e");
    } finally {
      await Future.delayed(const Duration(seconds: 1));
      _isPlaying = false;
    }
  }
}
