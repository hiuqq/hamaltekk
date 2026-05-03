import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hamaltekk/screens/chat_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  bool isProcessing = false;

  // دالة ذكية لتنظيف النصوص وعرض الأرقام فقط
  String _formatValue(dynamic value) {
    if (value == null) return '-';
    String str = value.toString();
    // تحذف النصوص المتوقعة وتبقي الرقم
    return str.replaceAll(RegExp(r'[a-zA-Z_]'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'مسح بطاقة الحاج',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              if (isProcessing) return;
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _handleScannedData(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFA07B4F), width: 2),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleScannedData(String uid) async {
    setState(() => isProcessing = true);
    try {
      cameraController.stop();
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .get();

      if (userDoc.exists &&
          (userDoc.data() as Map<String, dynamic>)['type'] == 'p') {
        if (!mounted) return;
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => _buildPilgrimCardBottomSheet(
            userDoc.data() as Map<String, dynamic>,
            uid,
          ),
        );
      } else {
        _showStatus('عذراً، هذا الرمز لا يخص حاج مسجل.');
      }
    } catch (e) {
      _showStatus('فشل في قراءة البيانات، تأكد من اتصالك.');
    } finally {
      setState(() => isProcessing = false);
      cameraController.start();
    }
  }

  Widget _buildPilgrimCardBottomSheet(
    Map<String, dynamic> pilgrimData,
    String pilgrimUid,
  ) {
    String name = pilgrimData['info']?['name'] ?? 'غير معروف';
    String phone = pilgrimData['info']?['phone'] ?? '';

    // تنظيف رقم المجموعة
    String groupId = _formatValue(pilgrimData['group_id']);

    Map<String, dynamic>? mina = pilgrimData['housing_mina'];
    Map<String, dynamic>? arafat = pilgrimData['housing_arafat'];
    Map<String, dynamic>? muzdalifa = pilgrimData['housing_muzdalifa'];

    String bloodType = pilgrimData['info']?['b_type'] ?? '-';

    List disList = pilgrimData['info']?['dis'] ?? [];
    List devList = pilgrimData['info']?['dev'] ?? [];
    var cleanDis = disList
        .where((e) => e.toString().trim().isNotEmpty)
        .toList();
    var cleanDev = devList
        .where((e) => e.toString().trim().isNotEmpty)
        .toList();

    bool isHealthy = cleanDis.isEmpty && cleanDev.isEmpty;
    String healthNote = isHealthy
        ? "سليم (لا توجد أمراض أو أجهزة مسجلة)"
        : "${cleanDis.join('، ')} ${cleanDev.isNotEmpty ? '- أجهزة: ${cleanDev.join('، ')}' : ''}";

    String supervisorId = pilgrimData['created_by'] ?? '';
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(35),
          topRight: Radius.circular(35),
        ),
        border: Border(top: BorderSide(color: Color(0xFFA07B4F), width: 1.5)),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(name, groupId),
              const SizedBox(height: 20),

              _buildHousingTile("منى ", mina),
              const SizedBox(height: 10),
              _buildHousingTile("عرفة ", arafat),
              const SizedBox(height: 10),
              _buildHousingTile("مزدلفة ", muzdalifa),

              const SizedBox(height: 20),
              _buildHealthCard(bloodType, healthNote, isHealthy),
              const SizedBox(height: 20),
              _buildSupervisorInfo(supervisorId, currentUserId),
              const SizedBox(height: 30),
              _buildActionButtons(currentUserId, pilgrimUid, name, phone),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String name, String groupId) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 25,
          backgroundColor: Color(0xFF2D231E),
          child: Icon(Icons.person, color: Color(0xFFA07B4F)),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'المجموعة: $groupId',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHousingTile(String title, Map<String, dynamic>? data) {
    if (data == null) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFA07B4F),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "الصالة: ${_formatValue(data['hall'])}",
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                "الغرفة: ${_formatValue(data['room'])}",
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                "السرير: ${_formatValue(data['bed'])}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthCard(String blood, String note, bool isHealthy) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isHealthy
            ? Colors.green.withOpacity(0.05)
            : Colors.redAccent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isHealthy
              ? Colors.green.withOpacity(0.2)
              : Colors.redAccent.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.favorite,
                color: isHealthy ? Colors.green : Colors.redAccent,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                'فصيلة الدم: $blood',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            note,
            style: TextStyle(
              color: isHealthy ? Colors.green : Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupervisorInfo(String supId, String currentId) {
    if (supId.isEmpty) return const SizedBox();
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('Users').doc(supId).get(),
      builder: (context, snapshot) {
        String supName = snapshot.data?['info']?['name'] ?? '...';
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              const Icon(Icons.security, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'المشرف العام: $supName',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.chat_outlined,
                  color: Color(0xFFA07B4F),
                  size: 22,
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      chatId: '${supId}_$currentId',
                      otherUserName: supName,
                      currentUserId: currentId,
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

  Widget _buildActionButtons(
    String currentId,
    String pUid,
    String name,
    String phone,
  ) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  chatId: '${currentId}_$pUid',
                  otherUserName: name,
                  currentUserId: currentId,
                ),
              ),
            ),
            icon: const Icon(Icons.message_rounded, size: 18),
            label: const Text('محادثة الحاج'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA07B4F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        if (phone.isNotEmpty) ...[
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => launchUrl(Uri.parse('tel:$phone')),
              icon: const Icon(Icons.phone_enabled, color: Colors.green),
            ),
          ),
        ],
      ],
    );
  }

  void _showStatus(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
