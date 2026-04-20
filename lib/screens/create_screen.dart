import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hamaltekk/models/user_model.dart';
import 'package:hamaltekk/screens/home_screen.dart';
import 'package:hamaltekk/screens/staff_home_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> _handleSignUp() async {
    final refNo = idController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (refNo.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackBar('يرجى ملء جميع الحقول');
      return;
    }

    setState(() => isLoading = true);

    try {
      print("🚀 بدء فحص الرقم: $refNo");

      // 1. التحقق من كولكشن الحجاج (Nusk)
      var nuskDoc = await FirebaseFirestore.instance
          .collection('Nusk')
          .doc(refNo)
          .get();

      String userType = '';
      Map<String, dynamic> infoData = {};
      Map<String, dynamic> activeHajjTasks = {}; // لتخزين المهام النشطة

      if (nuskDoc.exists) {
        userType = 'p'; // حاج
        infoData = nuskDoc.data()!;
        print("✅ تم العثور على حاج");
      } else {
        // 2. التحقق من كولكشن المشرفين (Staff)
        var staffDoc = await FirebaseFirestore.instance
            .collection('Staff')
            .doc(refNo)
            .get();

        if (staffDoc.exists) {
          userType = 's'; // مشرف
          infoData = staffDoc.data()!;
          print("✅ تم العثور على مشرف");

          // 🌟 سحب قوالب المهام وتحويلها لمهام نشطة (is_completed: false)
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
            print("📋 تم تجهيز ${activeHajjTasks.length} أيام من المهام");
          } else {
            print("⚠️ تنبيه: حقل task_templates غير موجود في ملف المشرف");
          }
        } else {
          _showSnackBar('رقم التصريح أو الرقم الوظيفي غير موجود');
          setState(() => isLoading = false);
          return;
        }
      }

      // 3. إنشاء الحساب في Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // 4. خوارزمية التعيين التلقائي للجروبات (للحجاج فقط)
      String? assignedGroupId;
      if (userType == 'p') {
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

      // 5. حفظ البيانات النهائية في كولكشن (Users)
      // ندمج المهام النشطة داخل حقل info للمشرف
      if (userType == 's') {
        infoData['active_hajj_tasks'] = activeHajjTasks;
      }

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userCredential.user!.uid)
          .set({
            'email': email,
            'type': userType,
            'refNo': refNo,
            'info': infoData,
            'group_id': assignedGroupId,
            'createdAt': Timestamp.now(),
          });

      print("✨ تم حفظ بيانات المستخدم بنجاح في كولكشن Users");

      // 6. التوجيه الذكي
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                userType == 's' ? const StaffHomeScreen() : const HomeScreen(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showSnackBar(
        e.code == 'email-already-in-use'
            ? 'الإيميل مسجل مسبقاً'
            : 'حدث خطأ في التسجيل',
      );
    } catch (e) {
      print("🚨 خطأ غير متوقع: $e");
      _showSnackBar('خطأ غير متوقع: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textAlign: TextAlign.right),
        backgroundColor: const Color(0xFFA07B4F),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double kaabaHeight = size.height * 0.70;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/black.png', fit: BoxFit.cover),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: kaabaHeight,
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
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
                              Colors.black.withOpacity(0.4),
                              Colors.black.withOpacity(0.8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: kaabaHeight + 19,
            right: 22,
            child: const Text(
              'إنشاء حساب',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontFamily: 'IBMPlexSans',
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: size.height - kaabaHeight + 20),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      children: [
                        _buildTextField(
                          idController,
                          'رقم التصريح / الوظيفي',
                          false,
                        ),
                        const SizedBox(height: 15),
                        _buildTextField(
                          emailController,
                          'البريد الإلكتروني',
                          false,
                        ),
                        const SizedBox(height: 15),
                        _buildTextField(
                          passwordController,
                          'كلمة المرور',
                          true,
                        ),
                        const SizedBox(height: 30),
                        isLoading
                            ? const CircularProgressIndicator(
                                color: Color(0xFFA07B4F),
                              )
                            : _buildGradientButton('تسجيل', _handleSignUp),
                        const SizedBox(height: 15),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            'لديك حساب بالفعل؟ تسجيل دخول',
                            style: TextStyle(
                              color: Colors.white70,
                              fontFamily: 'IBMPlexSans',
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
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    bool isPassword,
  ) {
    return TextFormField(
      controller: controller,
      textAlign: TextAlign.right,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white, fontFamily: 'IBMPlexSans'),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 20,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFA07B4F), width: 2),
        ),
      ),
    );
  }

  Widget _buildGradientButton(String title, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFA07B4F), Color(0xFF3A2D1D)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
