import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

// =============================================================
// الجزء 1: دوال جلب البيانات (هنا سيتم الربط مع الـ API الخاص بكِ)
// =============================================================

// 🟢 دالة حساب المسافة: ستحتاجين مستقبلاً لجلب إحداثيات (الجمرات) من قاعدة البيانات بدل كتابتها يدوياً
Future<String> calculateDistanceToJamarat() async {
  try {
    // 🚩 BACK-END NOTE: هذه الإحداثيات ثابتة الآن، مستقبلاً قد تأتي من API حسب موقع المخيم
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
    return "2.1 km"; // قيمة احتياطية في حال فشل الحساب
  }
}

// 🟢 دالة الطقس: تستخدم حالياً API خارجي
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

// 🟢 دالة مواقيت الصلاة
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
// الجزء 2: واجهة المستخدم الرئيسية (HomeScreen)
// =============================================================

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // 🖼️ دالة إظهار الخريطة المنبثقة (Pop-up)
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
    return Scaffold(
      backgroundColor: Colors.black, // الثيم الغامق للبرنامج
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/black.png'), // خلفية الشاشة الكاملة
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.end, // محاذاة العناصر لليمين (عربي)
              children: [
                const SizedBox(height: 20),
                // 🚩 BACK-END NOTE: هنا يتم استبدال "أحمد" و "صالح" بمتغيرات تأتي من بيانات تسجيل دخول المستخدم
                const Text(
                  'أهلاً أحمد 👋',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'اسم المشرف المسؤول: صالح ياسر الشهري',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),

                const SizedBox(height: 30),
                _buildQRCodeSection(), // استدعاء قسم الـ QR

                const SizedBox(height: 30),
                _buildSectionTitle('معلومات التسكين'),
                const SizedBox(height: 15),

                // قائمة كروت التسكين (Scroll أفقي)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Row(
                    children: [
                      // 🚩 BACK-END NOTE: هذه الكروت يجب أن تُبنى باستخدام ListView.builder بناءً على مصفوفة بيانات الحاج
                      _buildInfoCard(context, 'مزدلفة', '15', 'أ-4'),
                      _buildInfoCard(context, 'عرفة', '20', '16'),
                      _buildInfoCard(context, 'منى', '913', '13'),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
                _buildSectionTitle('خدمات إضافية'),
                const SizedBox(height: 15),
                _buildServicesGrid(
                  context,
                ), // شبكة الخدمات (صلاة، طقس، مسافة، قبلة)
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // 🛠️ بناء كارد معلومات التسكين
  Widget _buildInfoCard(
    BuildContext context,
    String masher,
    String hall,
    String location,
  ) {
    return Container(
      width: 160,
      height: 160,
      margin: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: AssetImage('assets/card.png'), // خلفية الكارد
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
            _buildTextRow('الموقع:', location),
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

  // 🛠️ بناء شبكة الخدمات الإضافية
  Widget _buildServicesGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.0,
      children: [
        // كارد الصلاة (بيانات حية)
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
              'assets/card.png',
            );
          },
        ),
        // كارد الطقس (بيانات حية)
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
              'assets/card.png',
            );
          },
        ),
        // كارد المسافة (بيانات حية من الـ GPS)
        FutureBuilder<String>(
          future: calculateDistanceToJamarat(),
          builder: (context, snapshot) {
            return _serviceItem(
              'المسافة',
              snapshot.hasData ? snapshot.data! : '...',
              'إلى الجمرات',
              Icons.straighten,
              'assets/card.png',
            );
          },
        ),
        // كارد القبلة (انتقال لشاشة أخرى)
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
            'assets/card.png',
          ),
        ),
      ],
    );
  }

  // 🛠️ بناء عنصر الخدمة المنفرد
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

  // 🛠️ بناء صف نصي (Label: Value)
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

  // 🛠️ عنوان الأقسام
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

  // 🛠️ قسم الـ QR Code
  Widget _buildQRCodeSection() {
    return Center(
      child: Column(
        children: [
          const Text(
            'الرمز الخاص بي',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            // 🚩 BACK-END NOTE: هنا يجب تمرير معرف الحاج الفريد (User ID) في رابط الـ QR
            child: Image.network(
              'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=User123',
              width: 200,
              height: 200,
            ),
          ),
        ],
      ),
    );
  }

  // 🛠️ البار السفلي (Navigation Bar)
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
      child: Container(
        height: 65,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E).withOpacity(0.95),
          borderRadius: BorderRadius.circular(35),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const Icon(Icons.person_outline, color: Colors.white54),
            const Icon(Icons.directions_bus_outlined, color: Colors.white54),
            const Icon(Icons.chat_bubble_outline, color: Colors.white54),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFA07B4F),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.home, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// الجزء 3: شاشة القبلة (QiblaScreen)
// =============================================================

// (ملاحظة: شاشة القبلة تعتمد كلياً على حساسات الجهاز والـ GPS ولا تحتاج باك اند غالباً)
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
    _checkPermission(); // طلب الإذن عند فتح الشاشة
  }

  // دالة التأكد من صلاحيات الموقع
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

                // تفعيل الاهتزاز عند الوصول للقبلة الصحيحة
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

// رسام البوصلة (الدوائر والخطوط)
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
      canvas.rotate(0.785); // 45 درجة
      canvas.translate(-center.dx, -center.dy);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
