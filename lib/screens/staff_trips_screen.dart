import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hamaltekk/screens/scanner_screen.dart';
import 'package:hamaltekk/screens/pilgrims_boarding_screen.dart';
import 'package:hamaltekk/widgets/add_trip_dialog.dart';
import 'package:intl/intl.dart' hide TextDirection;

class StaffTripsScreen extends StatefulWidget {
  const StaffTripsScreen({super.key});

  @override
  State<StaffTripsScreen> createState() => _StaffTripsScreenState();
}

class _StaffTripsScreenState extends State<StaffTripsScreen> {
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
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
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (context) => const AddTripDialog(),
                      ),
                    ),
                    const Text(
                      'رحلاتي',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('Trips')
                      .orderBy('scheduled_at', descending: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFA07B4F),
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _buildEmptyState();
                    }

                    var trips = snapshot.data!.docs;

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      itemCount: trips.length,
                      itemBuilder: (context, index) {
                        var doc = trips[index];
                        var tripData = doc.data() as Map<String, dynamic>;
                        return ExpandableTripCard(
                          tripId: doc.id,
                          tripData: tripData,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.directions_bus_outlined, size: 80, color: Colors.white24),
          SizedBox(height: 20),
          Text(
            'لا توجد رحلات مجدولة حالياً',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
          SizedBox(height: 10),
          Text(
            'اضغط على (+) لإضافة رحلة جديدة',
            style: TextStyle(color: Color(0xFFA07B4F), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class ExpandableTripCard extends StatefulWidget {
  final String tripId;
  final Map<String, dynamic> tripData;

  const ExpandableTripCard({
    super.key,
    required this.tripId,
    required this.tripData,
  });

  @override
  State<ExpandableTripCard> createState() => _ExpandableTripCardState();
}

class _ExpandableTripCardState extends State<ExpandableTripCard> {
  bool isExpanded = false;

  void _showCustomSnackBar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // 🌟 الدالة المعدلة: تحفظ حالة الرحلة مع تسجيل وقت البداية والنهاية للتقرير
  Future<void> _updateTripStatus(String newStatus) async {
    try {
      Map<String, dynamic> updateData = {'status': newStatus};

      // 🌟 تسجيل أوقات التصعيد (Start/End time) في الفايربيس بمجرد تغيير الحالة
      if (newStatus == 'active') {
        updateData['start_time'] = FieldValue.serverTimestamp();
      } else if (newStatus == 'completed') {
        updateData['end_time'] = FieldValue.serverTimestamp();
      }

      // 1. التحديث في قاعدة البيانات
      await FirebaseFirestore.instance
          .collection('Trips')
          .doc(widget.tripId)
          .update(updateData);

      // 2. تشغيل الأتمتة
      await _sendAutomatedSystemMessage(newStatus);

      _showCustomSnackBar(
        'تم تحديث الحالة وإرسال الإشعارات بنجاح ✅',
        Colors.green,
      );
    } catch (e) {
      _showCustomSnackBar('حدث خطأ أثناء التحديث', Colors.red);
    }
  }

  Future<void> _sendAutomatedSystemMessage(String newStatus) async {
    final String? supervisorId = FirebaseAuth.instance.currentUser?.uid;
    if (supervisorId == null) return;

    final firestore = FirebaseFirestore.instance;
    String messageText = '';

    if (newStatus == 'active') {
      messageText =
          '🚌 إشعار نظام: بدأت الرحلة الآن، نرجو التوجه للحافلة فوراً.';
    } else if (newStatus == 'completed') {
      messageText = '✅ إشعار نظام: انتهت الرحلة بسلام، تقبل الله طاعتكم.';
    } else {
      return;
    }

    try {
      var manifestSnapshot = await firestore
          .collection('Trips')
          .doc(widget.tripId)
          .collection('manifest')
          .get();

      if (manifestSnapshot.docs.isEmpty) return;

      WriteBatch batch = firestore.batch();

      for (var doc in manifestSnapshot.docs) {
        String pilgrimId = doc.id;
        String chatId = '${supervisorId}_$pilgrimId';

        var messageRef = firestore
            .collection('Chats')
            .doc(chatId)
            .collection('messages')
            .doc();

        batch.set(messageRef, {
          'text': messageText,
          'sender_id': supervisorId,
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'system_alert',
        });

        var chatRef = firestore.collection('Chats').doc(chatId);
        batch.set(chatRef, {
          'last_message': messageText,
          'last_time': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await batch.commit();
      print('🚀 تم إرسال رسائل النظام الأوتوماتيكية بنجاح');
    } catch (e) {
      print('🚨 حدث خطأ في الأتمتة: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    Timestamp? scheduledAt = widget.tripData['scheduled_at'];
    String timeString = "غير محدد";
    String dateString = "غير محدد";

    if (scheduledAt != null) {
      DateTime dt = scheduledAt.toDate();
      timeString = DateFormat('hh:mm a').format(dt);
      dateString = DateFormat('yyyy/MM/dd').format(dt);
    }

    String currentStatus = widget.tripData['status'] ?? 'scheduled';
    String statusText = currentStatus == 'scheduled'
        ? 'لم يتم التصعيد'
        : currentStatus == 'active'
        ? 'يتم التصعيد'
        : 'انتهى التصعيد';
    String destinationName = widget.tripData['template_id'] == 'mina_to_arafat'
        ? 'التفويج إلى عرفة'
        : widget.tripData['template_id'];

    return GestureDetector(
      onTap: () {
        setState(() {
          isExpanded = !isExpanded;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4A3B32), Color(0xFF2D231E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isExpanded
                ? const Color(0xFFA07B4F)
                : const Color(0xFFA07B4F).withOpacity(0.3),
            width: isExpanded ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'معلومات الرحلة',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(color: Colors.white24, height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    const Text(
                      'موقع الباص',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    const SizedBox(height: 5),
                    GestureDetector(
                      onTap: () async {
                        String busId = widget.tripData['bus_id'];
                        var busDoc = await FirebaseFirestore.instance
                            .collection('Buses')
                            .doc(busId)
                            .get();

                        if (busDoc.exists &&
                            busDoc.data()!.containsKey('location')) {
                          GeoPoint loc = busDoc['location'];
                          final Uri url = Uri.parse(
                            'https://www.google.com/maps/search/?api=1&query=${loc.latitude},${loc.longitude}',
                          );
                          if (!await launchUrl(url)) {
                            _showCustomSnackBar(
                              'لا يمكن فتح تطبيق الخرائط',
                              Colors.red,
                            );
                          }
                        } else {
                          _showCustomSnackBar(
                            'موقع الباص غير متوفر حالياً',
                            Colors.orange,
                          );
                        }
                      },
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),

                    if (isExpanded) ...[
                      const SizedBox(height: 15),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.white,
                          size: 26,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ScannerScreen(tripId: widget.tripId),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 15),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Colors.white,
                          size: 26,
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AddTripDialog(
                              tripId: widget.tripId,
                              initialData: widget.tripData,
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildDetailRow('إلى', destinationName),
                      if (!isExpanded) const SizedBox(height: 8),
                      if (!isExpanded)
                        _buildDetailRow('تاريخ الانطلاق', dateString),
                      const SizedBox(height: 8),
                      _buildDetailRow('موعد الانطلاق', timeString),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        'رقم الباص',
                        widget.tripData['bus_id'] ?? '-',
                      ),
                      const SizedBox(height: 8),
                      if (!isExpanded)
                        _buildDetailRow(
                          'حالة التصعيد',
                          statusText,
                          valueColor: const Color(0xFFA07B4F),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            if (isExpanded) ...[
              const SizedBox(height: 5),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 10),

              const Text(
                'حالة التصعيد :',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),

              Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  children: [
                    _buildRadioOption(
                      'لم يتم التصعيد',
                      'scheduled',
                      currentStatus,
                    ),
                    _buildRadioOption(
                      'يتم التصعيد (نشطة)',
                      'active',
                      currentStatus,
                    ),
                    _buildRadioOption(
                      'انتهى التصعيد',
                      'completed',
                      currentStatus,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black38,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(
                        color: Color(0xFFA07B4F),
                        width: 1,
                      ),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PilgrimsBoardingScreen(tripId: widget.tripId),
                      ),
                    );
                  },
                  child: const Text(
                    'معلومات تصعيد الحجاج',
                    style: TextStyle(
                      color: Color(0xFFA07B4F),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRadioOption(String title, String value, String groupValue) {
    return InkWell(
      onTap: () => _updateTripStatus(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Row(
          children: [
            SizedBox(
              height: 28,
              width: 28,
              child: Radio<String>(
                value: value,
                groupValue: groupValue,
                activeColor: const Color(0xFFA07B4F),
                fillColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? const Color(0xFFA07B4F)
                      : Colors.white54,
                ),
                onChanged: (newValue) {
                  if (newValue != null) _updateTripStatus(newValue);
                },
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: groupValue == value ? Colors.white : Colors.white54,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color valueColor = Colors.white70,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          ' : $label',
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ],
    );
  }
}
