import 'package:flutter/material.dart';

class HajjInfoOverlays {
  static String _clean(String? val) {
    if (val == null || val.isEmpty) return '-';
    return val.replaceAll(RegExp(r'[^0-9]'), '');
  }

  static void showInfoCard(BuildContext context, Map<String, dynamic> data) {
    String name = data['info']?['name'] ?? 'بدون اسم';
    String permit = data['info']?['p_no'] ?? 'غير متوفر';
    String phone = data['info']?['ph'] ?? 'غير متوفر';

    var mina = data['housing_mina'];
    var arafat = data['housing_arafat'];
    var muzdalifa = data['housing_muzdalifa'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: double.infinity,
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
                    Expanded(
                      child: Text(
                        name,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Icon(Icons.person_pin, color: Colors.white, size: 30),
                  ],
                ),
                const Divider(color: Colors.white30, height: 30),

                _buildField(
                  'رقم التصريح',
                  permit,
                  Icons.assignment_ind_outlined,
                ),
                const SizedBox(height: 12),
                _buildField('رقم الهاتف', phone, Icons.phone_android_outlined),

                const SizedBox(height: 25),
                const Text(
                  'معلومات التسكين',
                  style: TextStyle(
                    color: Color(0xFFA07B4F),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),

                _buildHousingSection('خيمة منى', mina),
                _buildHousingSection('مخيم عرفة', arafat),
                _buildHousingSection('مزدلفة', muzdalifa),

                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildField(String label, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          value,
          style: const TextStyle(color: Colors.white70, fontSize: 15),
        ),
        const SizedBox(width: 5),
        Text(
          '$label :',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, color: Colors.white54, size: 18),
      ],
    );
  }

  static Widget _buildHousingSection(String title, dynamic geoData) {
    String hall = _clean(geoData?['hall']);
    String room = _clean(geoData?['room']);
    String bed = _clean(geoData?['bed']);

    String info = "صالة: $hall | غرفة: $room | سرير: $bed";

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.location_on_outlined,
                color: Color(0xFFA07B4F),
                size: 16,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Text(
              info,
              textDirection: TextDirection.rtl,
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  static void showHealthCard(BuildContext context, Map<String, dynamic> data) {
    String name = data['info']?['name'] ?? 'بدون اسم';
    String bloodType = data['info']?['b_type'] ?? 'A+';
    String emergencyPhone = data['info']?['em_ph'] ?? 'غير متوفر';

    List rawDisList = data['info']?['dis'] ?? [];
    List cleanDisList = rawDisList
        .where((e) => e.toString().trim().isNotEmpty)
        .toList();
    String diseases = cleanDisList.isNotEmpty
        ? cleanDisList.join('\n')
        : 'لا توجد أمراض مسجلة';

    List rawDevList = data['info']?['dev'] ?? [];
    List cleanDevList = rawDevList
        .where((e) => e.toString().trim().isNotEmpty)
        .toList();
    String devices = cleanDevList.isNotEmpty
        ? cleanDevList.join('\n')
        : 'لا توجد أجهزة مسجلة';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: const LinearGradient(
                colors: [Color(0xFF7B241C), Color(0xFF44130E)],
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            name,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // 🌟 الحل النهائي لفصيلة الدم
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // 1. الحرف الإنجليزي (نحطه أولاً عشان فلاتر يرميه يسار الكلمة)
                              Text(
                                bloodType,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(width: 5), // مسافة صغيرة بينهم
                              // 2. الكلمة العربية (نحطها ثانياً عشان تصير في اليمين)
                              const Text(
                                " : فصيلة الدم",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Icon(
                      Icons.medical_services_outlined,
                      color: Colors.white,
                      size: 30,
                    ),
                  ],
                ),
                const Divider(color: Colors.white30, height: 30),

                _buildHealthField('الأمراض المزمنة', diseases),
                const SizedBox(height: 15),
                _buildHealthField('الأجهزة الطبية', devices),
                const SizedBox(height: 15),
                _buildHealthField('رقم الطوارئ', emergencyPhone),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildHealthField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$label :',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
