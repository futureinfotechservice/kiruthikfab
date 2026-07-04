import 'package:flutter/material.dart';
import 'package:kiruthikfab/screens/loginpage.dart';
import 'package:kiruthikfab/screens/navigation_provider.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => NavigationProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kiruthik Fab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4318D1)),
        useMaterial3: true,
      ),
      // home: const CustomerManagementApp(),
      home: const LoginScreen(),
    );
  }
}
