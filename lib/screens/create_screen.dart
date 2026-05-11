import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 🌟 حماية المفاتيح
import 'package:hamaltekk/screens/login_screen.dart';
import 'package:hamaltekk/screens/otp_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  // ==========================================
  // 🌟 دالة إرسال الإيميل (بالأكواد المخفية)
  // ==========================================
  Future<void> sendOtpEmail(String userEmail, String otpCode) async {
    final serviceId = dotenv.env['EMAILJS_SERVICE_ID'] ?? '';
    final templateId = dotenv.env['EMAILJS_TEMPLATE_ID'] ?? '';
    final publicKey = dotenv.env['EMAILJS_PUBLIC_KEY'] ?? '';
    final privateKey = dotenv.env['EMAILJS_PRIVATE_KEY'] ?? '';

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': publicKey,
          'accessToken': privateKey,
          'template_params': {'email': userEmail, 'passcode': otpCode},
        }),
      );

      if (response.statusCode == 200) {
        print('✅ تم إرسال الإيميل بنجاح');
      } else {
        print('❌ فشل الإرسال: ${response.body}');
      }
    } catch (e) {
      print('❌ خطأ في الاتصال بـ EmailJS: $e');
    }
  }

  Future<void> _handleSignUp() async {
    final refNo = idController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (refNo.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackBar('يرجى ملء جميع الحقول');
      return;
    }

    setState(() => isLoading = true);

    try {
      // 1. التحقق من عدم تكرار الحساب بنفس رقم التصريح
      var existingUserCheck = await FirebaseFirestore.instance
          .collection('Users')
          .where('refNo', isEqualTo: refNo)
          .get();

      if (existingUserCheck.docs.isNotEmpty) {
        _showSnackBar('هذا التصريح أو الرقم الوظيفي مسجل مسبقاً في النظام!');
        setState(() => isLoading = false);
        return;
      }

      // 2. التحقق من وجود الرقم في (نسك) أو (الموظفين)
      var nuskDoc = await FirebaseFirestore.instance
          .collection('Nusk')
          .doc(refNo)
          .get();
      var staffDoc = await FirebaseFirestore.instance
          .collection('Staff')
          .doc(refNo)
          .get();

      if (!nuskDoc.exists && !staffDoc.exists) {
        _showSnackBar('رقم التصريح أو الرقم الوظيفي غير موجود');
        setState(() => isLoading = false);
        return;
      }

      String userType = nuskDoc.exists ? 'p' : 's';

      // 3. توليد رمز OTP وإرساله للإيميل
      String generatedOtp = (Random().nextInt(9000) + 1000).toString();
      await sendOtpEmail(email, generatedOtp);

      if (mounted) {
        _showSnackBar('تم إرسال رمز التحقق إلى بريدك الإلكتروني 📩');

        // 4. الانتقال لشاشة الـ OTP وتمرير كل البيانات المطلوبة لإنشاء الحساب لاحقاً
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OtpScreen(
              actualOtp: generatedOtp,
              userType: userType,
              email: email,
              password: password, // 🌟 تمرير الباسورد
              refNo: refNo, // 🌟 تمرير رقم التصريح
            ),
          ),
        );
      }
    } catch (e) {
      _showSnackBar('حدث خطأ غير متوقع: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textAlign: TextAlign.right),
        backgroundColor: const Color(0xFFA07B4F),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double kaabaHeight = size.height * 0.70;

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
              'إنشاء حساب',
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
                SizedBox(height: size.height - kaabaHeight + 20),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      children: [
                        _buildTextField(
                          idController,
                          'رقم التصريح / الوظيفي',
                          false,
                        ),
                        const SizedBox(height: 15),
                        _buildTextField(
                          emailController,
                          'البريد الإلكتروني',
                          false,
                        ),
                        const SizedBox(height: 15),
                        _buildTextField(
                          passwordController,
                          'كلمة المرور',
                          true,
                        ),
                        const SizedBox(height: 30),
                        isLoading
                            ? const CircularProgressIndicator(
                                color: Color(0xFFA07B4F),
                              )
                            : _buildGradientButton('تسجيل', _handleSignUp),
                        const SizedBox(height: 15),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'لديك حساب بالفعل؟ تسجيل دخول',
                            style: TextStyle(
                              color: Colors.white70,
                              fontFamily: 'IBMPlexSans',
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
    TextEditingController controller,
    String hint,
    bool isPassword,
  ) {
    return TextFormField(
      controller: controller,
      textAlign: TextAlign.right,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white, fontFamily: 'IBMPlexSans'),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 20,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 1),
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
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
