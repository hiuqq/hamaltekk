import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // مكتبة Firebase الأساسية
import 'firebase_options.dart'; // الملف الذي تم توليده بواسطة FlutterFire CLI

// استيراد الشاشات
import 'package:hamaltekk/screens/logo_screen.dart';
import 'package:hamaltekk/screens/login_screen.dart';
import 'package:hamaltekk/screens/create_screen.dart';
import 'package:hamaltekk/screens/otp_screen.dart';
import 'package:hamaltekk/screens/home_screen.dart';
import 'package:hamaltekk/screens/pilgrim_main_screen.dart'; // 🌟 إضافة استيراد الشاشة الحاضنة الجديدة

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

        // إعدادات الكروت (Cards)
        cardTheme: CardThemeData(
          color: Colors.black.withOpacity(0.8),
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
        ),
      ),

      // 🏁 التعديل الجوهري: جعل PilgrimMainScreen هي نقطة الانطلاق لظهور البار السفلي
      // يمكنك إعادتها إلى LogoScreen() لاحقاً إذا كنت تريد عرض اللوقو أولاً ثم الانتقال برمجياً
      home: const LogoScreen(),

      // تعريف المسارات (Routes) للتنقل بين الشاشات
      routes: {
        '/main': (context) => const PilgrimMainScreen(), // مسار الشاشة الحاضنة
        '/home': (context) => const HomeScreen(),
        '/logo': (context) => const LogoScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),

        // 🌟 تم إزالة مسار '/otp' من هنا؛ لأن شاشة التحقق تحتاج بيانات ديناميكية (كود التحقق والإيميل)
        // وتمت معالجة الانتقال لها برمجياً من داخل شاشة التسجيل
      },
    );
  }
}
