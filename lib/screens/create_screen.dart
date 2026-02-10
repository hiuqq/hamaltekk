import 'package:flutter/material.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double kaabaHeight = size.height * 0.70;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // خلفية التطبيق
          Positioned.fill(
            child: Image.asset('assets/black.png', fit: BoxFit.cover),
          ),

          // منطقة الكعبة المنحنية
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildKaabaBackground(kaabaHeight),
          ),

          // العنوان
          Positioned(
            bottom: kaabaHeight + 19,
            right: 22,
            child: const Text(
              'إنشاء حساب',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // المحتوى والحقول
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
                          'أدخل رقم تصريح الحج / الرقم الوظيفي',
                          false,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField('أدخل بريدك الإلكتروني', false),
                        const SizedBox(height: 20),
                        _buildTextField('أدخل كلمة المرور', true),
                        const SizedBox(height: 40),

                        // زر إنشاء الحساب مع خاصية التنقل لصفحة الـ OTP
                        _buildGradientButton('أنشاء الحساب', () {
                          // الانتقال لصفحة الرمز باستخدام الاسم المعرف في الماين
                          Navigator.pushNamed(context, '/otp');
                        }),

                        const SizedBox(height: 20),

                        // العودة لتسجيل الدخول
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            'هل لديك حساب؟ تسجيل الدخول',
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

  // دوال مساعدة للتصميم (Widgets) لتقليل تكرار الكود
  Widget _buildKaabaBackground(double height) {
    return Container(
      height: height,
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
    );
  }

  Widget _buildTextField(String hint, bool isPassword) {
    return TextFormField(
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
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
