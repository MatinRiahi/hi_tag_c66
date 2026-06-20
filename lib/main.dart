import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'services/rfid_service.dart';
import 'views/login/login_screen.dart';
import 'views/dashboard/dashboard_screen.dart';
import 'services/beep_manager.dart';

// 🔥 ۱. ساخت سرویس‌ها به صورت سراسری (Global) قبل از هر چیزی
final rfidService = RfidService();
final beepManager = BeepManager();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 🔥 ۲. روشن کردن موتور سخت‌افزارها همینجا در امن‌ترین جای ممکن
  // اینجا فقط آماده‌سازی میشن، اسکن نمیکنن!
  rfidService.init();
  beepManager.startMonitoring();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // 🔥 ۳. به جای create، از value استفاده میکنیم
        // این یعنی "خودت نساز، من ساختمش بیا از همین استفاده کن"
        Provider<RfidService>.value(value: rfidService),
        ChangeNotifierProvider<BeepManager>.value(value: beepManager),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hi Tag C66',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const SafeArea(child: LoginScreen()),

      routes: {
        '/dashboard': (context) {
          final userData =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>? ??
              {};
          return DashboardScreen(userData: userData);
        },
      },
    );
  }
}
