import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart' hide TextDirection;

class PilgrimRequestsHistoryScreen extends StatelessWidget {
  const PilgrimRequestsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'سجل طلباتي',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFA07B4F)),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: StreamBuilder<QuerySnapshot>(
          // 🌟 شلنا الـ orderBy من هنا عشان فايربيس ما يرفض الطلب
          stream: FirebaseFirestore.instance
              .collection('SupportRequests')
              .where('pilgrim_uid', isEqualTo: currentUserId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFA07B4F)),
              );
            }

            // إضافة للتحقق من الأخطاء (عشان لو فيه خطأ ما تصير الشاشة بيضاء)
            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'حدث خطأ في جلب البيانات',
                  style: TextStyle(color: Colors.redAccent),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined, size: 80, color: Colors.white24),
                    SizedBox(height: 15),
                    Text(
                      'لا توجد طلبات سابقة',
                      style: TextStyle(color: Colors.white54, fontSize: 18),
                    ),
                  ],
                ),
              );
            }

            // 🌟 الحل هنا: نحول البيانات لقائمة ونرتبها برمجياً داخل فلاتر!
            var requests = snapshot.data!.docs.toList();
            requests.sort((a, b) {
              Timestamp? timeA =
                  (a.data() as Map<String, dynamic>)['created_at'];
              Timestamp? timeB =
                  (b.data() as Map<String, dynamic>)['created_at'];
              if (timeA == null && timeB == null) return 0;
              if (timeA == null) return 1;
              if (timeB == null) return -1;
              return timeB.compareTo(timeA); // ترتيب تنازلي (الأحدث فوق)
            });

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                var data = requests[index].data() as Map<String, dynamic>;
                String category = data['category'] ?? 'طلب مساعدة';
                String note = data['note'] ?? '';
                String status = data['status'] ?? 'pending';
                Timestamp? timestamp = data['created_at'];

                String timeString = '';
                if (timestamp != null) {
                  timeString = DateFormat(
                    'yyyy/MM/dd - hh:mm a',
                  ).format(timestamp.toDate());
                }

                bool isResolved = status == 'resolved';

                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.label_important,
                                color: isResolved
                                    ? Colors.green
                                    : const Color(0xFFA07B4F),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                category,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isResolved
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isResolved
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                            child: Text(
                              isResolved ? 'تم الحل ✅' : 'قيد الانتظار ⏳',
                              style: TextStyle(
                                color: isResolved
                                    ? Colors.green
                                    : Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (note.isNotEmpty) ...[
                        Text(
                          note,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      const Divider(color: Colors.white12),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Colors.white38,
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            timeString,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
