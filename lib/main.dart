import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hamaltekk/screens/logo_screen.dart';
import 'package:hamaltekk/screens/login_screen.dart';
import 'package:hamaltekk/screens/create_screen.dart';
import 'package:hamaltekk/screens/otp_screen.dart';
import 'package:hamaltekk/screens/home_screen.dart';
import 'package:hamaltekk/screens/pilgrim_main_screen.dart';
import 'package:hamaltekk/screens/staff_main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

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
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'IBMPlexSans',
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: const Color(0xFFA07B4F),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFA07B4F),
          primary: const Color(0xFFA07B4F),
          surface: Colors.black,
          brightness: Brightness.dark,
        ),
        cardTheme: CardThemeData(
          color: Colors.black.withOpacity(0.8),
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
        ),
      ),
      home: const LogoScreen(),
      routes: {
        '/main': (context) => const PilgrimMainScreen(),
        '/home': (context) => const HomeScreen(),
        '/logo': (context) => const LogoScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/staff_main': (context) => const StaffMainScreen(),
      },
    );
  }
}
