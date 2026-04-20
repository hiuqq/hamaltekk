import 'package:flutter/material.dart';

class HajjInfoOverlays {
  // 1. كارد البيانات الشخصية والتسكين (التصميم البني)
  static void showInfoCard(BuildContext context, Map<String, dynamic> data) {
    // سحب البيانات الأساسية
    String name = data['info']?['name'] ?? 'بدون اسم';
    String permit = data['info']?['p_no'] ?? 'غير متوفر';
    String phone = data['info']?['ph'] ?? 'غير متوفر';

    // 🌟 سحب بيانات التسكين الديناميكية من الـ Maps
    // تسكين منى
    var mina = data['housing_mina'];
    String minaText =
        "صالة: ${mina?['hall'] ?? '-'} , غرفة: ${mina?['room'] ?? '-'} , سرير: ${mina?['bed'] ?? '-'}";

    // تسكين عرفة
    var arafat = data['housing_arafat'];
    String arafatText =
        "صالة: ${arafat?['hall'] ?? '-'} , غرفة: ${arafat?['room'] ?? '-'} , سرير: ${arafat?['bed'] ?? '-'}";

    // تسكين مزدلفة
    var muzdalifa = data['housing_muzdalifa'];
    String muzdalifaText =
        "صالة: ${muzdalifa?['hall'] ?? '-'} , غرفة: ${muzdalifa?['room'] ?? '-'} , سرير: ${muzdalifa?['bed'] ?? '-'}";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: const LinearGradient(
                colors: [Color(0xFF5D4037), Color(0xFF212121)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Icon(
                      Icons.person_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ],
                ),
                const Divider(color: Colors.white30, height: 30),
                _buildField(': رقم التصريح', permit),
                const SizedBox(height: 12),
                _buildField(': رقم الهاتف', phone),
                const SizedBox(height: 20),

                const Text(
                  'معلومات التسكين',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),

                _buildHousingRow('منى', minaText),
                _buildHousingRow('عرفة', arafatText),
                _buildHousingRow('مزدلفة', muzdalifaText),
              ],
            ),
          ),
        );
      },
    );
  }

  // 2. كارد البيانات الصحية (التصميم الأحمر) - يبقى كما هو مع التأكد من المسميات
  static void showHealthCard(BuildContext context, Map<String, dynamic> data) {
    String name = data['info']?['name'] ?? 'بدون اسم';
    String bloodType = data['info']?['b_type'] ?? 'A+';
    String emergencyPhone = data['info']?['em_ph'] ?? 'غير متوفر';

    List disList = data['info']?['dis'] ?? [];
    String diseases = disList.isNotEmpty
        ? disList.join(' , ')
        : 'لا توجد أمراض مسجلة';

    List devList = data['info']?['dev'] ?? [];
    String devices = devList.isNotEmpty
        ? devList.join(' , ')
        : 'لا توجد أجهزة مسجلة';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: const LinearGradient(
                colors: [Color(0xFF880E4F), Color(0xFF212121)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "فصيلة الدم: $bloodType",
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 15),
                    const Icon(
                      Icons.medical_services_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ],
                ),
                const Divider(color: Colors.white30, height: 30),
                _buildField(': الأمراض المزمنة', diseases),
                const SizedBox(height: 15),
                _buildField(': الأجهزة الطبية', devices),
                const SizedBox(height: 15),
                _buildField(': رقم الطوارئ', emergencyPhone),
              ],
            ),
          ),
        );
      },
    );
  }

  // أداة مساعدة لعرض صف التسكين
  static Widget _buildHousingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFA07B4F),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  static Widget _buildField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }
}
