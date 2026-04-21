import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:ui' as ui;

class AddTripDialog extends StatefulWidget {
  final String? tripId;
  final Map<String, dynamic>? initialData;

  const AddTripDialog({super.key, this.tripId, this.initialData});

  @override
  State<AddTripDialog> createState() => _AddTripDialogState();
}

class _AddTripDialogState extends State<AddTripDialog> {
  String? selectedGroupId;
  String? selectedTemplateId;
  String? selectedBusId;
  DateTime? selectedDateTime;
  GeoPoint? busLocation;
  bool isLoading = false;
  bool isLocationFetched = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      selectedGroupId = widget.initialData!['group_id'];
      selectedTemplateId = widget.initialData!['template_id'];
      selectedBusId = widget.initialData!['bus_id'];
      selectedDateTime = (widget.initialData!['scheduled_at'] as Timestamp)
          .toDate();
      isLocationFetched = true;
    }
  }

  Future<void> _pickDateTime() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: selectedDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFA07B4F),
              onPrimary: Colors.white,
              surface: Color(0xFF212121),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: selectedDateTime != null
            ? TimeOfDay.fromDateTime(selectedDateTime!)
            : TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _fetchLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showMsg('الرجاء تفعيل خدمة الموقع في جوالك');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    setState(() => isLoading = true);
    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        busLocation = GeoPoint(position.latitude, position.longitude);
        isLocationFetched = true;
      });
      _showMsg('تم حفظ موقع الحافلة بنجاح ✅');
    } catch (e) {
      _showMsg('حدث خطأ في جلب الموقع');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveTrip() async {
    if (selectedGroupId == null ||
        selectedTemplateId == null ||
        selectedBusId == null ||
        selectedDateTime == null) {
      _showMsg('الرجاء إكمال جميع البيانات');
      return;
    }

    setState(() => isLoading = true);

    try {
      String tripDocId =
          widget.tripId ?? '${selectedTemplateId}_$selectedGroupId';
      var firestore = FirebaseFirestore.instance;

      // 1. إنشاء/تحديث معلومات الرحلة الأساسية
      Map<String, dynamic> data = {
        'template_id': selectedTemplateId,
        'group_id': selectedGroupId,
        'bus_id': selectedBusId,
        'scheduled_at': Timestamp.fromDate(selectedDateTime!),
        'status': widget.initialData?['status'] ?? 'scheduled',
        'created_by': FirebaseAuth.instance.currentUser?.uid,
      };

      await firestore
          .collection('Trips')
          .doc(tripDocId)
          .set(data, SetOptions(merge: true));

      // 🌟 2. السحر هنا: إنشاء (Manifest) قائمة ركاب الرحلة تلقائياً!
      // إذا كانت إضافة جديدة (مو تعديل)، نسحب الحجاج ونضيفهم للرحلة
      if (widget.tripId == null) {
        // نجيب كل الحجاج اللي في هذا القروب من كولكشن اليوزرز
        var usersSnapshot = await firestore
            .collection('Users')
            .where('group_id', isEqualTo: selectedGroupId)
            .get();

        // نستخدم Batch (حفظ دفعة واحدة) عشان يكون سريع وما يعلق التطبيق
        WriteBatch batch = firestore.batch();

        for (var doc in usersSnapshot.docs) {
          var userData = doc.data();
          // ننشئ ملف لكل حاج داخل مجموعة manifest التابعة لهذي الرحلة
          var manifestRef = firestore
              .collection('Trips')
              .doc(tripDocId)
              .collection('manifest')
              .doc(doc.id);

          batch.set(manifestRef, {
            'name':
                userData['info']?['name'] ?? 'بدون اسم', // سحبنا الاسم للسهولة
            'status': 'waiting', // الحالة الافتراضية: بانتظار التصعيد
            'added_at': FieldValue.serverTimestamp(),
          });
        }

        await batch.commit(); // تنفيذ الحفظ دفعة واحدة
      }

      if (mounted) Navigator.pop(context, true);
      _showMsg(
        widget.tripId == null
            ? 'تمت إضافة الرحلة وإنشاء قائمة الركاب 🚀'
            : 'تم التعديل ✅',
      );
    } catch (e) {
      _showMsg('حدث خطأ أثناء الحفظ: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // 🌟 دالة الحذف الجديدة مع رسالة التأكيد
  Future<void> _deleteTrip() async {
    // 1. إظهار رسالة تأكيد أولاً
    bool confirmDelete =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF2D231E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            title: const Text(
              'تأكيد الحذف',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
            content: const Text(
              'هل أنت متأكد من رغبتك في حذف هذه الرحلة نهائياً؟ لا يمكن التراجع عن هذا الإجراء.',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.right,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false), // إلغاء
                child: const Text(
                  'إلغاء',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: () => Navigator.pop(context, true), // تأكيد
                child: const Text(
                  'نعم، احذف',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false; // إذا ضغط برا الشاشة يعتبره إلغاء

    // 2. إذا وافق على الحذف، نحذف من الداتابيس
    if (confirmDelete) {
      setState(() => isLoading = true);
      try {
        await FirebaseFirestore.instance
            .collection('Trips')
            .doc(widget.tripId)
            .delete();
        if (mounted) Navigator.pop(context, true); // إغلاق النافذة
        _showMsg('تم حذف الرحلة بنجاح 🗑️');
      } catch (e) {
        _showMsg('حدث خطأ أثناء الحذف');
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  void _showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textAlign: TextAlign.right),
        backgroundColor: const Color(0xFFA07B4F),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.tripId != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4A3B32), Color(0xFF2D231E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: const Color(0xFFA07B4F).withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                isEdit ? 'تعديل معلومات الرحلة' : 'إضافة معلومات الرحلة',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 25),

              _buildGroupDropdown(),
              const SizedBox(height: 15),

              _buildTemplateDropdown(),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickDateTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Center(
                          child: Text(
                            selectedDateTime == null
                                ? 'موعد الانطلاق'
                                : '${selectedDateTime!.hour}:${selectedDateTime!.minute.toString().padLeft(2, '0')} | ${selectedDateTime!.day}/${selectedDateTime!.month}',
                            style: TextStyle(
                              color: selectedDateTime == null
                                  ? Colors.white54
                                  : Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _buildBusDropdown()),
                ],
              ),
              const SizedBox(height: 15),

              GestureDetector(
                onTap: _fetchLocation,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isLocationFetched
                        ? Colors.green.withOpacity(0.15)
                        : Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isLocationFetched
                          ? Colors.green.withOpacity(0.5)
                          : Colors.white12,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLocationFetched ? 'تم تحديد الموقع' : 'إضافة الموقع',
                        style: TextStyle(
                          color: isLocationFetched
                              ? Colors.green
                              : Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        isLocationFetched
                            ? Icons.check_circle
                            : Icons.add_location_alt,
                        color: isLocationFetched
                            ? Colors.green
                            : Colors.white54,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // 🌟 أزرار التحكم السفلية (تم التعديل هنا لدعم الحذف)
              Row(
                children: [
                  // زر الإضافة / التعديل (يأخذ المساحة الأكبر)
                  Expanded(
                    child: SizedBox(
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA07B4F),
                          elevation: 5,
                          shadowColor: const Color(0xFFA07B4F).withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isLoading ? null : _saveTrip,
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                isEdit ? 'حفظ التعديلات' : 'إضافة',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),

                  // 🌟 زر الحذف يظهر فقط في حالة التعديل
                  if (isEdit) ...[
                    const SizedBox(width: 15),
                    SizedBox(
                      height: 55,
                      width: 55, // زر مربع أنيق
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.withOpacity(0.15),
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          side: BorderSide(
                            color: Colors.redAccent.withOpacity(0.5),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isLoading ? null : _deleteTrip,
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- دوال القوائم (نفسها بدون تغيير) ---
  Widget _buildGroupDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('Groups').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const LinearProgressIndicator(color: Color(0xFFA07B4F));

        var groups = snapshot.data!.docs;
        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: DropdownButtonFormField<String>(
            value: selectedGroupId,
            isExpanded: true,
            dropdownColor: const Color(0xFF2D231E),
            iconEnabledColor: const Color(0xFFA07B4F),
            decoration: _inputDeco('اختر المجموعة المسؤولة'),
            items: groups
                .map(
                  (doc) => DropdownMenuItem<String>(
                    value: doc.id,
                    child: Text(
                      'مجموعة: ${doc.id}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) => setState(() => selectedGroupId = val),
          ),
        );
      },
    );
  }

  Widget _buildTemplateDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('TripTemplates')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const LinearProgressIndicator(color: Color(0xFFA07B4F));

        var templates = snapshot.data!.docs;
        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: DropdownButtonFormField<String>(
            value: selectedTemplateId,
            isExpanded: true,
            dropdownColor: const Color(0xFF2D231E),
            iconEnabledColor: const Color(0xFFA07B4F),
            decoration: _inputDeco('الوجهة (اختر الرحلة)'),
            items: templates
                .map(
                  (doc) => DropdownMenuItem<String>(
                    value: doc.id,
                    child: Text(
                      doc['title'] ?? 'بدون عنوان',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) => setState(() => selectedTemplateId = val),
          ),
        );
      },
    );
  }

  Widget _buildBusDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('Buses').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const LinearProgressIndicator(color: Color(0xFFA07B4F));

        var buses = snapshot.data!.docs;
        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: DropdownButtonFormField<String>(
            value: selectedBusId,
            isExpanded: true,
            dropdownColor: const Color(0xFF2D231E),
            iconEnabledColor: const Color(0xFFA07B4F),
            decoration: _inputDeco('رقم الباص'),
            items: buses
                .map(
                  (doc) => DropdownMenuItem<String>(
                    value: doc.id,
                    child: Text(
                      doc.id,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) => setState(() => selectedBusId = val),
          ),
        );
      },
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
      filled: true,
      fillColor: Colors.black26,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFA07B4F)),
      ),
    );
  }
}
