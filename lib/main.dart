import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(ChangeNotifierProvider(
    create: (_) => AppProvider(),
    child: const SmartCityApp(),
  ));
}

class SmartCityApp extends StatelessWidget {
  const SmartCityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مدينتي الذكية',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      home: Consumer<AppProvider>(
        builder: (_, app, __) =>
            app.loggedIn ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }
}
