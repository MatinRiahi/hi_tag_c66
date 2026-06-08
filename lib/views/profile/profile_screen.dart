import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart'; // مسیر AppTheme خودت رو چک کن

class ProfileScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const ProfileScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final userInfo = data['user_info'] ?? {};
    final remainingDays = data['remaining_days'] ?? 0;

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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ), // پدینگ کمتر برای 5.5 اینچ
                child: Container(
                  width: size.width * 0.95, // استفاده حداکثری از عرض موبایل
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20), // کمی گردی کمتر
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- هدر ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 32),
                          Text(
                            "پروفایل کاربری",
                            style: TextStyle(
                              fontFamily: 'Peyda',
                              fontSize: 18, // کمی سایز فونت رو متناسب کردم
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
                      const SizedBox(height: 12),

                      // --- خطوط طلایی ---
                      Container(
                        height: 2,
                        decoration: BoxDecoration(
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

                      const SizedBox(height: 20),

                      // --- باکس روزهای باقیمانده ---
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryGold.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.timer,
                              color: AppTheme.primaryGold,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "$remainingDays روز باقی‌مانده از اشتراک",
                              style: const TextStyle(
                                fontFamily: 'Peyda',
                                color: AppTheme.primaryGold,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // --- اطلاعات کاربر ---
                      _buildInfoRow(
                        context,
                        "نام و نام خانوادگی",
                        userInfo['name']?.toString() ?? '-',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        context,
                        "نام فروشگاه",
                        userInfo['store_name']?.toString() ?? '-',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        context,
                        "نام کاربری",
                        userInfo['username']?.toString() ?? '-',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        context,
                        "شماره تماس",
                        userInfo['phone_number']?.toString() ?? '-',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        context,
                        "شهر",
                        userInfo['city']?.toString() ?? '-',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        context,
                        "تاریخ انقضا",
                        userInfo['expire_date']?.toString() ?? '-',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        context,
                        "آدرس سرور",
                        userInfo['url']?.toString() ?? '-',
                      ),
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

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ), // بهینه برای 5.5 اینچ
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
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign:
                  TextAlign.left, // برای اینکه متن‌های طولانی به هم نریزه
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Peyda',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
