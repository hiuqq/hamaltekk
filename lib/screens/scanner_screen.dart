import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScannerScreen extends StatefulWidget {
  final String tripId;

  const ScannerScreen({super.key, required this.tripId});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool isScanning = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true, // 🌟 الكاميرا تأخذ الشاشة كاملة
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'مسح كود الحاج',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // 1. الكاميرا بكامل الشاشة
          MobileScanner(
            fit: BoxFit
                .cover, // 🌟 يمنع ظهور حواف سوداء وتمدد الكاميرا بشكل طبيعي
            onDetect: (capture) async {
              if (!isScanning) return;

              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  setState(() => isScanning = false);
                  String pilgrimId = barcode.rawValue!;

                  await _processScannedPilgrim(pilgrimId);
                  break;
                }
              }
            },
          ),

          // 2. مربع التحديد الذهبي
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: const Color(0xFFA07B4F), width: 3),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 50,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),

          // 3. نص إرشادي
          const Positioned(
            bottom: 80,
            child: Text(
              'ضع الباركود داخل المربع',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black, blurRadius: 10)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🌟 دالة معالجة الحاج وتحديث الداتابيس في مسار الرحلة (Manifest)
  Future<void> _processScannedPilgrim(String pilgrimId) async {
    _showFeedback('جاري التحقق...', Colors.blueGrey);

    try {
      // نبحث عن الحاج داخل قائمة ركاب هذه الرحلة تحديداً
      var manifestRef = FirebaseFirestore.instance
          .collection('Trips')
          .doc(widget.tripId)
          .collection('manifest')
          .doc(pilgrimId);

      var doc = await manifestRef.get();

      if (doc.exists) {
        // الحاج مسجل في هذه الرحلة -> نحدث حالته إلى "تم التصعيد"
        await manifestRef.update({
          'status': 'boarded',
          'scanned_at': FieldValue.serverTimestamp(), // توقيت المسح
        });

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          _showFeedback('تم تصعيد الحاج بنجاح ✅', Colors.green);
          Navigator.pop(context); // الرجوع لشاشة الرحلة تلقائياً
        }
      } else {
        // الحاج غير مسجل في هذه الرحلة
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showFeedback('عذراً، هذا الحاج غير مسجل في هذه الرحلة ❌', Colors.red);
        setState(
          () => isScanning = true,
        ); // إعادة تشغيل الكاميرا للمحاولة مرة أخرى
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showFeedback('حدث خطأ في الاتصال ⚠️', Colors.orange);
      setState(() => isScanning = true);
    }
  }

  // 🌟 دالة الإشعارات العائمة الاحترافية
  void _showFeedback(String msg, Color color) {
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
        margin: const EdgeInsets.only(bottom: 50, left: 20, right: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
