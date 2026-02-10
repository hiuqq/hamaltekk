import 'package:flutter/material.dart';
// استيراد الملف الثاني لكي يتعرف الكود على صفحة الإنشاء عند الانتقال
import 'create_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // الحصول على أبعاد الشاشة (الطول والعرض) لجعل التصميم متجاوباً
    final size = MediaQuery.of(context).size;

    // تحديد ارتفاع منطقة الكعبة بـ 70% من إجمالي طول الشاشة
    final double kaabaHeight = size.height * 0.70;

    // حساب مسافة لوحة المفاتيح عند ظهورها لمنع تغطية العناصر المهمة
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      // تعطيل إعادة التحجيم التلقائي لتجنب انضغاط الخلفية عند فتح الكيبورد
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. الخلفية المزخرفة (الطبقة السفلى تماماً)
          Positioned.fill(
            child: Image.asset('assets/black.png', fit: BoxFit.cover),
          ),

          // 2. حاوية الكعبة والتأثيرات البصرية عليها
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: kaabaHeight,
              width: double.infinity,
              decoration: const BoxDecoration(
                // عمل انحناء علوي للحاوية بمقدار 40 بكسل
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: ClipRRect(
                // قص صورة الكعبة بنفس مقدار انحناء الحاوية
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                child: Stack(
                  children: [
                    // عرض صورة الكعبة لتغطي المساحة المخصصة
                    Positioned.fill(
                      child: Image.asset('assets/kaaba.png', fit: BoxFit.cover),
                    ),
                    // إضافة طبقة تدرج لوني (Gradient) فوق الصورة لتسهيل قراءة النصوص
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(
                                0.4,
                              ), // شفافية خفيفة في الأعلى
                              Colors.black.withOpacity(
                                0.8,
                              ), // قتامة في الأسفل لبروز الأزرار
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

          // 3. العنوان (نص تسجيل الدخول)
          Positioned(
            // تحديد الموقع بدقة: فوق منطقة الكعبة بـ 19 بكسل ومن اليمين بـ 22 بكسل
            bottom: kaabaHeight + 19,
            right: 22,
            child: const Text(
              'تسجيل الدخول',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontFamily: 'IBMPlexSans', // استخدام الخط الذي قمنا بتركيبه
              ),
            ),
          ),

          // 4. منطقة المحتوى (الحقول والأزرار)
          SafeArea(
            child: Column(
              children: [
                // دفع المحتوى للأسفل ليبدأ من فوق منطقة الكعبة مباشرة
                SizedBox(height: size.height - kaabaHeight),
                Expanded(
                  child: SingleChildScrollView(
                    // إضافة مسافات داخلية للمحتوى لضمان عدم التصاقه بالحواف
                    padding: EdgeInsets.only(
                      left: 30,
                      right: 30,
                      top: 40,
                      bottom: bottomPadding + 20,
                    ),
                    child: Column(
                      children: [
                        // استدعاء دالة بناء الحقل للبريد الإلكتروني
                        _buildTextField('أدخل بريدك الإلكتروني', false),
                        const SizedBox(height: 20),
                        // استدعاء دالة بناء الحقل لكلمة المرور (مع تفعيل إخفاء النص)
                        _buildTextField('أدخل كلمة المرور', true),
                        const SizedBox(height: 40),

                        // زر تسجيل الدخول بالتصميم المتدرج
                        _buildGradientButton('تسجيل الدخول', () {
                          // ملاحظة: هنا يتم ربط البرمجة الخلفية مستقبلاً
                        }),

                        const SizedBox(height: 20),

                        // رابط الانتقال لصفحة "إنشاء حساب"
                        GestureDetector(
                          onTap: () {
                            // استخدام Navigator للذهاب إلى صفحة SignUpScreen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignUpScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'ليس لديك حساب؟ إنشاء حساب',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
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

  // دالة مساعدة (Helper Method) لبناء حقول الإدخال بشكل موحد
  Widget _buildTextField(String hint, bool isPassword) {
    return TextFormField(
      textAlign: TextAlign.right, // محاذاة النص لليمين (للغة العربية)
      obscureText: isPassword, // إخفاء النص إذا كان الحقل لكلمة المرور
      style: const TextStyle(color: Colors.white, fontFamily: 'IBMPlexSans'),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
          fontFamily: 'IBMPlexSans',
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 20,
        ),
        // شكل حدود الحقل في الحالة العادية
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 1),
        ),
        // شكل حدود الحقل عند الضغط عليه (التركيز)
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFA07B4F), width: 2),
        ),
      ),
    );
  }

  // دالة مساعدة لبناء الأزرار ذات التدرج اللوني الذهبي/البني
  Widget _buildGradientButton(String title, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        // التدرج اللوني المطلوب من البني الفاتح إلى الغامق
        gradient: const LinearGradient(
          colors: [Color(0xFFA07B4F), Color(0xFF3A2D1D)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              Colors.transparent, // جعل خلفية الزر شفافة ليظهر التدرج
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
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'IBMPlexSans',
          ),
        ),
      ),
    );
  }
}
