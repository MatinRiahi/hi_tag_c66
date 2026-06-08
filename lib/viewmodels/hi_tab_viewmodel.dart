import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/rfid_service.dart';
import '../../core/constants/app_constants.dart';
import '../../services/beep_manager.dart';

class HiTabViewModel extends ChangeNotifier {
  final RfidService rfidService;
  final BeepManager beepManager; // ✅ مساوی برداشته شد

  // ✅ از ورودی دریافت میکنه
  HiTabViewModel({required this.rfidService, required this.beepManager});

  List<Map<String, dynamic>> invoiceList = [];
  bool isLoading = false;
  String? errorMessage;
  String? successMessage;

  StreamSubscription? _tagSubscription;
  final Set<String> _recentlyProcessed = {};

  void initList(List<Map<String, dynamic>>? savedList) {
    if (savedList != null && savedList.isNotEmpty) {
      invoiceList.addAll(savedList);
      notifyListeners();
    }
  }

  Future<void> startScanning() async {
    await rfidService.setTagFocus(true);
    await rfidService.startScan();

    _tagSubscription = rfidService.tagStream.listen((tag) {
      final epc = tag['epc'] ?? '';
      if (epc.isNotEmpty) handleScan(epc);
    });
  }

  Future<void> stopScanning() async {
    await rfidService.stopScan();
    await rfidService.setTagFocus(false);
    _tagSubscription?.cancel();
    _tagSubscription = null;
  }

  void handleScan(String rawEpc) {
    final epc = rawEpc.trim().toUpperCase();

    if (_recentlyProcessed.contains(epc)) return;

    beepManager.playBeep(); // ✅ صدا از منیجر اصلی پخش میشه

    _recentlyProcessed.add(epc);
    Timer(const Duration(milliseconds: 2000), () {
      _recentlyProcessed.remove(epc);
    });

    final existingIndex = invoiceList.indexWhere(
      (item) => item['epc'].toString().trim().toUpperCase() == epc,
    );

    if (existingIndex != -1) {
      errorMessage = "این کالا قبلاً در لیست فاکتور وجود دارد";
      notifyListeners();
    } else {
      fetchAndAddProduct(epc);
    }
  }

  Future<void> fetchAndAddProduct(String epc) async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/get_info_with_RFID/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'rfid': epc}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        if (data['product_info'] != null) {
          final info = data['product_info'];
          bool isAvailable = info['is_mojod'] == true || info['is_mojod'] == 1;

          if (!isAvailable) {
            errorMessage =
                "کالای '${info['name'] ?? 'شناسایی شده'}' ناموجود است!";
          } else {
            final newProduct = {
              'epc': info['rfid'] ?? epc,
              'name': info['name'] ?? 'بدون نام',
              'code': info['code'] ?? '-',
              'weight': info['weight']?.toString() ?? '0',
              'price': info['price']?.toString() ?? '0',
              'ojrat': info['ojrat']?.toString() ?? '0',
              'image': info['image'] != null
                  ? '${AppConstants.baseUrl}/${info['image']}'
                  : '',
              'is_available': isAvailable,
            };

            invoiceList.add(newProduct);
            successMessage = "کالای ${newProduct['name']} اضافه شد";
          }
        } else {
          errorMessage = 'اطلاعات محصول یافت نشد';
        }
      } else {
        errorMessage = 'خطای سرور: ${response.statusCode}';
      }
    } catch (e) {
      errorMessage = 'خطای ارتباط با سرور';
    }

    isLoading = false;
    notifyListeners();
  }

  void removeFromInvoice(int index) {
    invoiceList.removeAt(index);
    notifyListeners();
  }

  void clearAllItems() {
    invoiceList.clear();
    notifyListeners();
  }

  void clearMessages() {
    errorMessage = null;
    successMessage = null;
  }

  @override
  void dispose() {
    stopScanning();
    super.dispose();
  }
}
