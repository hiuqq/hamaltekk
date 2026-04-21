import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hamaltekk/widgets/hajj_info_overlays.dart';

class PilgrimsListScreen extends StatefulWidget {
  const PilgrimsListScreen({super.key});

  @override
  State<PilgrimsListScreen> createState() => _PilgrimsListScreenState();
}

class _PilgrimsListScreenState extends State<PilgrimsListScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/black.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Users')
                .doc(userId)
                .snapshots(),
            builder: (context, userSnapshot) {
              if (!userSnapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFA07B4F)),
                );
              }

              String? groupId = userSnapshot.data?['group_id'];

              return Column(
                children: [
                  _buildCustomAppBar(context),

                  // عرض العدد
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('Users')
                          .where('group_id', isEqualTo: groupId)
                          .where('type', isEqualTo: 'p')
                          .snapshots(),
                      builder: (context, qSnapshot) {
                        int count = qSnapshot.data?.docs.length ?? 0;
                        return Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'عددهم : $count',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // حقل البحث
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value.trim();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'ابحث عن حاج',
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.white38,
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: Colors.white12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Color(0xFFA07B4F),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // القائمة الفعلية للحجاج مع البحث
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('Users')
                          .where('group_id', isEqualTo: groupId)
                          .where('type', isEqualTo: 'p')
                          .snapshots(),
                      builder: (context, pilgrimsSnapshot) {
                        if (!pilgrimsSnapshot.hasData) return const SizedBox();

                        var docs = pilgrimsSnapshot.data!.docs;

                        // تصفية القائمة بناءً على البحث
                        if (searchQuery.isNotEmpty) {
                          docs = docs.where((doc) {
                            String name =
                                (doc.data()
                                    as Map<String, dynamic>)['info']?['name'] ??
                                '';
                            return name.contains(searchQuery);
                          }).toList();
                        }

                        if (docs.isEmpty) {
                          return const Center(
                            child: Text(
                              'لا يوجد حجاج مطابقين للبحث',
                              style: TextStyle(color: Colors.white54),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            var pilgrimData =
                                docs[index].data() as Map<String, dynamic>;
                            String name =
                                pilgrimData['info']?['name'] ?? 'حاج بدون اسم';

                            // 🌟 التعديل: سحب الأمراض وتصفيتها من أي نصوص فارغة أو مسافات
                            List rawDiseases =
                                pilgrimData['info']?['dis'] ?? [];
                            List cleanDiseases = rawDiseases
                                .where(
                                  (element) =>
                                      element.toString().trim().isNotEmpty,
                                )
                                .toList();

                            // إذا بعد التنظيف صارت المصفوفة فيها أمراض حقيقية، خله أحمر
                            bool isCritical = cleanDiseases.isNotEmpty;

                            return _buildPilgrimCard(
                              context,
                              name,
                              isCritical,
                              pilgrimData,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'قائمة الحجاج المسؤول عنهم',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildPilgrimCard(
    BuildContext context,
    String name,
    bool isCritical,
    Map<String, dynamic> pilgrimData,
  ) {
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
          IconButton(
            icon: Icon(
              Icons.medical_services_outlined,
              color: isCritical ? Colors.redAccent : Colors.white70,
              size: 22,
            ),
            onPressed: () =>
                HajjInfoOverlays.showHealthCard(context, pilgrimData),
          ),
          IconButton(
            icon: const Icon(
              Icons.info_outline,
              color: Colors.white70,
              size: 22,
            ),
            onPressed: () =>
                HajjInfoOverlays.showInfoCard(context, pilgrimData),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
