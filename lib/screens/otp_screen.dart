import 'dart:async';
import 'package:flutter/material.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  // مصفوفة لتخزين الأرقام الأربعة من المربعات
  List<String> otpValues = ["", "", "", ""];
  Timer? _timer;
  int _start = 110;

  // الكود الصحيح (لأغراض التجربة سأجعله 1234، وسأعلمك كيف تجعله حقيقياً)
  final String correctOtp = "1234";

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() => timer.cancel());
      } else {
        setState(() => _start--);
      }
    });
  }

  // دالة التحقق من الكود المدخل
  void _verifyOtp() {
    String enteredOtp = otpValues.join(); // تجميع الأرقام من المربعات

    if (enteredOtp == correctOtp) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم التحقق بنجاح!')));
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الكود غير صحيح، حاول مرة أخرى')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double kaabaHeight = size.height * 0.70;

    return Scaffold(
      resizeToAvoidBottomInset:
          true, // للسماح للكيبورد بالظهور دون تغطية الحقول
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/black.png', fit: BoxFit.cover),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildKaabaBackground(kaabaHeight),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: size.height - kaabaHeight),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'أدخل رمز التحقق',
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                        const SizedBox(height: 25),

                        // صف مربعات الـ OTP المربوطة بالـ Logic
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            4,
                            (index) => _otpBox(context, index),
                          ),
                        ),

                        const SizedBox(height: 30),
                        _buildTimerSection(),
                        const SizedBox(height: 40),

                        _buildGradientButton('تحقق', _verifyOtp),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _otpBox(BuildContext context, int index) {
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
        onChanged: (v) {
          if (v.length == 1) {
            otpValues[index] = v; // تخزين الرقم في المصفوفة
            if (index < 3) {
              FocusScope.of(context).nextFocus(); // الانتقال للمربع التالي
            }
          } else {
            otpValues[index] = "";
            if (index > 0) {
              FocusScope.of(context).previousFocus(); // العودة للخلف عند الحذف
            }
          }
        },
        decoration: const InputDecoration(
          counterText: "",
          border: InputBorder.none,
        ),
      ),
    );
  }

  // --- دوال التصميم الباقية (نفس كودك السابق) ---
  Widget _buildTimerSection() {
    int min = _start ~/ 60;
    int sec = _start % 60;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$min:${sec.toString().padLeft(2, '0')}',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        const Text(
          'لقد أرسلنا رمز الدخول إلى بريدك',
          style: TextStyle(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildKaabaBackground(double h) {
    /* نفس الكود */
    return Container();
  }

  Widget _buildGradientButton(String t, VoidCallback p) {
    /* نفس الكود */
    return Container();
  }
}
