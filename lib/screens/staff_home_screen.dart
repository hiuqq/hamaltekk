import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hamaltekk/screens/pilgrims_list_screen.dart';

class StaffHomeScreen extends StatefulWidget {
  const StaffHomeScreen({super.key});

  @override
  State<StaffHomeScreen> createState() => _StaffHomeScreenState();
}

class _StaffHomeScreenState extends State<StaffHomeScreen> {
  // 🌟 متغير لحفظ اليوم المحدد حالياً (الافتراضي هو يوم التروية - 8)
  String selectedDayKey = 'day_8';

  // قائمة بأسماء الأيام والمفاتيح الخاصة بها في الداتابيس
  final List<Map<String, String>> hajjDays = [
    {'key': 'day_8', 'name': 'يوم 8\nالتروية'},
    {'key': 'day_9', 'name': 'يوم 9\nعرفة'},
    {'key': 'day_10', 'name': 'يوم 10\nالعيد'},
    {'key': 'day_11', 'name': 'يوم 11\nالتشريق'},
    {'key': 'day_12', 'name': 'يوم 12\nالتعجل'},
    {'key': 'day_13', 'name': 'يوم 13\nالختام'},
  ];

  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true, // مهم للبار السفلي
      // 🌟 زر الكاميرا العائم في المنتصف (الماسح)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print("فتح كاميرا المسح...");
        },
        backgroundColor: const Color(0xFFA07B4F),
        shape: const CircleBorder(),
        child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // 🌟 البار السفلي
      bottomNavigationBar: _buildBottomBar(),

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Users')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFA07B4F)),
            );
          }

          var userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};

          // سحب الاسم
          String fullName = userData['info']?['name'] ?? 'مشرفنا';
          String firstName = fullName.split(' ')[0];

          // سحب مهام الحج من الداتابيس
          Map<String, dynamic> activeHajjTasks =
              userData['info']?['active_hajj_tasks'] ?? {};
          // مهام اليوم المحدد فقط
          List<dynamic> currentDayTasks = activeHajjTasks[selectedDayKey] ?? [];

          return Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/black.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(height: 30),

                    // 1. الترحيب
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'أهلاً $firstName',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text('👋', style: TextStyle(fontSize: 28)),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // 2. 🌟 شريط اختيار أيام الحج (Day Selector) 🌟
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true, // عشان يبدأ من اليمين
                      child: Row(
                        children: hajjDays.map((day) {
                          bool isSelected = selectedDayKey == day['key'];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedDayKey = day['key']!;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(left: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFA07B4F)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFA07B4F)
                                      : Colors.white24,
                                ),
                              ),
                              child: Text(
                                day['name']!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white54,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // 3. 🌟 قائمة المهام الديناميكية لليوم المحدد 🌟
                    const Text(
                      ': قائمة المهام اليومية',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // رسم المهام أو رسالة إذا كان اليوم فارغ
                    if (currentDayTasks.isNotEmpty)
                      ...List.generate(currentDayTasks.length, (index) {
                        var task = currentDayTasks[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildTaskItem(
                            task['title'] ?? 'مهمة بدون عنوان',
                            task['is_completed'] ?? false,
                            (val) async {
                              // 🌟 تحديث الداتابيس عند الضغط
                              List<dynamic> updatedTasks = List.from(
                                currentDayTasks,
                              );
                              updatedTasks[index]['is_completed'] = val;

                              await FirebaseFirestore.instance
                                  .collection('Users')
                                  .doc(userId)
                                  .update({
                                    'info.active_hajj_tasks.$selectedDayKey':
                                        updatedTasks,
                                  });
                            },
                          ),
                        );
                      })
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.task_alt,
                              color: Colors.white24,
                              size: 40,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'لا توجد مهام مسجلة لهذا اليوم',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 40),

                    // 4. خدمات إضافية (الأزرار الثابتة)
                    const Text(
                      'خدمات أضافية',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(color: Colors.white24, thickness: 1),
                    ),
                    const SizedBox(height: 10),

                    _buildServiceButton(
                      'قائمة الحجاج المسؤول عنهم',
                      Icons.people_alt_outlined,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PilgrimsListScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildServiceButton(
                      'إشعار تسليم الوجبة',
                      Icons.restaurant_menu_outlined,
                      () {},
                    ),
                    const SizedBox(height: 15),
                    _buildServiceButton(
                      'التقارير اليومية',
                      Icons.insert_drive_file_outlined,
                      () {},
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // === مكونات الواجهة (Widgets) ===

  Widget _buildTaskItem(
    String title,
    bool isChecked,
    Function(bool?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: isChecked ? Colors.white.withOpacity(0.05) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isChecked
              ? Colors.white24
              : const Color(0xFFA07B4F).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isChecked ? Colors.white38 : Colors.white,
                fontSize: 14,
                decoration: isChecked
                    ? TextDecoration.lineThrough
                    : null, // شطب النص إذا اكتمل
              ),
            ),
          ),
          const SizedBox(width: 10),
          Theme(
            data: ThemeData(unselectedWidgetColor: Colors.white54),
            child: Checkbox(
              value: isChecked,
              onChanged: onChanged,
              activeColor: const Color(0xFFA07B4F),
              checkColor: Colors.white,
              shape: const CircleBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceButton(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(
            colors: [Color(0xFF3A2D1D), Color(0xFF1E1E1E)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          border: Border.all(color: Colors.white12, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 15),
            Icon(icon, color: Colors.white, size: 26),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return BottomAppBar(
      color: const Color(0xFF1E1E1E).withOpacity(0.95),
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.person_outline, color: Colors.white54),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(
                Icons.directions_bus_outlined,
                color: Colors.white54,
              ),
              onPressed: () {},
            ),
            const SizedBox(width: 40),
            IconButton(
              icon: const Icon(
                Icons.chat_bubble_outline,
                color: Colors.white54,
              ),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.home, color: Color(0xFFA07B4F)),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
