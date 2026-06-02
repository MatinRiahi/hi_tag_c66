import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'services/rfid_service.dart';
import 'views/login/login_screen.dart';
import 'views/dashboard/dashboard_screen.dart';
import 'services/beep_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  BeepManager().startMonitoring();

  // 👇 عمودی - برعکس پروژه قبلی
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // RfidService رو یه بار اینجا میسازیم
        // تا همه صفحات بهش دسترسی داشته باشن
        Provider<RfidService>(create: (_) => RfidService()),
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
          // داده رو از arguments بگیر
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
