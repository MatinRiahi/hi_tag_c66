import 'package:flutter/material.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
// import '../../core/constants/app_constants.dart';
import '../../core/constants/mock_data.dart';

class LoginViewModel extends ChangeNotifier {
  // ── State ها ──────────────────────────────────────────────────
  bool isLoading = false;
  bool isPasswordVisible = false;
  String deviceId = 'در حال دریافت...';
  String? errorMessage;
  Map<String, dynamic>? userData; // بعد از لاگین موفق پر میشه

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  // ── Constructor ───────────────────────────────────────────────
  LoginViewModel() {
    _getDeviceIdentifier();
  }

  // ── توابع ─────────────────────────────────────────────────────
  void togglePasswordVisibility() {
    isPasswordVisible = !isPasswordVisible;
    notifyListeners();
  }

  Future<void> _getDeviceIdentifier() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    String? identifier;

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        identifier = androidInfo.fingerprint;
      }
    } catch (e) {
      identifier = 'خطا در دریافت شناسه';
    }

    deviceId = identifier ?? 'شناسه یافت نشد';
    notifyListeners();
  }

  Future<void> login() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    // ✅ Mock Login - فقط چک کن با داده ثابت
    if (username == MockData.mockUsername &&
        password == MockData.mockPassword) {
      userData = MockData.mockUserData;
    } else {
      errorMessage = 'نام کاربری یا رمز عبور اشتباه است';
    }

    isLoading = false;
    notifyListeners();
  }

  // Future<void> login() async {
  //   isLoading = true;
  //   errorMessage = null;
  //   notifyListeners();

  //   final url = Uri.parse(AppConstants.loginUrl);

  //   try {
  //     final response = await http.post(
  //       url,
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode({
  //         "username": usernameController.text.trim(),
  //         "password": passwordController.text.trim(),
  //         "device_id": deviceId,
  //       }),
  //     );

  //     Map<String, dynamic> responseData = {};
  //     try {
  //       responseData = jsonDecode(utf8.decode(response.bodyBytes));
  //     } catch (_) {}

  //     if (response.statusCode == 200 && responseData['status'] == 'ok') {
  //       userData = responseData; // ✅ لاگین موفق
  //     } else {
  //       errorMessage = responseData['error'] ?? 'خطا در برقراری ارتباط با سرور';
  //     }
  //   } catch (e) {
  //     errorMessage = 'خطا در اتصال: اینترنت خود را بررسی کنید.';
  //   }

  //   isLoading = false;
  //   notifyListeners();
  // }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
