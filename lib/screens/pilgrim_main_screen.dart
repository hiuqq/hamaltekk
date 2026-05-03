import 'package:flutter/material.dart';
import 'package:hamaltekk/screens/home_screen.dart';
import 'package:hamaltekk/screens/pilgrim_trips_screen.dart';
import 'package:hamaltekk/screens/pilgrim_chat_list_screen.dart';
import 'package:hamaltekk/widgets/help_request_bottom_sheet.dart'; // تأكدي من المسار
import 'package:hamaltekk/screens/profile_pilgrim_screen.dart';

class PilgrimMainScreen extends StatefulWidget {
  const PilgrimMainScreen({super.key});

  @override
  State<PilgrimMainScreen> createState() => _PilgrimMainScreenState();
}

class _PilgrimMainScreenState extends State<PilgrimMainScreen> {
  int _currentIndex = 0;

  // 🌟 تحديث قائمة الشاشات وتم إضافة شاشة الملف الشخصي الفعلية
  final List<Widget> _screens = [
    const HomeScreen(), // 0: الرئيسية (Home)
    const PilgrimChatListScreen(), // 1: المحادثات
    const PilgrimTripsScreen(), // 2: الرحلات
    const PilgrimProfileScreen(), // 3: الملف الشخصي (تم الربط بنجاح ✅)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true, // مهم جداً عشان الشاشة تنزل تحت الشريط المفرغ

      body: IndexedStack(index: _currentIndex, children: _screens),
      // ==========================================
      // 🌟 الزر العائم في المنتصف (طلب المساعدة / الشكاوى)
      // ==========================================
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) =>
                const HelpRequestBottomSheet(), // استدعاء نظيف ومختصر
          );
        },
        backgroundColor: const Color(
          0xFFA07B4F,
        ), // 🌟 تم التعديل للون الذهبي الفخم
        elevation: 8,
        shape: const CircleBorder(),
        child: const Icon(Icons.support_agent, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ==========================================
      // 🌟 الشريط السفلي
      // ==========================================
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF1E1E1E).withOpacity(0.98),
        elevation: 20,
        shadowColor: const Color(0xFFA07B4F),
        shape:
            const CircularNotchedRectangle(), // 🌟 هذي اللي تسوي التفريغ المقوس للزر
        notchMargin: 10, // مساحة التجويف حول الزر العائم
        child: SizedBox(
          height: 65, // رفعناه شوي عشان يناسب التجويف
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // الجانب الأيسر
              _buildNavItem(Icons.person_outline, Icons.person, 3), // ملفي
              _buildNavItem(
                Icons.directions_bus_outlined,
                Icons.directions_bus,
                2,
              ), // الرحلات
              // مساحة فارغة في المنتصف عشان الزر العائم يجلس فيها
              const SizedBox(width: 45),

              // الجانب الأيمن
              _buildNavItem(
                Icons.chat_bubble_outline,
                Icons.chat_bubble,
                1,
              ), // المحادثات
              _buildNavItem(Icons.home_outlined, Icons.home, 0), // الرئيسية
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
        size: isSelected ? 32 : 28, // حركتك الممتازة في تكبير الأيقونة
      ),
      onPressed: () {
        setState(() {
          _currentIndex = index;
        });
      },
    );
  }
}
