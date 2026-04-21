import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // مكتبة Firebase الأساسية
import 'firebase_options.dart'; // الملف الذي تم توليده بواسطة FlutterFire CLI

// استيراد الشاشات - تأكد من مطابقة الأسماء للملفات الموجودة في مجلد screens
import 'package:hamaltekk/screens/logo_screen.dart';
import 'package:hamaltekk/screens/login_screen.dart';
import 'package:hamaltekk/screens/create_screen.dart';
import 'package:hamaltekk/screens/otp_screen.dart';
import 'package:hamaltekk/screens/chat_screen.dart';
import 'package:hamaltekk/screens/home_screen.dart';

void main() async {
  // 1. التأكد من تهيئة روابط Flutter قبل أي شيء
  WidgetsFlutterBinding.ensureInitialized();

  // 2. تهيئة Firebase باستخدام الإعدادات الخاصة بمشروعك
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hamlatekk',

      // تطبيق الهوية البصرية الفخمة (الأسود والذهبي/النحاسي)
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'IBMPlexSans',
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,

        // اللون النحاسي المعتمد للهوية
        primaryColor: const Color(0xFFA07B4F),

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFA07B4F),
          primary: const Color(0xFFA07B4F),
          surface: Colors.black,
          brightness: Brightness.dark,
        ),

        // التصحيح النهائي: استخدام CardThemeData لحل خطأ argument_type_not_assignable
        cardTheme: CardThemeData(
          color: Colors.black.withOpacity(0.8),
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
        ),
      ),

      // 🏁 أول شاشة تظهر عند تشغيل التطبيق (اللوقو)
      home: const LogoScreen(),

      // تعريف المسارات (Routes) للتنقل بين الشاشات
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
