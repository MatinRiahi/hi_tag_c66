import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 👈 برای SystemNavigator.pop()
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
// import '../../core/theme/theme_provider.dart'; // دیگه اینجا نیازی نیست
import '../../services/rfid_service.dart';
import '../../views/hi_counter/hi_counter_screen.dart';
import '../../views/hi_tab/hi_tab_screen.dart';
import '../../views/store/store_screen.dart';
import '../../views/profile/profile_screen.dart';
import '../../views/settings/settings_screen.dart';
import '../../viewmodels/hi_tab_viewmodel.dart';
import '../../services/beep_manager.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const DashboardScreen({super.key, required this.userData});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rfidService = context.read<RfidService>();
      rfidService.init();
    });
  }

  // ── تابع نمایش پیام تایید خروج ──────────────────────────────────
  Future<bool?> _showExitDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          'خروج از برنامه',
          style: TextStyle(
            fontFamily: 'Peyda',
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: const Text(
          'آیا مطمئن هستید که می‌خواهید از برنامه خارج شوید؟',
          style: TextStyle(fontFamily: 'Peyda', fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'خیر',
              style: TextStyle(fontFamily: 'Peyda', color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'بله، خارج شو',
              style: TextStyle(fontFamily: 'Peyda', color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldExit = await _showExitDialog();
        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Container(
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
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.1,
                      children: [
                        _buildMenuCard(
                          context: context,
                          title: "HI-COUNTER",
                          imagePath: "assets/images/hi_counter.png",
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HiCounterScreen(),
                            ),
                          ),
                        ),
                        _buildMenuCard(
                          context: context,
                          title: "HI-STORE",
                          imagePath: "assets/images/hi_store.png",
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const StoreScreen(),
                            ),
                          ),
                        ),
                        _buildMenuCard(
                          context: context,
                          title: "HI-TAB",
                          imagePath: "assets/images/hi_tab.png",
                          onTap: () {
                            final rfidService = context.read<RfidService>();
                            final beepManager = context.read<BeepManager>();

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ChangeNotifierProvider<HiTabViewModel>(
                                      create: (context) => HiTabViewModel(
                                        rfidService: rfidService,
                                        beepManager: beepManager,
                                      ),
                                      child: const HiTabScreen(),
                                    ),
                              ),
                            );
                          },
                        ),
                        _buildMenuCard(
                          context: context,
                          title: "پروفایل",
                          imagePath: "assets/images/profile.png",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProfileScreen(data: widget.userData),
                              ),
                            );
                          },
                        ),
                        _buildMenuCard(
                          context: context,
                          title: "تنظیمات",
                          imagePath: "assets/images/settings.png",
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          ),
                        ),
                        _buildMenuCard(
                          context: context,
                          title: "درباره ما",
                          imagePath: "assets/images/about.png",
                          onTap: () {
                            // TODO
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── AppBar ویرایش شده ───────────────────────────────────────────
  Widget _buildAppBar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(
        top: 24,
        bottom: 0,
      ), // پدینگ بالا رو یه کم بیشتر کردم جای دکمه که رفت
      color: Colors.transparent,
      child: Column(
        children: [
          Image.asset(
            'assets/images/logo.png', // همون مسیر لوگویی که تو لاگین استفاده کردی
            height: 70, // سایزش رو بسته به سلیقه‌ت میتونی تغییر بدی
          ),
          const SizedBox(height: 8),
          Text(
            "فروشگاه ساروین",
            style: TextStyle(
              fontFamily: 'Peyda',
              fontSize: 16, // فونت رو یه نمه بزرگتر کردم که وسط قشنگ بشینه
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
              shadows: const [
                Shadow(
                  color: Colors.black,
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16), // فاصله تا خطوط پایین
          Container(
            width: double.infinity,
            height: 3,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Colors.transparent, // شروع کاملاً شفاف از سمت چپ
                  AppTheme.gradientGoldLight, // کم‌رنگ می‌شه
                  AppTheme.gradientGoldDark, // دقیقاً وسط خط پررنگ‌ترین حالت
                  AppTheme.gradientGoldLight, // دوباره کم‌رنگ می‌شه
                  Colors.transparent, // پایان کاملاً شفاف در سمت راست
                ],
                // تنظیم محل قرارگیری رنگ‌ها برای نرم شدن شیب رنگ
                stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGold.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── کارت منو ────────────────────────────────────────────────────
  Widget _buildMenuCard({
    required BuildContext context,
    required String title,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imagePath, width: 55, height: 55, fit: BoxFit.contain),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Peyda',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
