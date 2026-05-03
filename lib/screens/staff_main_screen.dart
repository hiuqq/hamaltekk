import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🌟 إضافة الفايرستور
import 'package:firebase_auth/firebase_auth.dart'; // 🌟 إضافة المصادقة

import 'package:hamaltekk/screens/staff_home_screen.dart';
import 'package:hamaltekk/screens/staff_trips_screen.dart';
import 'package:hamaltekk/screens/staff_chat_list_screen.dart';
import 'package:hamaltekk/screens/qr_scanner_screen.dart';
import 'package:hamaltekk/screens/profile_staff_screen.dart';

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
    const StaffProfileScreen(),
  ];

  // ==========================================
  // 🌟 تشغيل المستمع فور فتح شاشة المشرف
  // ==========================================
  @override
  void initState() {
    super.initState();
    _listenForEmergencyRequests();
  }

  // 🌟 دالة الاستماع لطلبات المساعدة الجديدة الخاصة بقروب المشرف
  void _listenForEmergencyRequests() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // جلب بيانات المشرف لمعرفة الـ group_id الخاص به
    var userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .get();
    var groupId = userDoc.data()?['group_id'];

    if (groupId != null) {
      // الاستماع للطلبات اللي حالتها pending وموجهة لقروبه
      FirebaseFirestore.instance
          .collection('SupportRequests')
          .where('group_id', isEqualTo: groupId)
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .listen((snapshot) {
            for (var change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added) {
                var requestData = change.doc.data();
                // إظهار الكارد التحذيري للمشرف
                if (requestData != null && mounted) {
                  _showEmergencyCard(requestData, change.doc.id);
                }
              }
            }
          });
    }
  }

  // 🌟 دالة بناء كارد الطوارئ اللي بيطلع بوجه المشرف
  void _showEmergencyCard(Map<String, dynamic> data, String docId) {
    showDialog(
      context: context,
      barrierDismissible:
          false, // يمنع إغلاق الكارد بالنقر خارجه عشان ما يتجاهله
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(
                color: Colors.redAccent,
                width: 2,
              ), // حواف حمراء طارئة
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.redAccent,
                  size: 30,
                ),
                SizedBox(width: 10),
                Text(
                  'طلب مساعدة طارئ!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الحاج: ${data['pilgrim_name']}',
                  style: const TextStyle(
                    color: Color(0xFFA07B4F),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'نوع المشكلة: ${data['category']}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'التفاصيل: ${data['note'].toString().isEmpty ? "لم يكتب تفاصيل إضافية" : data['note']}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA07B4F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    // تحديث حالة الطلب لـ resolved عشان يختفي وما يرجع يطلع له
                    FirebaseFirestore.instance
                        .collection('SupportRequests')
                        .doc(docId)
                        .update({'status': 'resolved'});
                    Navigator.pop(context); // إغلاق الكارد
                  },
                  child: const Text(
                    'استلام الطلب وإغلاق',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,

      body: IndexedStack(index: _currentIndex, children: _screens),

      // زر الكاميرا في المنتصف مع إطار ذهبي
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QRScannerScreen()),
          );
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
