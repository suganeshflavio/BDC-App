import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/services/api_service.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize environment variables from .env asset
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('DotEnv load notice: $e');
  }

  // Initialize offline persistent preferences
  await StorageService.init();

  // Call /auth/device 1st to ensure token is obtained before other operations
  ApiService().ensureDeviceAuth().catchError((e) {
    debugPrint('App init device auth notice: $e');
    return null;
  });

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
      title: 'BDC Family',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
