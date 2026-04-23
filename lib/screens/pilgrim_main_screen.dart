import 'package:flutter/material.dart';
import 'package:hamaltekk/screens/home_screen.dart';
import 'package:hamaltekk/screens/pilgrim_trips_screen.dart';
import 'package:hamaltekk/screens/pilgrim_chat_list_screen.dart'; // 🌟 أضفنا استيراد شاشة قائمة المحادثات

class PilgrimMainScreen extends StatefulWidget {
  const PilgrimMainScreen({super.key});

  @override
  State<PilgrimMainScreen> createState() => _PilgrimMainScreenState();
}

class _PilgrimMainScreenState extends State<PilgrimMainScreen> {
  int _currentIndex = 0;

  // 🌟 تحديث قائمة الشاشات لتبديل "قريباً" بالشاشة الفعلية
  final List<Widget> _screens = [
    const HomeScreen(), // 0: الرئيسية (Home)
    const PilgrimChatListScreen(), // 1: المحادثات (تم الربط هنا ✅)
    const PilgrimTripsScreen(), // 2: الرحلات
    const Center(
      child: Text(
        'شاشة الملف الشخصي قريباً',
        style: TextStyle(color: Colors.white),
      ),
    ), // 3: الملف الشخصي (مكان شاشة الهوية والملاحظات لاحقاً)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,

      body: IndexedStack(index: _currentIndex, children: _screens),

      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF1E1E1E).withOpacity(0.98),
        elevation: 20,
        shadowColor: const Color(0xFFA07B4F),
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
              _buildNavItem(Icons.chat_bubble_outline, Icons.chat_bubble, 1),
              _buildNavItem(Icons.home_outlined, Icons.home, 0),
            ],
          ),
        ),
      ),
    );
  }

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
