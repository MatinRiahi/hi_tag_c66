import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../viewmodels/login_viewmodel.dart';
import '../../views/dashboard/dashboard_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginViewModel(),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatelessWidget {
  const _LoginView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LoginViewModel>();

    // 🔥 بررسی وضعیت تم (دارک یا لایت)
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (vm.userData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DashboardScreen(userData: vm.userData!),
          ),
        );
      });
    }

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          // 🔥 تنظیم گرادیانت پس‌زمینه
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDarkMode
                  ? [AppTheme.navyBackgroundLight, AppTheme.navyBackgroundDark]
                  : [
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
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  // 🔥 استایل دادن به کارت وسط
                  decoration: BoxDecoration(
                    // اگر دارک بود از surface سرمه‌ای روشن‌تر با شفافیت استفاده می‌کنه
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withOpacity(isDarkMode ? 0.65 : 0.8),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      // یه بردر خیلی محو سفید برای حالت دارک میذاریم که کارت رو شیک‌تر کنه
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.15)
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(
                          isDarkMode ? 0.5 : 0.2,
                        ), // سایه تو دارک کمی قوی‌تره
                        blurRadius: 20,
                        spreadRadius:
                            3, // اسپرد رو یکم کمتر کردم که کارت برجسته‌تر دیده بشه
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // لوگو
                      Image.asset('assets/images/logo.png', height: 80),
                      const SizedBox(height: 16),

                      Text(
                        'لطفا وارد حساب کاربری خود شوید',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // فیلد نام کاربری
                      _buildTextField(
                        context: context,
                        controller: vm.usernameController,
                        hint: 'نام کاربری',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),

                      // فیلد رمز عبور
                      _buildTextField(
                        context: context,
                        controller: vm.passwordController,
                        hint: 'رمز عبور',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        isPasswordVisible: vm.isPasswordVisible,
                        onTogglePassword: vm.togglePasswordVisibility,
                      ),
                      const SizedBox(height: 24),

                      // نمایش خطا
                      if (vm.errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            vm.errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // دکمه ورود
                      Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppTheme.gradientGoldLight,
                              AppTheme.gradientGoldDark,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          // یه سایه کم جون طلایی به دکمه اضافه کردم قشنگ‌تر شه
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryGold.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: vm.isLoading ? null : vm.login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: vm.isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'ورود',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                        ),
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

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onTogglePassword,
  }) {
    // گرفتن وضعیت تم برای فیلدها هم مفیده
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: controller,
      obscureText: isPassword && !isPasswordVisible,
      decoration: InputDecoration(
        prefixIcon: Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
                onPressed: onTogglePassword,
              )
            : null,
        hintText: hint,
        hintStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
        ),
        filled: true,
        // تو تم دارک بک‌گراند فیلدها یکم تیره‌تر بشه تا با کارت روشن‌تر کنتراست بسازه
        fillColor: Theme.of(
          context,
        ).colorScheme.surface.withOpacity(isDarkMode ? 0.3 : 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
