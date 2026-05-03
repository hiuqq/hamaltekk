import 'dart:async';
import 'package:flutter/material.dart';

class OtpScreen extends StatefulWidget {
  final String actualOtp;
  final String userType;
  final String email; // 🌟 أضفنا الإيميل عشان نعرضه بالشاشة

  const OtpScreen({
    super.key,
    required this.actualOtp,
    required this.userType,
    required this.email,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  List<String> otpValues = ["", "", "", ""];
  Timer? _timer;
  int _start = 110;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _start = 110;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        timer.cancel();
        setState(() {});
      } else {
        setState(() => _start--);
      }
    });
  }

  void _verifyOtp() {
    String enteredOtp = otpValues.join();

    if (enteredOtp == widget.actualOtp) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم التحقق بنجاح!')));

      if (widget.userType == 's') {
        Navigator.pushReplacementNamed(context, '/staff_main');
      } else {
        Navigator.pushReplacementNamed(context, '/main');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الكود غير صحيح، حاول مرة أخرى')),
      );
    }
  }

  // دالة لتشفير الإيميل (مثال: d*****@gmail.com)
  String _maskEmail(String email) {
    if (!email.contains('@')) return email;
    var parts = email.split('@');
    var name = parts[0];
    if (name.isEmpty) return email;
    return '${name[0]}*****@${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double topSectionHeight = size.height * 0.30;
    final double kaabaHeight = size.height * 0.75;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF1A1A1A), // لون خلفية مقارب للصورة
      body: Stack(
        children: [
          // الخلفية العلوية (ممكن تحطين صورة الباترن هنا إذا متوفرة عندك)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topSectionHeight,
            child: Image.asset(
              'assets/black.png',
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.5), // تخفيف وضوح الخلفية
            ),
          ),

          // عنوان الشاشة العلوي
          Positioned(
            top: topSectionHeight * 0.6,
            left: 0,
            right: 0,
            child: const Center(
              child: Text(
                'تأكيد البريد الإلكتروني',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'IBMPlexSans',
                ),
              ),
            ),
          ),

          // الكارد السفلي اللي فيه الكعبة والبيانات
          Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: kaabaHeight,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(45),
                  topRight: Radius.circular(45),
                ),
                child: Stack(
                  children: [
                    // صورة الكعبة
                    Positioned.fill(
                      child: Image.asset('assets/kaaba.png', fit: BoxFit.cover),
                    ),
                    // التظليل الأسود فوق الكعبة عشان يبرز النص
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.6),
                              Colors.black.withOpacity(0.8),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // المحتوى الداخلي
                    SafeArea(
                      top: false,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 40,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const SizedBox(height: 20),
                            const Text(
                              'أدخل رمز التحقق',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'IBMPlexSans',
                              ),
                            ),
                            const SizedBox(height: 25),

                            // مربعات الـ OTP
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(
                                4,
                                (index) => _otpBox(context, index),
                              ),
                            ),

                            const SizedBox(height: 35),

                            // قسم العداد ومعلومات الإيميل
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTimerBox(), // مربع العداد على اليسار
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'لقد أرسلنا رمز الدخول إلى بريدك',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                        fontFamily: 'IBMPlexSans',
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _maskEmail(widget.email),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'IBMPlexSans',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 15),

                            // زر إعادة الإرسال
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                GestureDetector(
                                  onTap: _start == 0
                                      ? () {
                                          // TODO: استدعاء دالة إرسال الإيميل
                                          _startTimer();
                                        }
                                      : null,
                                  child: Text(
                                    'أعد الإرسال',
                                    style: TextStyle(
                                      color: _start == 0
                                          ? Colors.white
                                          : Colors.white38,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'IBMPlexSans',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  'لم يصلك الرمز؟',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontFamily: 'IBMPlexSans',
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 40),

                            // زر التحقق البني
                            _buildSolidButton('تحقق', _verifyOtp),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _otpBox(BuildContext context, int index) {
    return Container(
      height: 70,
      width: 60,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white54, width: 1),
      ),
      child: TextField(
        textAlign: TextAlign.center,
        maxLength: 1,
        keyboardType: TextInputType.number,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w400,
        ),
        onChanged: (v) {
          otpValues[index] = v;

          if (v.isNotEmpty) {
            if (index < 3) {
              FocusScope.of(context).nextFocus();
            } else {
              FocusScope.of(context).unfocus();
            }
          } else {
            if (index > 0) {
              FocusScope.of(context).previousFocus();
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

  // تصميم مربع العداد مثل الصورة
  Widget _buildTimerBox() {
    int min = _start ~/ 60;
    int sec = _start % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Text(
        '$min:${sec.toString().padLeft(2, '0')}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
          fontFamily: 'IBMPlexSans',
        ),
      ),
    );
  }

  // تصميم الزر بلون بني مطابق للصورة
  Widget _buildSolidButton(String title, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6B4E31), // لون الزر البني
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontFamily: 'IBMPlexSans',
          ),
        ),
      ),
    );
  }
}
