import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hamaltekk/screens/login_screen.dart'; // تأكدي من المسار

class StaffProfileScreen extends StatelessWidget {
  const StaffProfileScreen({super.key});

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
          // 1. حالة التحميل
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFA07B4F)),
            );
          }

          // 2. فحص وجود البيانات
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                "لم يتم العثور على بيانات",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          // 3. استخراج البيانات الفعلية
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          var info = userData['info'] ?? {};
          String adminName =
              info['name'] ?? 'مشرف الحافلة'; // الاسم الفعلي من الفايربيس

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
                  // الهيدر - تم وضعه هنا لضمان سحب الاسم
                  SliverAppBar(
                    expandedHeight: 120,
                    pinned: true,
                    backgroundColor: const Color(0xFF1A1A1A),
                    elevation: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: true,
                      title: Text(
                        adminName, // الآن سيعرض الاسم الفعلي
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
                          _buildSectionTitle('المعلومات الوظيفية'),
                          _buildExpansionInfoCard(
                            title: 'الرقم الوظيفي',
                            value:
                                info['j_no']?.toString() ??
                                'غير متوفر', // حقل j_no
                            icon: Icons.badge_outlined,
                          ),
                          _buildExpansionInfoCard(
                            title: 'المسمى الوظيفي',
                            value: info['role'] ?? 'مشرف', // حقل role
                            icon: Icons.work_outline,
                          ),

                          const SizedBox(height: 25),
                          _buildSectionTitle('البيانات الشخصية'),
                          _buildExpansionInfoCard(
                            title: 'رقم الهوية',
                            value: info['id'] ?? 'غير متوفر', // حقل id
                            icon: Icons.fingerprint,
                          ),
                          _buildExpansionInfoCard(
                            title: 'الجنس',
                            value: info['sex'] ?? 'غير متوفر', // حقل sex
                            icon: Icons.person_outline,
                          ),
                          _buildExpansionInfoCard(
                            title: 'رقم الهاتف',
                            value: info['refNo'] ?? 'غير متوفر', // حقل refNo
                            icon: Icons.phone_android,
                          ),
                          _buildExpansionInfoCard(
                            title: 'البريد الإلكتروني',
                            value:
                                userData['email'] ?? 'غير متوفر', // حقل email
                            icon: Icons.alternate_email,
                          ),

                          const SizedBox(height: 50),
                          _buildPremiumLogoutButton(context),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, right: 5),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFFA07B4F),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildExpansionInfoCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(18),
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
          collapsedIconColor: Colors.white30,
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

  Widget _buildPremiumLogoutButton(BuildContext context) {
    return InkWell(
      onTap: () async {
        await FirebaseAuth.instance.signOut();
        if (context.mounted) {
          // استبدلي LoginScreen باسم شاشتك الفعلي
          Navigator.of(
            context,
            rootNavigator: true,
          ).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      },
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(
            colors: [Color(0xFF634D32), Color(0xFFA07B4F)],
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
    );
  }
}
