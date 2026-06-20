import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

// 🔥 ایمپورت‌های مربوط به پروایدر و تم اضافه شد
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';

// 👇 مسیر این دو تا رو چک کن که درست باشه
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _profitController = TextEditingController();
  final TextEditingController _taxController = TextEditingController();
  final TextEditingController _gemProfitController = TextEditingController();
  final TextEditingController _jewelryProfitController =
      TextEditingController();

  bool _calculatePriceWithStone = false;
  bool _calculateStoneWithTaxAndProfit = false;
  bool _isLoading = true; // برای نمایش لودینگ اولیه

  late String _getFinanceUrl;
  late String _setFinanceUrl;

  @override
  void initState() {
    super.initState();
    // 🔥 استفاده از baseUrl داینامیک که موقع لاگین ذخیره کردیم
    final String baseUrl = AppConstants.baseUrl;
    _getFinanceUrl = "$baseUrl/get_Finance_Settings/";
    _setFinanceUrl = "$baseUrl/set_Finance_Settings/";

    _fetchFinanceSettings();
  }

  Future<void> _fetchFinanceSettings() async {
    try {
      final response = await http.post(
        Uri.parse(_getFinanceUrl),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final financeSettings = data['Finance_setting'];

        setState(() {
          _profitController.text = financeSettings['profit_percent'].toString();
          _taxController.text = financeSettings['vat_percent'].toString();
          _gemProfitController.text = financeSettings['stone_percent']
              .toString();
          _jewelryProfitController.text = financeSettings['ojrat_percent']
              .toString();
          _calculatePriceWithStone =
              financeSettings['gold_price_with_stone'] == true ||
              financeSettings['gold_price_with_stone'] == 1;
          _calculateStoneWithTaxAndProfit =
              financeSettings['stone_price_without_vat_profit'] == true ||
              financeSettings['stone_price_without_vat_profit'] == 1;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showErrorDialog(
          "خطا در دریافت تنظیمات. کد خطا: ${response.statusCode}",
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog("خطا در اتصال به سرور. اینترنت را بررسی کنید.");
    }
  }

  Future<void> _saveFinanceSettings() async {
    try {
      final Map<String, dynamic> requestBody = {
        "vat_percent": _taxController.text,
        "profit_percent": _profitController.text,
        "ojrat_percent": _jewelryProfitController.text,
        "stone_percent": _gemProfitController.text,
        "gold_price_with_stone": _calculatePriceWithStone ? "1" : "0",
        "stone_price_without_vat_profit": _calculateStoneWithTaxAndProfit
            ? "1"
            : "0",
      };

      final response = await http.post(
        Uri.parse(_setFinanceUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'ok') {
          _showSuccessDialog("تنظیمات با موفقیت ذخیره شد.");
        } else {
          _showErrorDialog("خطا در ذخیره تنظیمات.");
        }
      } else {
        _showErrorDialog(
          "خطا در ذخیره تنظیمات. کد خطا: ${response.statusCode}",
        );
      }
    } catch (e) {
      _showErrorDialog("خطا در اتصال به سرور: $e");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl, // 👈 راست‌چین کردن دیالوگ
        child: AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent),
              const SizedBox(width: 8),
              Text(
                "خطا",
                style: TextStyle(
                  fontFamily: 'Peyda',
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(
              fontFamily: 'Peyda',
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "باشه",
                style: TextStyle(fontFamily: 'Peyda', color: Colors.redAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl, // 👈 راست‌چین کردن دیالوگ
        child: AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                "موفقیت",
                style: TextStyle(
                  fontFamily: 'Peyda',
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(
              fontFamily: 'Peyda',
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "باشه",
                style: TextStyle(
                  fontFamily: 'Peyda',
                  color: AppTheme.primaryGold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // 🔥 فراخوانی themeProvider
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).scaffoldBackgroundColor,
                Theme.of(context).colorScheme.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: size.width * 0.95,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- هدر کارت ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 32),
                          Text(
                            "تنظیمات", // 👈 عنوان کلی‌تر شد
                            style: TextStyle(
                              fontFamily: 'Peyda',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(50),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // --- خطوط جداکننده طلایی ---
                      Container(
                        height: 2,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppTheme.primaryGold,
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 1,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Color.fromARGB(205, 177, 117, 64),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // --- در حال بارگذاری یا فرم ---
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryGold,
                          ),
                        )
                      else ...[
                        // --- لیست ورودی‌ها ---
                        _buildInlineInput("درصد مالیات:", _taxController),
                        const SizedBox(height: 8),
                        _buildInlineInput("درصد سود ساده:", _profitController),
                        const SizedBox(height: 8),
                        _buildInlineInput(
                          "درصد سود سنگ‌دار:",
                          _gemProfitController,
                        ),
                        const SizedBox(height: 8),
                        _buildInlineInput(
                          "درصد سود جواهر:",
                          _jewelryProfitController,
                        ),
                        const SizedBox(height: 8),

                        _buildSwitchInput(
                          "محاسبه قیمت طلا با سنگ",
                          _calculatePriceWithStone,
                          (val) {
                            setState(() => _calculatePriceWithStone = val);
                          },
                        ),
                        const SizedBox(height: 8),

                        _buildSwitchInput(
                          "محاسبه سنگ با مالیات و سود",
                          _calculateStoneWithTaxAndProfit,
                          (val) {
                            setState(
                              () => _calculateStoneWithTaxAndProfit = val,
                            );
                          },
                        ),

                        const SizedBox(height: 8),

                        // 🔥 این همونیه که اضافه شد: تنظیمات تم
                        _buildThemeSwitch(context, themeProvider),

                        const SizedBox(height: 20),

                        // --- دکمه ذخیره ---
                        Container(
                          width: double.infinity,
                          height: 45,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppTheme.gradientGoldLight,
                                AppTheme.gradientGoldDark,
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryGold.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _saveFinanceSettings,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "ذخیره تغییرات",
                              style: TextStyle(
                                fontFamily: 'Peyda',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🔥 ویجت ساخته شده مخصوص سوییچ تم که هم‌شکل با بقیه آیتم‌هاست
  Widget _buildThemeSwitch(BuildContext context, ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        textDirection: TextDirection.rtl,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                size: 18,
                color: themeProvider.isDarkMode
                    ? Colors.white70
                    : Colors.black87,
              ),
              const SizedBox(width: 6),
              Text(
                "حالت تاریک اپلیکیشن",
                style: TextStyle(
                  fontFamily: 'Peyda',
                  fontSize: 13,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ],
          ),
          Transform.scale(
            scale: 0.75,
            child: CupertinoSwitch(
              value: themeProvider.isDarkMode,
              onChanged: (value) => themeProvider.toggleTheme(value),
              activeColor: AppTheme.primaryGold,
              trackColor: Theme.of(
                context,
              ).colorScheme.onSurface.withOpacity(0.24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchInput(String label, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Peyda',
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
          Transform.scale(
            scale: 0.75,
            child: CupertinoSwitch(
              value: value,
              onChanged: onChanged,
              activeColor: AppTheme.primaryGold,
              trackColor: Theme.of(
                context,
              ).colorScheme.onSurface.withOpacity(0.24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineInput(String label, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        textDirection: TextDirection.rtl,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Peyda',
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          SizedBox(
            width: 70,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Peyda',
                color: AppTheme.primaryGold,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: "0",
                hintStyle: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.24),
                ),
                suffixText: "%",
                suffixStyle: TextStyle(
                  fontFamily: 'Peyda',
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.38),
                  fontSize: 12,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
