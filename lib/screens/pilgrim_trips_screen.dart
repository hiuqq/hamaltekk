import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:url_launcher/url_launcher.dart';
import 'package:hamaltekk/screens/chat_screen.dart';

class PilgrimTripsScreen extends StatelessWidget {
  const PilgrimTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/black.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('Users')
                      .doc(userId)
                      .get(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFA07B4F),
                        ),
                      );
                    }

                    var userData =
                        userSnapshot.data?.data() as Map<String, dynamic>?;
                    String? groupId = userData?['group_id'];

                    if (groupId == null) {
                      return const Center(
                        child: Text(
                          'لم يتم تعيينك في مجموعة بعد',
                          style: TextStyle(color: Colors.white54),
                        ),
                      );
                    }

                    return StreamBuilder<QuerySnapshot>(
                      // 1. جلب التمبلت الأساسي ليعمل كمسودة
                      stream: FirebaseFirestore.instance
                          .collection('TripTemplates')
                          .orderBy('order')
                          .snapshots(),
                      builder: (context, templateSnapshot) {
                        if (templateSnapshot.hasError) {
                          return const Center(
                            child: Text(
                              'حدث خطأ',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          );
                        }
                        if (templateSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFA07B4F),
                            ),
                          );
                        }

                        return StreamBuilder<QuerySnapshot>(
                          // 2. جلب الرحلات الحقيقية التي أنشأها المشرف
                          stream: FirebaseFirestore.instance
                              .collection('Trips')
                              .where('group_id', isEqualTo: groupId)
                              .snapshots(),
                          builder: (context, tripSnapshot) {
                            if (tripSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFA07B4F),
                                ),
                              );
                            }

                            // دمج البيانات
                            Map<String, Map<String, dynamic>> finalTrips = {};

                            if (templateSnapshot.hasData) {
                              for (var doc in templateSnapshot.data!.docs) {
                                if (doc.id == 'other') continue;

                                finalTrips[doc.id] = {
                                  'template_id': doc.id,
                                  'title': doc['title'],
                                  'is_placeholder': true,
                                  'order': doc['order'] ?? 99,
                                };
                              }
                            }

                            if (tripSnapshot.hasData) {
                              for (var doc in tripSnapshot.data!.docs) {
                                var data = doc.data() as Map<String, dynamic>;
                                String tId = data['template_id'] ?? 'other';

                                if (tId == 'other') {
                                  finalTrips[doc.id] = {
                                    ...data,
                                    'is_placeholder': false,
                                    'order': 100,
                                  };
                                } else {
                                  finalTrips[tId] = {
                                    ...data,
                                    'is_placeholder': false,
                                    'order': finalTrips[tId]?['order'] ?? 99,
                                  };
                                }
                              }
                            }

                            var trips = finalTrips.values.toList();

                            // 🌟 الترتيب الجديد الذكي 🌟
                            trips.sort((a, b) {
                              bool isPlaceholderA =
                                  a['is_placeholder'] ?? false;
                              bool isPlaceholderB =
                                  b['is_placeholder'] ?? false;

                              // 1. الأولوية: الرحلات الفعالة (الكارد الكبير) تظهر فوق المجدولة
                              if (!isPlaceholderA && isPlaceholderB) return -1;
                              if (isPlaceholderA && !isPlaceholderB) return 1;

                              // 2. إذا كانوا نفس النوع، نرتبهم حسب تسلسل الرحلة (order)
                              int orderA = a['order'] as int? ?? 99;
                              int orderB = b['order'] as int? ?? 99;
                              return orderA.compareTo(orderB);
                            });

                            if (trips.isEmpty) return _buildEmptyState();

                            return ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              itemCount: trips.length,
                              itemBuilder: (context, index) {
                                return _buildPilgrimTripCard(
                                  context,
                                  trips[index],
                                  userId ?? '',
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 30, bottom: 20),
      child: Column(
        children: [
          const Text(
            'رحلاتي',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 1,
            width: 150,
            color: const Color(0xFFA07B4F).withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildPilgrimTripCard(
    BuildContext context,
    Map<String, dynamic> tripData,
    String currentPilgrimId,
  ) {
    bool isPlaceholder = tripData['is_placeholder'] ?? false;

    // 🌟 الكارد الصغير للمسودات 🌟
    if (isPlaceholder) {
      String title = tripData['title'] ?? 'وجهة مجدولة';
      return Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white12, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'رحلة مجدولة - بانتظار تحديد الباص',
                  style: TextStyle(color: Color(0xFFA07B4F), fontSize: 12),
                ),
              ],
            ),
            const SizedBox(width: 15),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black26,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white12),
              ),
              child: const Icon(
                Icons.schedule,
                color: Colors.white38,
                size: 22,
              ),
            ),
          ],
        ),
      );
    }

    // 🌟 الكارد الكبير للرحلات الفعالة 🌟
    Timestamp? scheduledAt = tripData['scheduled_at'];
    String timeString = "غير محدد", dateString = "غير محدد";
    String supervisorId = tripData['created_by'] ?? '';

    if (scheduledAt != null) {
      DateTime dt = scheduledAt.toDate();
      timeString = DateFormat(
        'hh:mm a',
      ).format(dt).replaceAll('AM', 'صباحًا').replaceAll('PM', 'مساءً');
      dateString = DateFormat('yyyy/MM/dd').format(dt);
    }

    String status = tripData['status'] ?? 'scheduled';
    String busId = tripData['bus_id'] ?? '-';
    String templateId = tripData['template_id'] ?? '';

    String destination = "غير محدد";
    if (templateId == 'other') {
      destination = tripData['custom_destination'] ?? 'وجهة مخصصة';
    } else if (templateId.contains('mina_to_arafat')) {
      destination = "عرفة";
    } else if (templateId.contains('arafat_to_muzdalifa')) {
      destination = "مزدلفة";
    } else if (templateId.contains('muzdalifa_to_mina')) {
      destination = "منى";
    }

    List<Color> gradientColors;
    Color borderColor;
    String statusText;
    if (status == 'active') {
      gradientColors = [const Color(0xFF384333), const Color(0xFF232B1F)];
      borderColor = Colors.green.withOpacity(0.3);
      statusText = 'بدأ التصعيد';
    } else if (status == 'completed') {
      gradientColors = [const Color(0xFF1E2430), const Color(0xFF10141C)];
      borderColor = Colors.blue.withOpacity(0.3);
      statusText = 'انتهى التصعيد';
    } else {
      gradientColors = [const Color(0xFF332A1D), const Color(0xFF1F1910)];
      borderColor = const Color(0xFFA07B4F).withOpacity(0.3);
      statusText = 'لم يتم التصعيد';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => _openGoogleMaps(context, tripData),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'موقع الباص',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(height: 1.5, width: 70, color: Colors.white30),
                      const SizedBox(width: 10),
                      const Text(
                        'معلومات الرحلة',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _buildTripDataRow(Icons.map_outlined, 'إلى : $destination'),
                  _buildTripDataRow(
                    Icons.calendar_month_outlined,
                    'تاريخ الإنطلاق : $dateString',
                  ),
                  _buildTripDataRow(
                    Icons.access_time,
                    'موعد الإنطلاق : $timeString',
                  ),
                  _buildTripDataRow(
                    Icons.directions_bus_outlined,
                    'رقم الباص : $busId',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (supervisorId.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              height: 1,
              width: double.infinity,
              color: Colors.white.withOpacity(0.1),
            ),
            const SizedBox(height: 15),
            _buildSupervisorInfo(context, supervisorId, currentPilgrimId),
          ],
        ],
      ),
    );
  }

  Widget _buildSupervisorInfo(
    BuildContext context,
    String supervisorId,
    String currentPilgrimId,
  ) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('Users')
          .doc(supervisorId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        var data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        String name = data['info']?['name'] ?? 'مشرف الرحلة';

        return Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFA07B4F).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.chat_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () {
                  String chatId = '${supervisorId}_$currentPilgrimId';
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        chatId: chatId,
                        otherUserName: name,
                        currentUserId: currentPilgrimId,
                      ),
                    ),
                  );
                },
              ),
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'مشرف الباص',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline,
                color: Colors.white70,
                size: 20,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTripDataRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
          const SizedBox(width: 8),
          Icon(icon, color: const Color(0xFFA07B4F).withOpacity(0.9), size: 16),
        ],
      ),
    );
  }

  Future<void> _openGoogleMaps(
    BuildContext context,
    Map<String, dynamic> tripData,
  ) async {
    double? lat = tripData['bus_lat'], lng = tripData['bus_lng'];
    if (lat == null || lng == null) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لم يتم تحديث موقع الحافلة لهذه الرحلة حتى الآن.'),
            backgroundColor: Colors.orange,
          ),
        );
      return;
    }
    try {
      final Uri url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      );
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء فتح الخريطة.'),
            backgroundColor: Colors.redAccent,
          ),
        );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_bus_filled_outlined,
            color: Colors.white.withOpacity(0.2),
            size: 80,
          ),
          const SizedBox(height: 15),
          const Text(
            'لا توجد رحلات مجدولة لمجموعتك حالياً',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
