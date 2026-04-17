import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String email;
  final String type; // 'p' للحاج أو 's' للموظف
  final String refNo; // رقم التصريح أو الرقم الوظيفي
  final Map<String, dynamic> info; // البيانات المنسوخة من نُسك أو الحملة
  final Timestamp? createdAt;

  UserModel({
    required this.email,
    required this.type,
    required this.refNo,
    required this.info,
    this.createdAt,
  });

  // هذه الدالة تحول بيانات فايربيس إلى كائن (Object) نستخدمه في التطبيق
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      email: map['email'] ?? '',
      type: map['type'] ?? '',
      refNo: map['ref_no'] ?? '', // تأكدي أن الحرف N كبير هنا
      info: Map<String, dynamic>.from(map['info'] ?? {}),
      createdAt: map['created_at'],
    ); // الفاصلة المنقوطة هنا فقط
  }

  // هذه الدالة تحول الكائن إلى خريطة (Map) عشان نرسلها لفايربيس عند الحفظ
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'type': type,
      'ref_no': refNo,
      'info': info,
      'created_at': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}
