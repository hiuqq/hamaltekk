import 'package:flutter/material.dart';
import 'package:hamaltekk/screens/home_screen.dart'; // مسار شاشتك الرئيسية
import 'package:hamaltekk/screens/pilgrim_trips_screen.dart'; // مسار شاشة الرحلات

class PilgrimMainScreen extends StatefulWidget {
  const PilgrimMainScreen({super.key});

  @override
  State<PilgrimMainScreen> createState() => _PilgrimMainScreenState();
}

class _PilgrimMainScreenState extends State<PilgrimMainScreen> {
  // 🌟 خلينا البداية 0 عشانها مرتبطة بـ HomeScreen بناءً على ترتيبك
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(), // 0: الرئيسية (Home)
    const Center(
      child: Text(
        'شاشة المحادثات قريباً',
        style: TextStyle(color: Colors.white),
      ),
    ), // 1: المحادثات
    const PilgrimTripsScreen(), // 2: الرحلات
    const Center(
      child: Text(
        'شاشة الملف الشخصي قريباً',
        style: TextStyle(color: Colors.white),
      ),
    ), // 3: الملف الشخصي
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,

      body: IndexedStack(index: _currentIndex, children: _screens),

      // 🌟 البار السفلي مع التوهج الذهبي (نفس المشرف بالضبط بس بدون الفراغ اللي بالنص)
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF1E1E1E).withOpacity(0.98),
        elevation: 20,
        shadowColor: const Color(0xFFA07B4F), // التوهج الذهبي
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.person_outline, Icons.person, 3),
              _buildNavItem(
                Icons.directions_bus_outlined,
                Icons.directions_bus,
                2,
              ),

              // تم إزالة الفراغ (SizedBox) الخاص بزر الكاميرا هنا ليصبح التوزيع متساوي
              _buildNavItem(Icons.chat_bubble_outline, Icons.chat_bubble, 1),
              _buildNavItem(Icons.home_outlined, Icons.home, 0),
            ],
          ),
        ),
      ),
    );
  }

  // 🌟 نفس دالتك بالضبط لضمان توحيد شكل الأيقونات وتكبيرها عند الضغط
  Widget _buildNavItem(IconData outlineIcon, IconData filledIcon, int index) {
    bool isSelected = _currentIndex == index;
    return IconButton(
      icon: Icon(
        isSelected ? filledIcon : outlineIcon,
        color: isSelected ? const Color(0xFFA07B4F) : Colors.white54,
        size: isSelected ? 32 : 28,
      ),
      onPressed: () {
        setState(() {
          _currentIndex = index;
        });
      },
    );
  }
}
