import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PilgrimsBoardingScreen extends StatelessWidget {
  final String tripId;

  const PilgrimsBoardingScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E).withOpacity(0.8),
        elevation: 0,
        title: const Text(
          'حالة تصعيد الحجاج',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // الخلفية
          Positioned.fill(
            child: Image.asset('assets/black.png', fit: BoxFit.cover),
          ),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Trips')
                .doc(tripId)
                .collection('manifest')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFA07B4F)),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'لا يوجد حجاج مسجلين',
                    style: TextStyle(color: Colors.white54),
                  ),
                );
              }

              var allPilgrims = snapshot.data!.docs;
              var boarded = allPilgrims
                  .where(
                    (p) =>
                        (p.data() as Map<String, dynamic>)['status'] ==
                        'boarded',
                  )
                  .toList();
              var waiting = allPilgrims
                  .where(
                    (p) =>
                        (p.data() as Map<String, dynamic>)['status'] ==
                        'waiting',
                  )
                  .toList();

              return Column(
                children: [
                  _buildTopStats(boarded.length, waiting.length),
                  Expanded(
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: ListView(
                        padding: const EdgeInsets.all(15),
                        children: [
                          _buildSectionHeader(
                            'بانتظار التصعيد',
                            waiting.length,
                            const Color(0xFFE53935),
                          ),
                          ...waiting.map(
                            (doc) => PilgrimListTile(
                              pilgrimId: doc.id,
                              statusColor: const Color(0xFFE53935),
                              isBoarded: false,
                            ),
                          ),
                          const SizedBox(height: 25),
                          _buildSectionHeader(
                            'تم التصعيد',
                            boarded.length,
                            const Color(0xFF4CAF50),
                          ),
                          ...boarded.map(
                            (doc) => PilgrimListTile(
                              pilgrimId: doc.id,
                              statusColor: const Color(0xFF4CAF50),
                              isBoarded: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // --- العدادات العلوية ---
  Widget _buildTopStats(int boarded, int waiting) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withOpacity(0.8),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          _buildStatItem('تم التصعيد', boarded, const Color(0xFF4CAF50)),
          const SizedBox(width: 15),
          _buildStatItem('في الانتظار', waiting, const Color(0xFFE53935)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(width: 4, height: 18, color: color),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text('$count حجاج', style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}

// 🌟 الويدجت الخاص بكل حاج (مع زر الـ Overlay)
class PilgrimListTile extends StatelessWidget {
  final String pilgrimId;
  final Color statusColor;
  final bool isBoarded;

  const PilgrimListTile({
    super.key,
    required this.pilgrimId,
    required this.statusColor,
    required this.isBoarded,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('Users')
          .doc(pilgrimId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        var userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        var info = userData['info'] ?? {};

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E).withOpacity(0.7),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: statusColor.withOpacity(0.2)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 5,
            ),
            leading: CircleAvatar(
              backgroundColor: statusColor.withOpacity(0.1),
              child: Icon(
                isBoarded ? Icons.check_circle : Icons.hourglass_top_rounded,
                color: statusColor,
              ),
            ),
            title: Text(
              info['name'] ?? 'حاج بدون اسم',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'تصريح: $pilgrimId',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.info_outline, color: Color(0xFFA07B4F)),
              onPressed: () {
                // 🌟 إظهار الـ Overlay عند الضغط
                _showPilgrimOverlay(context, userData);
              },
            ),
          ),
        );
      },
    );
  }

  // 🌟 دالة إظهار الـ Overlay (النافذة المنبثقة)
  void _showPilgrimOverlay(
    BuildContext context,
    Map<String, dynamic> userData,
  ) {
    var info = userData['info'] ?? {};
    var health = userData['health_info'] ?? {};

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFA07B4F).withOpacity(0.5),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20),
              ],
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // الهيدر
                  Row(
                    children: [
                      const Icon(
                        Icons.medical_information,
                        color: Color(0xFFA07B4F),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'تفاصيل الحاج الصحية',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 25),

                  // معلومات الحاج
                  _buildDetailItem(Icons.person, 'الاسم', info['name'] ?? '-'),
                  _buildDetailItem(
                    Icons.phone,
                    'رقم التواصل',
                    info['phone'] ?? '-',
                  ),
                  _buildDetailItem(
                    Icons.bloodtype,
                    'فصيلة الدم',
                    health['blood_type'] ?? '-',
                  ),
                  _buildDetailItem(
                    Icons.medical_services,
                    'الحالة الصحية',
                    health['condition'] ?? 'سليم',
                  ),
                  _buildDetailItem(
                    Icons.warning_amber_rounded,
                    'الحساسية',
                    health['allergies'] ?? 'لا يوجد',
                  ),

                  const SizedBox(height: 20),

                  // زر الإغلاق
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA07B4F),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'تم المراجعة',
                        style: TextStyle(
                          color: Colors.white,
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
      },
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFFA07B4F).withOpacity(0.7)),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
