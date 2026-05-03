import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PilgrimProfileScreen extends StatelessWidget {
  const PilgrimProfileScreen({super.key});

  // دالة ذكية لتنظيف وعرض مصفوفات الأمراض والأجهزة
  String _formatList(List? list) {
    if (list == null || list.isEmpty) return 'سليم (لا يوجد)';
    var cleanList = list.where((e) => e.toString().trim().isNotEmpty).toList();
    return cleanList.isEmpty ? 'سليم (لا يوجد)' : cleanList.join('، ');
  }

  @override
  Widget build(BuildContext context) {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Users')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFA07B4F)),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                "لم يتم العثور على بيانات",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          // سحب البيانات من قاعدة البيانات
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          var info = userData['info'] ?? {};

          String pilgrimName = info['name'] ?? 'اسم الحاج';

          return Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/black.png'),
                fit: BoxFit.cover,
                opacity: 0.1,
              ),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: CustomScrollView(
                slivers: [
                  // الهيدر
                  SliverAppBar(
                    expandedHeight: 120,
                    pinned: true,
                    backgroundColor: const Color(0xFF1A1A1A),
                    elevation: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: true,
                      title: Text(
                        pilgrimName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ================= القسم الأول: المعلومات الشخصية =================
                          _buildSectionTitle('المعلومات الشخصية'),
                          _buildExpansionInfoCard(
                            title: 'رقم التصريح',
                            value: info['p_no']?.toString() ?? 'غير متوفر',
                            icon: Icons.confirmation_number_outlined,
                          ),
                          _buildExpansionInfoCard(
                            title: 'رقم الهوية',
                            value: info['id']?.toString() ?? 'غير متوفر',
                            icon: Icons.fingerprint,
                          ),
                          _buildExpansionInfoCard(
                            title: 'الجنس',
                            value: info['sex'] ?? 'غير متوفر',
                            icon: Icons.person_outline,
                          ),
                          _buildExpansionInfoCard(
                            title: 'تاريخ الميلاد',
                            value: info['dob'] ?? 'غير متوفر',
                            icon: Icons.calendar_month_outlined,
                          ),
                          _buildExpansionInfoCard(
                            title: 'رقم الهاتف',
                            value: info['ph']?.toString() ?? 'غير متوفر',
                            icon: Icons.phone_android,
                          ),
                          _buildExpansionInfoCard(
                            title: 'البريد الإلكتروني',
                            value: userData['email'] ?? 'غير متوفر',
                            icon: Icons.alternate_email,
                          ),

                          const SizedBox(height: 35),

                          // ================= القسم الثاني: المعلومات الصحية =================
                          _buildSectionTitle('المعلومات الصحية'),
                          _buildExpansionInfoCard(
                            title: 'فصيلة الدم',
                            value: info['b_type'] ?? 'غير متوفر',
                            icon: Icons.bloodtype_outlined,
                          ),
                          _buildExpansionInfoCard(
                            title: 'الأمراض المزمنة',
                            value: _formatList(info['dis']),
                            icon: Icons.medical_services_outlined,
                          ),
                          _buildExpansionInfoCard(
                            title: 'الأجهزة الطبية',
                            value: _formatList(info['dev']),
                            icon: Icons.monitor_heart_outlined,
                          ),
                          _buildExpansionInfoCard(
                            title: 'الطول',
                            value: info['h'] != null
                                ? '${info['h']} سم'
                                : 'غير متوفر',
                            icon: Icons.height,
                          ),
                          _buildExpansionInfoCard(
                            title: 'الوزن',
                            value: info['w'] != null
                                ? '${info['w']} كجم'
                                : 'غير متوفر',
                            icon: Icons.monitor_weight_outlined,
                          ),
                          _buildExpansionInfoCard(
                            title: 'رقم الهاتف للطوارئ',
                            value: info['em_ph']?.toString() ?? 'غير متوفر',
                            icon: Icons.emergency_outlined,
                          ),

                          const SizedBox(height: 40),

                          // ================= زر تسجيل الخروج المميز =================
                          InkWell(
                            onTap: () async {
                              await FirebaseAuth.instance.signOut();
                              if (context.mounted) {
                                Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).pushNamedAndRemoveUntil(
                                  '/login',
                                  (route) => false,
                                );
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              height: 55,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF634D32),
                                    Color(0xFFA07B4F),
                                  ],
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  'تسجيل الخروج',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // دالة بناء العناوين باللون الذهبي
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, right: 5),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFFA07B4F),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // دالة بناء الكروت بالتصميم الموحد الداكن
  Widget _buildExpansionInfoCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // لون الكارد الموحد (أسود رمادي)
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(icon, color: const Color(0xFFA07B4F), size: 22),
          title: Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
          iconColor: const Color(0xFFA07B4F),
          collapsedIconColor: Colors.white54,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 0, 65, 20),
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
