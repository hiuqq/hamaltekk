import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hamaltekk/screens/pilgrim_requests_history_screen.dart';

class HelpRequestBottomSheet extends StatefulWidget {
  const HelpRequestBottomSheet({super.key});

  @override
  State<HelpRequestBottomSheet> createState() => _HelpRequestBottomSheetState();
}

class _HelpRequestBottomSheetState extends State<HelpRequestBottomSheet> {
  int _selectedCategoryIndex = -1;
  final TextEditingController _noteController = TextEditingController();

  String? selectedDay;
  final List<Map<String, String>> hajjDays = [
    {'key': 'day_8', 'title': 'يوم التروية'},
    {'key': 'day_9', 'title': 'يوم عرفة'},
    {'key': 'day_10', 'title': 'يوم النحر'},
    {'key': 'day_11', 'title': 'أول أيام التشريق'},
    {'key': 'day_12', 'title': 'ثاني أيام التشريق'},
    {'key': 'day_13', 'title': 'ثالث أيام التشريق'},
  ];

  final List<Map<String, dynamic>> _categories = [
    {'title': 'طوارئ طبية', 'icon': Icons.medical_services},
    {'title': 'حالة ضياع', 'icon': Icons.wrong_location},
    {'title': 'مشكلة سكن', 'icon': Icons.home_work},
    {'title': 'النقل والحافلة', 'icon': Icons.directions_bus},
    {'title': 'استفسار عام', 'icon': Icons.help_outline},
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 15, 20, bottomInset + 20),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        border: Border(top: BorderSide(color: Color(0xFFA07B4F), width: 1.5)),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.support_agent,
                        color: Color(0xFFA07B4F),
                        size: 28,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'كيف يمكننا مساعدتك؟',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.history,
                      color: Color(0xFFA07B4F),
                      size: 28,
                    ),
                    tooltip: 'سجل طلباتي',
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const PilgrimRequestsHistoryScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 15),

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
                      'حدد اليوم (اختياري)',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                    dropdownColor: const Color(0xFF1E1E1E),
                    isExpanded: true,
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white70,
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    items: hajjDays
                        .map(
                          (day) => DropdownMenuItem<String>(
                            value: day['key'],
                            child: Text(day['title']!),
                          ),
                        )
                        .toList(),
                    onChanged: (newValue) =>
                        setState(() => selectedDay = newValue),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(_categories.length, (index) {
                  final isSelected = _selectedCategoryIndex == index;
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _categories[index]['icon'],
                          size: 16,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFFA07B4F),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _categories[index]['title'],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) => setState(
                      () => _selectedCategoryIndex = selected ? index : -1,
                    ),
                    backgroundColor: const Color(0xFF2A2A2A),
                    selectedColor: const Color(0xFFA07B4F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: isSelected ? Colors.transparent : Colors.white12,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _noteController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'اكتب تفاصيل رسالتك أو مشكلتك هنا...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF121212),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: Color(0xFFA07B4F),
                      width: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA07B4F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () async {
                    if (_selectedCategoryIndex == -1 &&
                        _noteController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'الرجاء اختيار نوع المشكلة أو كتابة تفاصيل.',
                          ),
                        ),
                      );
                      return;
                    }
                    if (selectedDay == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('الرجاء تحديد اليوم!'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFA07B4F),
                        ),
                      ),
                    );

                    try {
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      var userDoc = await FirebaseFirestore.instance
                          .collection('Users')
                          .doc(uid)
                          .get();
                      var userData = userDoc.data() as Map<String, dynamic>;
                      var groupId = userData['group_id'];
                      var info = userData['info'] ?? {};

                      await FirebaseFirestore.instance
                          .collection('SupportRequests')
                          .add({
                            'pilgrim_uid': uid,
                            'pilgrim_name': info['name'] ?? 'حاج',
                            'group_id': groupId,
                            'category':
                                _categories[_selectedCategoryIndex]['title'],
                            'note': _noteController.text.trim(),
                            'day': selectedDay,
                            'status':
                                'new', // 🌟 غيرناها لـ new عشان تطلع للمشرف كطلب جديد
                            'created_at': FieldValue.serverTimestamp(),
                          });

                      if (context.mounted) {
                        Navigator.pop(context);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم إرسال طلبك للمشرف بنجاح.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text(
                    'إرسال الطلب',
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
    );
  }
}
