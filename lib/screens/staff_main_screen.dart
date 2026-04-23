import 'package:flutter/material.dart';
import 'package:hamaltekk/screens/staff_home_screen.dart';
import 'package:hamaltekk/screens/staff_trips_screen.dart';
import 'package:hamaltekk/screens/staff_chat_list_screen.dart';

class StaffMainScreen extends StatefulWidget {
  const StaffMainScreen({super.key});

  @override
  State<StaffMainScreen> createState() => _StaffMainScreenState();
}

class _StaffMainScreenState extends State<StaffMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const StaffHomeScreen(),
    const Center(child: StaffChatListScreen()),
    const StaffTripsScreen(),
    const Center(
      child: Text(
        'شاشة الملف الشخصي قريباً',
        style: TextStyle(color: Colors.white),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,

      body: IndexedStack(index: _currentIndex, children: _screens),

      // زر الكاميرا في المنتصف مع إطار ذهبي
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print("فتح كاميرا المسح العامة...");
        },
        backgroundColor: const Color(0xFFA07B4F),
        shape: CircleBorder(
          side: BorderSide(color: Colors.white.withOpacity(0.2), width: 2),
        ),
        elevation: 8,
        child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // البار السفلي مع التوهج الذهبي
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF1E1E1E).withOpacity(0.98),
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
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

              const SizedBox(width: 40),

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
