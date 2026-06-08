import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/rfid_service.dart';
import '../../core/constants/app_constants.dart';
import '../../services/beep_manager.dart'; // اضافه شد

class HiCounterViewModel extends ChangeNotifier {
  final RfidService rfidService;
  final BeepManager beepManager; // دسترسی به منیجر گلوبال

  HiCounterViewModel({required this.rfidService, required this.beepManager}) {
    beepManager.addListener(_onBeepManagerUpdate);
  }

  void _onBeepManagerUpdate() {
    notifyListeners();
  }

  // ── State ها ───────────────────────────────────────────────────
  // حالا لیست، میوت و زمان رو مستقیم از BeepManager می‌گیریم که پاک نشن
  List<Map<String, dynamic>> get trustList => beepManager.trustList;
  bool get isMuted => beepManager.isMuted;
  int? get alertTimeInMinutes => beepManager.alertTimeInMinutes;

  Map<String, dynamic>? currentProduct;
  bool isLoading = false;
  String? errorMessage;

  StreamSubscription? _tagSubscription;
  final Set<String> _recentlyProcessed = {};

  // ── شروع اسکن ──────────────────────────
  Future<void> startScanning() async {
    await rfidService.setTagFocus(true);
    await rfidService.startScan();

    _tagSubscription = rfidService.tagStream.listen((tag) {
      final epc = tag['epc'] ?? '';
      if (epc.isNotEmpty) _handleScan(epc);
    });
  }

  // ── توقف اسکن ───────────────────────
  Future<void> stopScanning() async {
    await rfidService.stopScan();
    await rfidService.setTagFocus(false);
    _tagSubscription?.cancel();
    _tagSubscription = null;
  }

  void setAlertTime(int? minutes) {
    beepManager.setAlertTime(minutes);
  }

  // ── هندل کردن تگ اسکن شده ─────────────────────────────────────
  void _handleScan(String rawEpc) {
    final epc = rawEpc.trim().toUpperCase();

    if (_recentlyProcessed.contains(epc)) return;

    // پخش صدای بیپ فلاتری موقع خوندن تگ جدید! (حل ارور ۱۲ جاوا)
    beepManager.playBeep();

    _recentlyProcessed.add(epc);
    Timer(const Duration(milliseconds: 1500), () {
      _recentlyProcessed.remove(epc);
    });

    final existingIndex = trustList.indexWhere(
      (item) => item['epc'].toString().trim().toUpperCase() == epc,
    );

    if (existingIndex != -1) {
      final removed = trustList[existingIndex];
      beepManager.removeItem(existingIndex); // حذف با منیجر

      if (currentProduct != null) {
        final currentEpc = currentProduct!['epc']
            .toString()
            .trim()
            .toUpperCase();
        if (currentEpc == epc) currentProduct = null;
      }

      errorMessage = "کالای ${removed['name']} برگشت داده شد";
      notifyListeners();
    } else {
      fetchProductInfo(rawEpc.trim());
    }
  }

  // ── دریافت اطلاعات محصول از سرور ──────────────────────────────
  Future<void> fetchProductInfo(String epc) async {
    isLoading = true;
    currentProduct = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(AppConstants.getProductByRfidUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'rfid': epc}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['product_info'] != null) {
          final info = data['product_info'];
          currentProduct = {
            'epc': info['rfid'] ?? epc,
            'name': info['name'] ?? 'بدون نام',
            'code': info['code'] ?? '-',
            'weight': info['weight']?.toString() ?? '0',
            'price': info['price']?.toString() ?? '0',
            'stone_price': (info['stone_price'] ?? 0).toDouble() / 10,
            'ojrat': (info['ojrat'] ?? 0).toDouble(),
            'image': info['image'] != null
                ? '${AppConstants.baseUrl}/${info['image']}'
                : '',
            'is_available': info['is_mojod'] == true || info['is_mojod'] == 1,
            // start_time رو موقع افزودن به تراست لیست می‌زنیم
          };
        } else {
          errorMessage = 'اطلاعات محصول یافت نشد';
        }
      } else {
        errorMessage = 'خطای سرور: ${response.statusCode}';
      }
    } catch (e) {
      errorMessage = 'خطای ارتباط: اینترنت خود را بررسی کنید';
    }

    isLoading = false;
    notifyListeners();
  }

  void addToTrust() {
    if (currentProduct == null) return;

    // گرفتن epc کالایی که داره ثبت میشه
    final epc = currentProduct!['epc'].toString().trim().toUpperCase();

    beepManager.addItem(currentProduct!); // افزودن با منیجر

    // 🔥 اضافه کردن به لیست پردازش شده‌ها برای جلوگیری از حذف ناخواسته (۳ ثانیه مهلت)
    _recentlyProcessed.add(epc);
    Timer(const Duration(seconds: 3), () {
      _recentlyProcessed.remove(epc);
    });

    currentProduct = null;
    notifyListeners();
  }

  void removeFromTrust(int index) {
    beepManager.removeItem(index);
  }

  void toggleMute() {
    beepManager.toggleMute();
  }

  void clearCurrentProduct() {
    currentProduct = null;
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    beepManager.removeListener(_onBeepManagerUpdate); // قطع ارتباط با منیجر
    stopScanning(); // ریدر اینجا قطع میشه!
    super.dispose();
  }
}
