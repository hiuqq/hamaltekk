import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  @override
  void initState() {
    super.initState();
    _listenForEmergencyRequests();
  }

  // 🌟 دالة الاستماع لطلبات المساعدة (الجديدة فقط)
  void _listenForEmergencyRequests() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    var userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .get();
    var groupId = userDoc.data()?['group_id'];

    if (groupId != null) {
      FirebaseFirestore.instance
          .collection('SupportRequests')
          .where('group_id', isEqualTo: groupId)
          .where('status', isEqualTo: 'new') // 🌟 نستمع للطلبات الجديدة فقط
          .snapshots()
          .listen((snapshot) {
            for (var change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added) {
                var requestData = change.doc.data();
                if (requestData != null && mounted) {
                  _showEmergencyCard(requestData, change.doc.id);
                }
              }
            }
          });
    }
  }

  // 🌟 الكارد المنبثق مع الخيارات الجديدة
  void _showEmergencyCard(Map<String, dynamic> data, String docId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.redAccent, width: 2),
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
              Row(
                children: [
                  // ⏳ زر التأجيل
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orangeAccent,
                        side: const BorderSide(color: Colors.orangeAccent),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.schedule, size: 18),
                      label: const Text(
                        'تأجيل للسجل',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      onPressed: () {
                        // 🌟 تحويله لقيد الانتظار (يختفي من الشاشة ويروح لصندوق الطلبات)
                        FirebaseFirestore.instance
                            .collection('SupportRequests')
                            .doc(docId)
                            .update({'status': 'pending'});
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  // ✅ زر الحل فوراً
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text(
                        'تم الحل',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      onPressed: () {
                        // 🌟 تحويله لمنجز فوراً
                        FirebaseFirestore.instance
                            .collection('SupportRequests')
                            .doc(docId)
                            .update({
                              'status': 'resolved',
                              'resolved_at': FieldValue.serverTimestamp(),
                            });
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
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
      onPressed: () => setState(() => _currentIndex = index),
    );
  }
}
