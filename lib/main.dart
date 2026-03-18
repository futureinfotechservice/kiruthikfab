import 'package:flutter/material.dart';
import 'package:kiruthikfab/screens/loginpage.dart';

void main() {
  runApp(const MyApp());
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

