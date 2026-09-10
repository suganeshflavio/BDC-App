import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize offline persistent preferences
  await StorageService.init();

  // System UI Overlay styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF201E38),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const ParamaninKeethangalApp());
}

class ParamaninKeethangalApp extends StatelessWidget {
  const ParamaninKeethangalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'பரமனின் கீதங்கள் - Paramanin Keethangal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
