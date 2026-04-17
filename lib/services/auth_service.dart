import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // دالة التسجيل الرئيسية
  Future<String?> registerUser(
    String email,
    String password,
    String refNo,
  ) async {
    try {
      // 1. البحث في نُسك (كحاج)
      var nuskDoc = await _db.collection('Nusk').doc(refNo).get();

      String type = '';
      Map<String, dynamic> dataInfo = {};

      if (nuskDoc.exists) {
        type = 'p'; // حاج
        dataInfo = nuskDoc.data()!;
      } else {
        // 2. إذا لم يجد، يبحث في الموظفين
        var staffDoc = await _db.collection('Staff').doc(refNo).get();
        if (staffDoc.exists) {
          type = 's'; // موظف
          dataInfo = staffDoc.data()!;
        } else {
          return "الرقم المرجعي غير مسجل في النظام";
        }
      }

      // 3. إنشاء الحساب في Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // 4. تخزين البيانات في كولكشن Users باستخدام الـ UID
      await _db.collection('Users').doc(userCredential.user!.uid).set({
        'email': email,
        'type': type,
        'ref_no': refNo,
        'info': dataInfo, // هنا يتم نسخ البيانات تلقائياً للماب
        'created_at': FieldValue.serverTimestamp(),
      });

      return null; // نجحت العملية
    } catch (e) {
      return e.toString();
    }
  }
}
