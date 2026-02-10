import 'package:flutter/material.dart';

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

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
            child: _buildKaabaBackground(kaabaHeight),
          ),

          Positioned(
            bottom: kaabaHeight + 19,
            right: 22,
            child: const Text(
              'تأكيد البريد الإلكتروني',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                SizedBox(height: size.height - kaabaHeight),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const SizedBox(height: 40),
                        const Text(
                          'أدخل رمز التحقق',
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                        const SizedBox(height: 25),

                        // صف مربعات الـ OTP
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            4,
                            (index) => _otpBox(context),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // تفاصيل إرسال الرمز والمؤقت
                        _buildTimerSection(),

                        const SizedBox(height: 20),
                        const Text(
                          'لم يصلك الرمز؟ أعد الإرسال',
                          style: TextStyle(color: Colors.white60, fontSize: 13),
                        ),

                        const SizedBox(height: 40),

                        // زر التحقق النهائي
                        _buildGradientButton('تحقق', () {
                          // هنا يتم توجيه المستخدم للصفحة الرئيسية بعد نجاح التحقق
                        }),
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

  // دالة بناء صندوق إدخال رقم واحد
  Widget _otpBox(BuildContext context) {
    return Container(
      height: 65,
      width: 65,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white),
      ),
      child: TextField(
        textAlign: TextAlign.center,
        maxLength: 1,
        keyboardType: TextInputType.number,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        onChanged: (v) =>
            v.length == 1 ? FocusScope.of(context).nextFocus() : null,
        decoration: const InputDecoration(
          counterText: "",
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildTimerSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white38),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            '1:50',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'لقد أرسلنا رمز الدخول إلى بريدك',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            Text(
              'd*****@gmail.com',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // الدوال المساعدة للزر والخلفية (نفسها لضمان ثبات التصميم)
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
