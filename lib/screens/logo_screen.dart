import 'dart:async';
import 'package:flutter/material.dart';

class LogoScreen extends StatefulWidget {
  const LogoScreen({super.key});

  @override
  State<LogoScreen> createState() => _LogoScreenState();
}

class _LogoScreenState extends State<LogoScreen> {
  @override
  void initState() {
    super.initState();
    // المؤقت للانتقال لصفحة تسجيل الدخول بعد 3 ثوانٍ
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. الخلفية
          Positioned.fill(
            child: Image.asset('assets/black.png', fit: BoxFit.cover),
          ),
          // 2. المحتوى في المنتصف
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // تغليف الصورة بـ Opacity للتحكم في الشفافية
                Opacity(
                  opacity: 0.63, // هنا وضعنا نسبة الشفافية 63%
                  child: Image.asset('assets/logo.png', width: 220),
                ),
                const SizedBox(height: 20),
                // النص أسفل الشعار
                const Text(
                  'H A M L A T E K',
                  style: TextStyle(
                    color: Color(0xFFA07B4F),
                    fontSize: 18,
                    letterSpacing: 5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
