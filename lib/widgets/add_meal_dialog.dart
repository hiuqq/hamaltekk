import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hamaltekk/screens/meal_history_screen.dart'; // 🌟 استدعاء شاشة السجل

class AddMealDialog extends StatefulWidget {
  const AddMealDialog({super.key});

  @override
  State<AddMealDialog> createState() => _AddMealDialogState();
}

class _AddMealDialogState extends State<AddMealDialog> {
  final TextEditingController locationController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  String selectedMeal = 'غداء'; // القيمة الافتراضية
  final List<String> mealTypes = ['فطور', 'غداء', 'عشاء', 'وجبة خفيفة'];

  // 🌟 إضافة أيام الحج لربط الوجبة بالتقرير
  String? selectedDay;
  final List<Map<String, String>> hajjDays = [
    {'key': 'day_8', 'title': 'يوم التروية'},
    {'key': 'day_9', 'title': 'يوم عرفة'},
    {'key': 'day_10', 'title': 'يوم النحر'},
    {'key': 'day_11', 'title': 'أول أيام التشريق'},
    {'key': 'day_12', 'title': 'ثاني أيام التشريق'},
    {'key': 'day_13', 'title': 'ثالث أيام التشريق'},
  ];

  bool isLoading = false;

  Future<void> _addMealAndNotify() async {
    // 1. التحقق من اختيار اليوم والمكان
    if (selectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء تحديد اليوم!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال مكان التسليم!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      String? supervisorId = FirebaseAuth.instance.currentUser?.uid;
      if (supervisorId == null) return;

      // 2. نجيب رقم مجموعة المشرف عشان نعرف حجاجه
      var supDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(supervisorId)
          .get();
      String groupId = supDoc['group_id'] ?? '';

      // 3. نحفظ الإشعار في السجل مع ربطه باليوم (day) المخصص للتقرير 🌟
      await FirebaseFirestore.instance.collection('Meal_Notifications').add({
        'supervisor_id': supervisorId,
        'meal_type': selectedMeal,
        'location': locationController.text.trim(),
        'notes': notesController.text.trim(),
        'day': selectedDay,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 4. نجيب كل الحجاج اللي تحت هذا المشرف
      var pilgrimsSnap = await FirebaseFirestore.instance
          .collection('Users')
          .where('group_id', isEqualTo: groupId)
          .where('type', isEqualTo: 'p')
          .get();

      // 5. نجهز رسالة الإشعار
      String messageText =
          '📢 إشعار وجبة: تم توفير "$selectedMeal" في "${locationController.text.trim()}".';
      if (notesController.text.trim().isNotEmpty) {
        messageText += '\nملاحظة: ${notesController.text.trim()}';
      }

      // 6. نرسل الرسالة لكل حاج (باستخدام Batch)
      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (var doc in pilgrimsSnap.docs) {
        String pilgrimId = doc.id;
        String chatId = '${supervisorId}_$pilgrimId';

        var messageRef = FirebaseFirestore.instance
            .collection('Chats')
            .doc(chatId)
            .collection('messages')
            .doc();

        batch.set(messageRef, {
          'sender_id': supervisorId,
          'text': messageText,
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'system_alert', // عشان تطلع فورا بنفس التنسيق
        });
      }

      await batch.commit();

      if (mounted) {
        Navigator.pop(context); // نقفل النافذة بعد النجاح
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال إشعار الوجبة للحجاج بنجاح! 🚀'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF332A1D), // لون ترابي غامق فخم
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      // 🌟 منع التصاق النافذة بالشاشة عند ظهور الكيبورد
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Directionality(
        textDirection: TextDirection.rtl,
        // 🌟 إضافة السكرول لحل مشكلة (Overflow) عند فتح الكيبورد
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // زر السجل بجانب العنوان
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'إضافة معلومات الوجبة',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.history,
                        color: Color(0xFFA07B4F),
                        size: 28,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MealHistoryScreen(),
                          ),
                        );
                      },
                      tooltip: 'سجل الوجبات',
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                // 🌟 حقل اختيار اليوم (Dropdown)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedDay,
                      hint: const Text(
                        'اختر يوم الإشعار',
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                      dropdownColor: const Color(0xFF332A1D),
                      isExpanded: true,
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white70,
                      ),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      items: hajjDays.map((day) {
                        return DropdownMenuItem<String>(
                          value: day['key'],
                          child: Text(day['title']!),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedDay = newValue;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // حقل نوع الوجبة (Dropdown)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedMeal,
                      dropdownColor: const Color(0xFF332A1D),
                      isExpanded: true,
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white70,
                      ),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      items: mealTypes.map((String meal) {
                        return DropdownMenuItem<String>(
                          value: meal,
                          child: Text(meal),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedMeal = newValue!;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // حقل مكان التسليم
                TextField(
                  controller: locationController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'مكان التسليم (مثال: خيمة 4، مقر الحملة...)',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // حقل الملاحظات (اختياري)
                TextField(
                  controller: notesController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'ملاحظات (اختياري)',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                // زر الإضافة
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA07B4F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: isLoading ? null : _addMealAndNotify,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'إضافة وإرسال',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
