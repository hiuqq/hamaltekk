import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart' hide TextDirection;

class StaffRequestsScreen extends StatefulWidget {
  const StaffRequestsScreen({super.key});

  @override
  State<StaffRequestsScreen> createState() => _StaffRequestsScreenState();
}

class _StaffRequestsScreenState extends State<StaffRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'صندوق طلبات الحجاج',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFA07B4F)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFA07B4F),
          labelColor: const Color(0xFFA07B4F),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'قيد الانتظار ⏳'),
            Tab(text: 'تم الحل ✅'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/black.png'),
            fit: BoxFit.cover,
            opacity: 0.1,
          ),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRequestsList('pending'),
              _buildRequestsList('resolved'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestsList(String status) {
    final String? supervisorId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Users')
          .doc(supervisorId)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData)
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFA07B4F)),
          );

        var userData = userSnapshot.data!.data() as Map<String, dynamic>;
        String groupId = userData['group_id'] ?? '';

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('SupportRequests')
              .where('group_id', isEqualTo: groupId)
              .where('status', isEqualTo: status)
              .snapshots(),
          builder: (context, requestSnapshot) {
            if (requestSnapshot.connectionState == ConnectionState.waiting)
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFA07B4F)),
              );

            if (!requestSnapshot.hasData ||
                requestSnapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      status == 'pending'
                          ? Icons.check_circle_outline
                          : Icons.history,
                      size: 80,
                      color: Colors.white24,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      status == 'pending'
                          ? 'لا توجد طلبات معلقة'
                          : 'السجل فارغ',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              );
            }

            var docs = requestSnapshot.data!.docs.toList();
            docs.sort((a, b) {
              Timestamp? tA = (a.data() as Map<String, dynamic>)['created_at'];
              Timestamp? tB = (b.data() as Map<String, dynamic>)['created_at'];
              if (tA == null || tB == null) return 0;
              return tB.compareTo(tA);
            });

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                var data = docs[index].data() as Map<String, dynamic>;
                String requestId = docs[index].id;
                String pilgrimName = data['pilgrim_name'] ?? 'حاج';
                String category = data['category'] ?? 'طلب مساعدة';
                String note = data['note'] ?? '';
                Timestamp? timestamp = data['created_at'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(20),
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
                              const CircleAvatar(
                                backgroundColor: Color(0xFFA07B4F),
                                radius: 15,
                                child: Icon(
                                  Icons.person,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                pilgrimName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            timestamp != null
                                ? DateFormat(
                                    'hh:mm a',
                                  ).format(timestamp.toDate())
                                : '',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA07B4F).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            color: Color(0xFFA07B4F),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        note,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (status == 'pending')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xFF4CAF50,
                              ).withOpacity(0.1),
                              foregroundColor: const Color(0xFF4CAF50),
                              side: const BorderSide(color: Color(0xFF4CAF50)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text(
                              'تم الحل ومعالجة الطلب',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: () => _markAsResolved(requestId),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _markAsResolved(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('SupportRequests')
          .doc(docId)
          .update({
            'status': 'resolved',
            'resolved_at': FieldValue.serverTimestamp(),
          });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث حالة الطلب بنجاح ✅'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ في التحديث'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
