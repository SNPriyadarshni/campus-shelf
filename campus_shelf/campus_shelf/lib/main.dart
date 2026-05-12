import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Note: Add any initialization for ApiService or secure storage here if needed
  
  runApp(const CampusShelfApp());
}

class CampusShelfApp extends StatelessWidget {
  const CampusShelfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const LoginPage(),
    );
  }
}
