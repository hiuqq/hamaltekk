import 'package:flutter/material.dart';
// استيراد الشاشات - تأكدي من صحة أسماء الملفات في مجلد screens
import 'package:hamaltekk/screens/logo_screen.dart';
import 'package:hamaltekk/screens/login_screen.dart';
import 'package:hamaltekk/screens/create_screen.dart';
import 'package:hamaltekk/screens/otp_screen.dart';
import 'package:hamaltekk/screens/chat_screen.dart';
import 'package:hamaltekk/screens/home_screen.dart'; // الملف الذي استعدناه

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
      // الثيم المعتمد لتطبيقك (بني وفخم)
      theme: ThemeData(
        fontFamily: 'IBMPlexSans',
        primarySwatch: Colors.brown,
        brightness: Brightness.dark, // لأن أغلب شاشاتك خلفيتها سوداء
      ),

      // 🏠 تعيين الهوم سكرين كشاشة أولى للتجربة
      home: const HomeScreen(),

      routes: {
        '/home': (context) => const HomeScreen(),
        '/logo': (context) => const LogoScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/otp': (context) => const OtpScreen(),
        '/chat': (context) => const CommunicationScreen(),
      },
    );
  }
}
