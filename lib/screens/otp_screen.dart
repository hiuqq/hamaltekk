import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class OtpScreen extends StatefulWidget {
  final String actualOtp;
  final String userType;
  final String email;
  final String password; // 🌟 استقبال الباسورد
  final String refNo; // 🌟 استقبال رقم التصريح

  const OtpScreen({
    super.key,
    required this.actualOtp,
    required this.userType,
    required this.email,
    required this.password,
    required this.refNo,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  List<String> otpValues = ["", "", "", ""];
  Timer? _timer;
  int _start = 110;
  bool isLoading = false; // 🌟 حالة التحميل أثناء إنشاء الحساب الفعلي

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _start = 110;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        timer.cancel();
        setState(() {});
      } else {
        setState(() => _start--);
      }
    });
  }

  // ==========================================
  // 🌟 دالة التحقق وإنشاء الحساب الفعلي 🌟
  // ==========================================
  Future<void> _verifyOtp() async {
    String enteredOtp = otpValues.join();

    if (enteredOtp != widget.actualOtp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الكود غير صحيح، حاول مرة أخرى')),
      );
      return;
    }

    // إذا الكود صحيح، نبدأ عملية إنشاء الحساب
    setState(() => isLoading = true);

    try {
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        print("⚠️ تنبيه: فشل جلب التوكن");
      }

      Map<String, dynamic> infoData = {};
      String? assignedGroupId;

      // --- 1. جلب بيانات الحاج وتعيين المجموعة ---
      if (widget.userType == 'p') {
        var nuskDoc = await FirebaseFirestore.instance
            .collection('Nusk')
            .doc(widget.refNo)
            .get();
        infoData = nuskDoc.data() ?? {};

        var groupsSnapshot = await FirebaseFirestore.instance
            .collection('Groups')
            .get();
        for (var doc in groupsSnapshot.docs) {
          var data = doc.data();
          if ((data['current_count'] ?? 0) < (data['max_capacity'] ?? 0)) {
            assignedGroupId = doc.id;
            await doc.reference.update({
              'current_count': FieldValue.increment(1),
            });
            break;
          }
        }
      }
      // --- 2. جلب بيانات الموظف وتجهيز المهام ---
      else if (widget.userType == 's') {
        var staffDoc = await FirebaseFirestore.instance
            .collection('Staff')
            .doc(widget.refNo)
            .get();
        infoData = staffDoc.data() ?? {};

        Map<String, dynamic> activeHajjTasks = {};
        var templates = staffDoc.data()?['task_templates'];
        if (templates != null && templates is Map) {
          templates.forEach((dayKey, taskList) {
            if (taskList is List) {
              activeHajjTasks[dayKey] = taskList
                  .map(
                    (title) => {
                      'title': title.toString(),
                      'is_completed': false,
                    },
                  )
                  .toList();
            }
          });
        }
        infoData['active_hajj_tasks'] = activeHajjTasks;

        var groupQuery = await FirebaseFirestore.instance
            .collection('Groups')
            .where('sup_id', isEqualTo: widget.refNo)
            .limit(1)
            .get();
        if (groupQuery.docs.isNotEmpty) {
          assignedGroupId = groupQuery.docs.first.id;
        }
      }

      // --- 3. إنشاء حساب المستخدم في Firebase Auth ---
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: widget.email,
            password: widget.password,
          );

      String uid = userCredential.user!.uid;

      // --- 4. حفظ البيانات في Firestore (جدول Users) ---
      await FirebaseFirestore.instance.collection('Users').doc(uid).set({
        'uid': uid,
        'email': widget.email,
        'type': widget.userType,
        'refNo': widget.refNo,
        'info': infoData,
        'group_id': assignedGroupId,
        'fcm_token': fcmToken,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // --- 5. النجاح والتحويل للشاشة المناسبة ---
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم التحقق وإنشاء الحساب بنجاح! 🎉')),
        );

        if (widget.userType == 's') {
          Navigator.pushReplacementNamed(context, '/staff_main');
        } else {
          Navigator.pushReplacementNamed(context, '/main');
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ في إنشاء الحساب: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('حدث خطأ غير متوقع: $e')));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // دالة لتشفير الإيميل (مثال: d*****@gmail.com)
  String _maskEmail(String email) {
    if (!email.contains('@')) return email;
    var parts = email.split('@');
    var name = parts[0];
    if (name.isEmpty) return email;
    return '${name[0]}*****@${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double topSectionHeight = size.height * 0.30;
    final double kaabaHeight = size.height * 0.75;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF1A1A1A),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topSectionHeight,
            child: Image.asset(
              'assets/black.png',
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.5),
            ),
          ),
          Positioned(
            top: topSectionHeight * 0.6,
            left: 0,
            right: 0,
            child: const Center(
              child: Text(
                'تأكيد البريد الإلكتروني',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'IBMPlexSans',
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: kaabaHeight,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(45),
                  topRight: Radius.circular(45),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset('assets/kaaba.png', fit: BoxFit.cover),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.6),
                              Colors.black.withOpacity(0.8),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 40,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const SizedBox(height: 20),
                            const Text(
                              'أدخل رمز التحقق',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'IBMPlexSans',
                              ),
                            ),
                            const SizedBox(height: 25),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(
                                4,
                                (index) => _otpBox(context, index),
                              ),
                            ),
                            const SizedBox(height: 35),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTimerBox(),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'لقد أرسلنا رمز الدخول إلى بريدك',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                        fontFamily: 'IBMPlexSans',
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _maskEmail(widget.email),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'IBMPlexSans',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                GestureDetector(
                                  onTap: _start == 0
                                      ? () {
                                          _startTimer();
                                          // اختياري: يمكنك هنا استدعاء API إرسال الرمز مرة أخرى
                                        }
                                      : null,
                                  child: Text(
                                    'أعد الإرسال',
                                    style: TextStyle(
                                      color: _start == 0
                                          ? Colors.white
                                          : Colors.white38,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'IBMPlexSans',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  'لم يصلك الرمز؟',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontFamily: 'IBMPlexSans',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                            // 🌟 عرض مؤشر التحميل أو زر التحقق بناءً على الحالة
                            isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF6B4E31),
                                    ),
                                  )
                                : _buildSolidButton('تحقق', _verifyOtp),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _otpBox(BuildContext context, int index) {
    return Container(
      height: 70,
      width: 60,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white54, width: 1),
      ),
      child: TextField(
        textAlign: TextAlign.center,
        maxLength: 1,
        keyboardType: TextInputType.number,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w400,
        ),
        onChanged: (v) {
          otpValues[index] = v;

          if (v.isNotEmpty) {
            if (index < 3) {
              FocusScope.of(context).nextFocus();
            } else {
              FocusScope.of(context).unfocus();
            }
          } else {
            if (index > 0) {
              FocusScope.of(context).previousFocus();
            }
          }
        },
        decoration: const InputDecoration(
          counterText: "",
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildTimerBox() {
    int min = _start ~/ 60;
    int sec = _start % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Text(
        '$min:${sec.toString().padLeft(2, '0')}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
          fontFamily: 'IBMPlexSans',
        ),
      ),
    );
  }

  Widget _buildSolidButton(String title, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6B4E31),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontFamily: 'IBMPlexSans',
          ),
        ),
      ),
    );
  }
}
