import 'package:flutter/material.dart';
// استيراد الشاشات
import 'package:hamaltekk/screens/logo_screen.dart';
import 'package:hamaltekk/screens/login_screen.dart';
import 'package:hamaltekk/screens/create_screen.dart';
import 'package:hamaltekk/screens/otp_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hamlatekk',
      theme: ThemeData(fontFamily: 'IBMPlexSans', primarySwatch: Colors.brown),

      // الشاشة الابتدائية عند تشغيل التطبيق
      home: const LogoScreen(),

      routes: {
        '/logo': (context) => const LogoScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/otp': (context) => const OtpScreen(),
      },
    );
  }
}
