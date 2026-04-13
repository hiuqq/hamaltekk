import 'package:flutter/material.dart';

class CommunicationScreen extends StatelessWidget {
  const CommunicationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // جعلنا ارتفاع منطقة الكعبة أصغر قليلاً ليعطي مساحة للعنوان والكروت في الأعلى
    final double kaabaHeight = size.height * 0.45;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. خلفية التطبيق السوداء (نفس الموجودة في الساين أب)
          Positioned.fill(
            child: Image.asset('assets/black.png', fit: BoxFit.cover),
          ),

          // 2. منطقة الكعبة المنحنية في الأسفل (بنفس ستايل الساين أب)
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildKaabaBackground(kaabaHeight),
          ),

          // 3. المحتوى العلوي (العنوان والكروت)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    'كيف تود التواصل؟',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'يمكنك التحدث مع مشرف الحملة للإجابة على استفساراتك.',
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 40),

                  // كرت المشرف بتصميم فخم يتناسب مع السواد والذهب
                  _buildCommunicationCard(
                    title: 'المشرف: صالح',
                    subtitle: 'متصل الآن - جاهز لخدمتك',
                    icon: Icons.person_pin_outlined,
                    onTap: () => print("تواصل مع المشرف"),
                  ),

                  const SizedBox(height: 20),

                  // كرت الدعم الفني
                  _buildCommunicationCard(
                    title: 'الدعم الفني',
                    subtitle: 'للمساعدة التقنية والأسئلة العامة',
                    icon: Icons.support_agent_outlined,
                    onTap: () => print("تواصل مع الدعم"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // البار السفلي المنحني
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // نفس دالة بناء خلفية الكعبة الموجودة في كود الساين أب الخاص بكِ
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
                      Colors.black.withOpacity(0.5),
                      Colors.black.withOpacity(0.9),
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

  // ويدجت الكروت بتصميم متناسق مع ألوان الكعبة والذهب
  Widget _buildCommunicationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFA07B4F).withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFFA07B4F),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            Icon(icon, color: const Color(0xFFA07B4F), size: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      height: 65,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white10),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Icon(Icons.person_outline, color: Colors.white54),
          Icon(Icons.directions_bus_outlined, color: Colors.white54),
          Icon(Icons.chat_bubble, color: Color(0xFFA07B4F)),
          Icon(Icons.home_outlined, color: Colors.white54),
        ],
      ),
    );
  }
}
