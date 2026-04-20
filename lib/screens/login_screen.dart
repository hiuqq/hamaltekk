import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🌟 أضفنا استيراد الفايرستور عشان نقرأ نوع المستخدم
import 'create_screen.dart';
import 'home_screen.dart';
import 'staff_home_screen.dart'; // 🌟 أضفنا استيراد شاشة المشرف

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 1. تعريف المتحكمات لسحب النصوص من الحقول
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // 2. دالة تسجيل الدخول عبر الفايربيس مع التوجيه الذكي
  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى ملء جميع الحقول')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // تسجيل الدخول
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // 🌟 التوجيه الذكي: جلب بيانات المستخدم لمعرفة نوعه (مشرف أم حاج)
      String uid = userCredential.user!.uid;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        String userType =
            userDoc.get('type') ?? 'p'; // نفترض أنه حاج إذا لم نجد الحقل

        if (mounted) {
          if (userType == 's') {
            // توجيه المشرف
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const StaffHomeScreen()),
            );
          } else {
            // توجيه الحاج
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        }
      } else {
        throw Exception('بيانات المستخدم غير موجودة في قاعدة البيانات');
      }
    } on FirebaseAuthException catch (e) {
      String message = 'حدث خطأ ما';
      if (e.code == 'user-not-found')
        message = 'المستخدم غير موجود';
      else if (e.code == 'wrong-password')
        message = 'كلمة المرور خاطئة';

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double kaabaHeight = size.height * 0.70;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/black.png', fit: BoxFit.cover),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: kaabaHeight,
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset('assets/kaaba.png', fit: BoxFit.cover),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.4),
                              Colors.black.withOpacity(0.8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: kaabaHeight + 19,
            right: 22,
            child: const Text(
              'تسجيل الدخول',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontFamily: 'IBMPlexSans',
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                SizedBox(height: size.height - kaabaHeight),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: 30,
                      right: 30,
                      top: 40,
                      bottom: bottomPadding + 20,
                    ),
                    child: Column(
                      children: [
                        _buildTextField(
                          'أدخل بريدك الإلكتروني',
                          false,
                          _emailController,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          'أدخل كلمة المرور',
                          true,
                          _passwordController,
                        ),
                        const SizedBox(height: 40),

                        _isLoading
                            ? const CircularProgressIndicator(
                                color: Color(0xFFA07B4F),
                              )
                            : _buildGradientButton('تسجيل الدخول', _login),

                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignUpScreen(),
                            ),
                          ),
                          child: const Text(
                            'ليس لديك حساب؟ إنشاء حساب',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String hint,
    bool isPassword,
    TextEditingController controller,
  ) {
    return TextFormField(
      controller: controller,
      textAlign: TextAlign.right,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70, fontSize: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFA07B4F), width: 2),
        ),
      ),
    );
  }

  Widget _buildGradientButton(String title, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFA07B4F), Color(0xFF3A2D1D)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        onPressed: onPressed,
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }
}
