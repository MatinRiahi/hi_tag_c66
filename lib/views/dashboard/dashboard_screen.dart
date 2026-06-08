import 'package:flutter/material.dart';
import 'package:hi_tag_c66/views/hi_tab/hi_tab_screen.dart';
import 'package:hi_tag_c66/views/store/store_screen.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../../services/rfid_service.dart';
import '../../views/hi_counter/hi_counter_screen.dart';
import '../../views/profile/profile_screen.dart';
import '../../views/settings/settings_screen.dart';
import '../../viewmodels/hi_tab_viewmodel.dart';
import '../../viewmodels/hi_counter_viewmodel.dart';
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
    // فقط init میکنیم - اسکن نمیکنیم
    final rfidService = context.read<RfidService>();
    rfidService.init();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
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
              _buildAppBar(context, themeProvider),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  // 👇 اینجا فرق اصلیه - GridView به جای Row های دستی
                  child: GridView.count(
                    crossAxisCount: 2, // 👈 2 ستون برای پرتریت
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1, // 👈 نسبت کارت‌ها
                    children: [
                      _buildMenuCard(
                        context: context,
                        title: "HI-COUNTER",
                        imagePath: "assets/images/hi_counter.png",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const HiCounterScreen(), // 👈 ساده و راحت، چون خودش تو فایل خودش Provider داره
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
                          final beepManager = context
                              .read<BeepManager>(); // 👈 اضافه شد

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ChangeNotifierProvider<HiTabViewModel>(
                                    create: (context) => HiTabViewModel(
                                      rfidService: rfidService,
                                      beepManager:
                                          beepManager, // 👈 بهش پاس میدیم
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
                          // 🔥 اینجا دیتای یوزر رو پاس میدیم به صفحه پروفایل
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
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context, ThemeProvider themeProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 12, bottom: 0),
      color: Colors.transparent,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // سوییچ تم
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      themeProvider.isDarkMode ? "حالت تاریک" : "حالت روشن",
                      style: TextStyle(
                        fontFamily: 'Peyda',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      themeProvider.isDarkMode
                          ? Icons.dark_mode
                          : Icons.light_mode,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    Transform.scale(
                      scale: 0.75,
                      child: Switch(
                        value: themeProvider.isDarkMode,
                        activeColor: AppTheme.primaryGold,
                        activeTrackColor: AppTheme.primaryGold.withOpacity(0.5),
                        onChanged: (value) => themeProvider.toggleTheme(value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // عنوان
                Text(
                  "فروشگاه ساروین",
                  style: TextStyle(
                    fontFamily: 'Peyda',
                    fontSize: 20, // 👈 کمی کوچکتر برای 5.5 اینچ
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
              ],
            ),
          ),

          const SizedBox(height: 12),

          // خط طلایی
          Container(
            width: double.infinity,
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppTheme.gradientGoldLight,
                  AppTheme.gradientGoldDark,
                  Colors.transparent,
                ],
                stops: const [0.0, 0.2, 0.8, 1.0],
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
            Image.asset(
              imagePath,
              width: 55, // 👈 کوچکتر برای 5.5 اینچ
              height: 55,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Peyda',
                fontSize: 14, // 👈 کوچکتر
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
