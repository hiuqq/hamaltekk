import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hamaltekk/widgets/hajj_info_overlays.dart'; // 🌟 استدعاء الكلاس حقك

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
          // الخلفية الفخمة
          Positioned.fill(
            child: Image.asset('assets/black.png', fit: BoxFit.cover),
          ),

          StreamBuilder<QuerySnapshot>(
            // 🌟 نقرأ من قائمة ركاب الرحلة الحالية
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

              // تقسيمهم حسب حالة التصعيد
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
                        children: [
                          _buildSectionHeader(
                            'بانتظار التصعيد',
                            waiting.length,
                            const Color(0xFFE53935),
                          ),
                          const SizedBox(height: 10),
                          // 🌟 استدعاء الكرت الموحد للحجاج في الانتظار
                          ...waiting.map(
                            (doc) => UnifiedPilgrimCard(pilgrimId: doc.id),
                          ),

                          const SizedBox(height: 30),

                          _buildSectionHeader(
                            'تم التصعيد',
                            boarded.length,
                            const Color(0xFF4CAF50),
                          ),
                          const SizedBox(height: 10),
                          // 🌟 استدعاء الكرت الموحد للحجاج اللي تم تصعيدهم
                          ...boarded.map(
                            (doc) => UnifiedPilgrimCard(pilgrimId: doc.id),
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
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count حاج',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 🌟 الكرت الموحد (نسخة طبق الأصل من تصميمك)
// ============================================================================
// ============================================================================
// 🌟 الكرت الموحد (تم تعديل الترتيب: الاسم يمين والأيقونات يسار)
// ============================================================================
class UnifiedPilgrimCard extends StatelessWidget {
  final String pilgrimId;

  const UnifiedPilgrimCard({super.key, required this.pilgrimId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('Users')
          .doc(pilgrimId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        var pilgrimData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        String name = pilgrimData['info']?['name'] ?? 'حاج بدون اسم';

        List rawDiseases = pilgrimData['info']?['dis'] ?? [];
        List cleanDiseases = rawDiseases
            .where((element) => element.toString().trim().isNotEmpty)
            .toList();
        bool isCritical = cleanDiseases.isNotEmpty;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: isCritical
                  ? [
                      const Color(0xFF7B241C).withOpacity(0.9),
                      const Color(0xFF44130E).withOpacity(0.9),
                    ]
                  : [
                      const Color(0xFF2D3E33).withOpacity(0.9),
                      const Color(0xFF1E2721).withOpacity(0.9),
                    ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            border: Border.all(color: Colors.white10, width: 0.5),
          ),
          child: Row(
            children: [
              // 1. اسم الحاج (صار في البداية عشان يجي يمين)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1, // عشان لو الاسم طويل ما ينزل سطر ثاني
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              // 2. أيقونة المعلومات الشخصية
              IconButton(
                icon: const Icon(
                  Icons.info_outline,
                  color: Colors.white70,
                  size: 22,
                ),
                onPressed: () =>
                    HajjInfoOverlays.showInfoCard(context, pilgrimData),
              ),

              // 3. أيقونة المعلومات الطبية (صارت في الأخير عشان تجي يسار)
              IconButton(
                icon: Icon(
                  Icons.medical_services_outlined,
                  color: isCritical ? Colors.redAccent : Colors.white70,
                  size: 22,
                ),
                onPressed: () =>
                    HajjInfoOverlays.showHealthCard(context, pilgrimData),
              ),
            ],
          ),
        );
      },
    );
  }
}
