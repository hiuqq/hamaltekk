import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';

// =============================================================
// الجزء 1: دوال جلب البيانات
// =============================================================

Future<String> calculateDistanceToJamarat() async {
  try {
    const double jamaratLat = 21.4214;
    const double jamaratLon = 39.8727;

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    double distanceInMeters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      jamaratLat,
      jamaratLon,
    );

    double distanceInKm = distanceInMeters / 1000;
    return "${distanceInKm.toStringAsFixed(1)} km";
  } catch (e) {
    return "2.1 km";
  }
}

Future<Map<String, dynamic>> fetchWeather() async {
  const apiKey = '52a3c3c645f78d3902d69531818d958a';
  const lat = '21.4172';
  const lon = '39.8944';
  final url =
      'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=ar';
  try {
    final response = await http.get(Uri.parse(url));
    return response.statusCode == 200
        ? json.decode(response.body)
        : throw Exception();
  } catch (e) {
    throw Exception();
  }
}

Future<Map<String, dynamic>> fetchPrayerTimes() async {
  const lat = '21.4225';
  const lon = '39.8262';
  final url =
      'https://api.aladhan.com/v1/timings?latitude=$lat&longitude=$lon&method=4';
  try {
    final response = await http.get(Uri.parse(url));
    return response.statusCode == 200
        ? json.decode(response.body)
        : throw Exception();
  } catch (e) {
    throw Exception();
  }
}

// =============================================================
// الجزء 2: منطق التسكين الشامل للثلاث مشاعر
// =============================================================

class HousingService {
  static Future<void> autoAssignHousing() async {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final firestore = FirebaseFirestore.instance;

    var userDoc = await firestore.collection('Users').doc(userId).get();
    if (userDoc.exists && userDoc.data()!.containsKey('housing_mina')) return;

    try {
      List<String> camps = ['mina', 'arafat', 'muzdalifa'];
      Map<String, dynamic> userHousingData = {};

      for (String campId in camps) {
        var halls = await firestore
            .collection('camps')
            .doc(campId)
            .collection('halls')
            .get();
        bool assignedForThisCamp = false;

        for (var hall in halls.docs) {
          if (assignedForThisCamp) break;
          var rooms = await hall.reference.collection('rooms').get();

          for (var room in rooms.docs) {
            if (assignedForThisCamp) break;
            var beds = await room.reference
                .collection('beds')
                .where('is_available', isEqualTo: true)
                .limit(1)
                .get();

            if (beds.docs.isNotEmpty) {
              var selectedBed = beds.docs.first;

              await selectedBed.reference.update({
                'is_available': false,
                'user_id': userId,
              });

              String masherName = campId == 'mina'
                  ? 'منى'
                  : (campId == 'arafat' ? 'عرفة' : 'مزدلفة');

              userHousingData['housing_$campId'] = {
                'masher': masherName,
                'hall': hall.id,
                'room': room.id,
                'bed': selectedBed.id,
                'group_id': selectedBed.data()['group_id'],
              };

              assignedForThisCamp = true;
            }
          }
        }
      }

      if (userHousingData.isNotEmpty) {
        await firestore
            .collection('Users')
            .doc(userId)
            .set(userHousingData, SetOptions(merge: true));
      }
    } catch (e) {
      print("Housing Error: $e");
    }
  }
}

// =============================================================
// الجزء 3: الشاشة الرئيسية
// =============================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    HousingService.autoAssignHousing();
  }

  // دالة البحث عن المشرف بناءً على الـ group_id
  Future<String> fetchSupervisorFromDB(String? groupId) async {
    if (groupId == null) return "غير معين";
    try {
      var groupDoc = await FirebaseFirestore.instance
          .collection('Groups')
          .doc(groupId)
          .get();
      String? supIdInGroup = groupDoc.data()?['sup_id'];
      if (supIdInGroup == null) return "لم يتم تحديد رقم مشرف";

      var staffQuery = await FirebaseFirestore.instance
          .collection('Staff')
          .where('j_no', isEqualTo: supIdInGroup)
          .limit(1)
          .get();

      if (staffQuery.docs.isNotEmpty) {
        return staffQuery.docs.first.data()['name'] ?? "مشرف بدون اسم";
      } else {
        return "المشرف $supIdInGroup غير موجود";
      }
    } catch (e) {
      return "خطأ في الاتصال";
    }
  }

  String formatLabel(String rawId, String prefix, String replaceWith) {
    return rawId.replaceAll(prefix, replaceWith).replaceAll('_', ' ');
  }

  void _showMapDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(15),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFA07B4F), width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset('assets/map.png', fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Users')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFA07B4F)),
            );
          }

          var userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};

          String userName = userData['info']?['name'] ?? 'الحاج';
          String? groupId = userData['group_id'];

          return Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/black.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'أهلاً $userName 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    FutureBuilder<String>(
                      future: fetchSupervisorFromDB(groupId),
                      builder: (context, supSnapshot) {
                        String supName = supSnapshot.data ?? "جاري التحميل...";
                        return Text(
                          'اسم المشرف المسؤول: $supName',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 30),

                    // 🌟 تمرير الـ userId للباركود لضمان توافقه مع نظام المشرف
                    _buildQRCodeSection(userId ?? ''),

                    const SizedBox(height: 30),
                    _buildSectionTitle('معلومات التسكين'),
                    const SizedBox(height: 15),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Row(
                        children: [
                          if (userData.containsKey('housing_muzdalifa'))
                            _buildInfoCard(
                              context,
                              userData['housing_muzdalifa']['masher'] ??
                                  'مزدلفة',
                              formatLabel(
                                userData['housing_muzdalifa']['hall'] ?? '',
                                'hall_',
                                'صالة ',
                              ),
                              formatLabel(
                                userData['housing_muzdalifa']['room'] ?? '',
                                'room_',
                                'غرفة ',
                              ),
                              formatLabel(
                                userData['housing_muzdalifa']['bed'] ?? '',
                                'bed_',
                                'موقع ',
                              ),
                            )
                          else
                            _buildEmptyCard('مزدلفة'),

                          if (userData.containsKey('housing_arafat'))
                            _buildInfoCard(
                              context,
                              userData['housing_arafat']['masher'] ?? 'عرفة',
                              formatLabel(
                                userData['housing_arafat']['hall'] ?? '',
                                'hall_',
                                'صالة ',
                              ),
                              formatLabel(
                                userData['housing_arafat']['room'] ?? '',
                                'room_',
                                'غرفة ',
                              ),
                              formatLabel(
                                userData['housing_arafat']['bed'] ?? '',
                                'bed_',
                                'موقع ',
                              ),
                            )
                          else
                            _buildEmptyCard('عرفة'),

                          if (userData.containsKey('housing_mina'))
                            _buildInfoCard(
                              context,
                              userData['housing_mina']['masher'] ?? 'منى',
                              formatLabel(
                                userData['housing_mina']['hall'] ?? '',
                                'hall_',
                                'صالة ',
                              ),
                              formatLabel(
                                userData['housing_mina']['room'] ?? '',
                                'room_',
                                'غرفة ',
                              ),
                              formatLabel(
                                userData['housing_mina']['bed'] ?? '',
                                'bed_',
                                'موقع ',
                              ),
                            )
                          else
                            _buildEmptyCard('منى'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                    _buildSectionTitle('خدمات إضافية'),
                    const SizedBox(height: 15),
                    _buildServicesGrid(context),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Widgets ---

  // 🌟 تحديث سكشن الباركود ليستخدم QrImageView
  Widget _buildQRCodeSection(String qrData) {
    return Center(
      child: Column(
        children: [
          const Text(
            'رمز التصعيد الخاص بي',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFA07B4F),
                width: 2,
              ), // إطار ذهبي خفيف
            ),
            child: QrImageView(
              data: qrData, // الـ ID حق الحاج
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor:
                  Colors.white, // خلفية بيضاء عشان الكاميرا تقرأه بسرعة
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'أبرز هذا الرمز للمشرف عند صعود الحافلة',
            style: TextStyle(
              color: Color(0xFFA07B4F),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String masher,
    String hall,
    String room,
    String location,
  ) {
    return Container(
      width: 160,
      height: 180,
      margin: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: AssetImage('assets/card.png'),
          fit: BoxFit.cover,
          opacity: 0.8,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.black.withOpacity(0.3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTextRow('المشعر:', masher),
            const SizedBox(height: 4),
            _buildTextRow('الصالة:', hall),
            const SizedBox(height: 4),
            _buildTextRow('الغرفة:', room),
            const SizedBox(height: 4),
            _buildTextRow('السرير:', location),
            const Spacer(),
            GestureDetector(
              onTap: () => _showMapDialog(context),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'خريطة المشعر',
                    style: TextStyle(
                      color: Color(0xFFA07B4F),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.location_on, color: Color(0xFFA07B4F), size: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String title) {
    return Container(
      width: 160,
      height: 180,
      margin: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bed, color: Colors.white24, size: 30),
            const SizedBox(height: 8),
            Text(
              'جاري تخصيص $title',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.0,
      children: [
        FutureBuilder<Map<String, dynamic>>(
          future: fetchPrayerTimes(),
          builder: (context, snapshot) {
            return _serviceItem(
              'الظهر',
              snapshot.hasData
                  ? snapshot.data!['data']['timings']['Dhuhr']
                  : '--:--',
              'وقت صلاة الظهر',
              Icons.access_time,
              'assets/salah.png',
            );
          },
        ),
        FutureBuilder<Map<String, dynamic>>(
          future: fetchWeather(),
          builder: (context, snapshot) {
            return _serviceItem(
              'منى',
              snapshot.hasData
                  ? '${snapshot.data!['main']['temp'].round()}°'
                  : '--',
              'حالة الطقس',
              Icons.wb_sunny_outlined,
              'assets/weather.png',
            );
          },
        ),
        FutureBuilder<String>(
          future: calculateDistanceToJamarat(),
          builder: (context, snapshot) {
            return _serviceItem(
              'المسافة',
              snapshot.hasData ? snapshot.data! : '...',
              'إلى الجمرات',
              Icons.straighten,
              'assets/jamrat.png',
            );
          },
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QiblaScreen()),
          ),
          child: _serviceItem(
            'القبلة',
            'مكة',
            'حدد اتجاهك الآن',
            Icons.explore_outlined,
            'assets/qibla.png',
          ),
        ),
      ],
    );
  }

  Widget _serviceItem(
    String title,
    String val,
    String sub,
    IconData icon,
    String imagePath,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
          opacity: 0.7,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.black.withOpacity(0.4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: const Color(0xFFA07B4F), size: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  val,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  sub,
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                  maxLines: 1,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(height: 2, width: 40, color: const Color(0xFFA07B4F)),
      ],
    );
  }
}

// =============================================================
// الجزء 4: شاشة القبلة (QiblaScreen)
// =============================================================

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});
  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  bool hasPermission = false;
  bool isHapticFeedbackDone = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await FlutterQiblah.checkLocationStatus();
    if (status.status == LocationPermission.always ||
        status.status == LocationPermission.whileInUse) {
      setState(() => hasPermission = true);
    } else {
      await FlutterQiblah.requestPermissions();
      final retryStatus = await FlutterQiblah.checkLocationStatus();
      if (retryStatus.status == LocationPermission.always ||
          retryStatus.status == LocationPermission.whileInUse) {
        setState(() => hasPermission = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "بوصلة القبلة",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: !hasPermission
          ? const Center(
              child: Text(
                "يرجى تفعيل الموقع الجغرافي",
                style: TextStyle(color: Colors.white),
              ),
            )
          : StreamBuilder(
              stream: FlutterQiblah.qiblahStream,
              builder: (context, AsyncSnapshot<QiblahDirection> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFA07B4F)),
                  );
                }
                final qiblahDirection = snapshot.data!;
                final bool isAligned = qiblahDirection.offset.abs() < 5;

                if (isAligned && !isHapticFeedbackDone) {
                  HapticFeedback.heavyImpact();
                  isHapticFeedbackDone = true;
                } else if (!isAligned) {
                  isHapticFeedbackDone = false;
                }

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${qiblahDirection.direction.toInt()}°",
                        style: TextStyle(
                          color: isAligned ? Colors.green : Colors.white,
                          fontSize: 45,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 50),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 280,
                            height: 280,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white12,
                                width: 2,
                              ),
                            ),
                            child: CustomPaint(painter: CompassPainter()),
                          ),
                          Transform.rotate(
                            angle:
                                (qiblahDirection.qiblah * (math.pi / 180) * -1),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: isAligned
                                      ? Colors.green
                                      : const Color(0xFFA07B4F),
                                  size: 70,
                                ),
                                const SizedBox(height: 5),
                                const Icon(
                                  Icons.keyboard_arrow_up,
                                  color: Colors.white24,
                                  size: 40,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 50),
                      Text(
                        isAligned
                            ? "أنت تواجه القبلة الآن"
                            : "وجه رأس الجوال نحو القبلة",
                        style: TextStyle(
                          color: isAligned ? Colors.green : Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 2;
    final center = Offset(size.width / 2, size.height / 2);
    for (var i = 0; i < 8; i++) {
      canvas.drawLine(
        Offset(center.dx, center.dy - (size.width / 2) + 15),
        Offset(center.dx, center.dy - (size.width / 2)),
        paint,
      );
      canvas.translate(center.dx, center.dy);
      canvas.rotate(0.785);
      canvas.translate(-center.dx, -center.dy);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
