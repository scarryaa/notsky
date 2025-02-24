import 'package:flutter/material.dart';
import 'package:notsky/features/auth/pages/login_page.dart';

void main() {
  runApp(const NotSkyApp());
}

class NotSkyApp extends StatelessWidget {
  const NotSkyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'notsky',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const LoginPage(),
    );
  }
}
