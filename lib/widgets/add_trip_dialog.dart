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
  String? selectedDay;
  String? customDestination; // 🌟 حقل الوجهة المخصصة
  DateTime? selectedDateTime;
  GeoPoint? busLocation;
  bool isLoading = false;
  bool isLocationFetched = false;

  final List<Map<String, String>> hajjDays = [
    {'key': 'day_8', 'title': 'يوم التروية (8 ذو الحجة)'},
    {'key': 'day_9', 'title': 'يوم عرفة (9 ذو الحجة)'},
    {'key': 'day_10', 'title': 'يوم النحر (10 ذو الحجة)'},
    {'key': 'day_11', 'title': 'أول أيام التشريق (11 ذو الحجة)'},
    {'key': 'day_12', 'title': 'ثاني أيام التشريق (12 ذو الحجة)'},
    {'key': 'day_13', 'title': 'ثالث أيام التشريق (13 ذو الحجة)'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      selectedGroupId = widget.initialData!['group_id'];
      selectedTemplateId = widget.initialData!['template_id'];
      customDestination = widget.initialData!['custom_destination'];
      selectedBusId = widget.initialData!['bus_id'];
      selectedDay = widget.initialData!['day'];
      selectedDateTime = (widget.initialData!['scheduled_at'] as Timestamp)
          .toDate();

      if (widget.initialData!['bus_lat'] != null &&
          widget.initialData!['bus_lng'] != null) {
        busLocation = GeoPoint(
          widget.initialData!['bus_lat'],
          widget.initialData!['bus_lng'],
        );
        isLocationFetched = true;
      }
    }
  }

  Future<void> _pickDateTime() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: selectedDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFA07B4F),
            onPrimary: Colors.white,
            surface: Color(0xFF212121),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
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
        selectedDay == null ||
        selectedDateTime == null) {
      _showMsg('الرجاء إكمال جميع البيانات الأساسية');
      return;
    }
    if (selectedTemplateId == 'other' &&
        (customDestination == null || customDestination!.trim().isEmpty)) {
      _showMsg('الرجاء كتابة الوجهة المخصصة');
      return;
    }

    setState(() => isLoading = true);

    try {
      String tripDocId =
          widget.tripId ?? '${selectedTemplateId}_$selectedGroupId';
      var firestore = FirebaseFirestore.instance;

      Map<String, dynamic> data = {
        'template_id': selectedTemplateId,
        'custom_destination': selectedTemplateId == 'other'
            ? customDestination
            : null, // 🌟
        'group_id': selectedGroupId,
        'bus_id': selectedBusId,
        'day': selectedDay,
        'scheduled_at': Timestamp.fromDate(selectedDateTime!),
        'status': widget.initialData?['status'] ?? 'scheduled',
        'created_by': FirebaseAuth.instance.currentUser?.uid,
      };

      if (busLocation != null) {
        data['bus_lat'] = busLocation!.latitude;
        data['bus_lng'] = busLocation!.longitude;
      }

      // 🌟 تحديث حالة الباص ليصبح مشغولاً
      await firestore.collection('Buses').doc(selectedBusId).update({
        'status': 'in_use',
      });

      await firestore
          .collection('Trips')
          .doc(tripDocId)
          .set(data, SetOptions(merge: true));

      if (widget.tripId == null) {
        // 🌟 الفلتر الذكي للحجاج فقط (لحل مشكلة المشرف)
        var usersSnapshot = await firestore
            .collection('Users')
            .where('group_id', isEqualTo: selectedGroupId)
            .where('type', isEqualTo: 'p')
            .get();

        WriteBatch batch = firestore.batch();

        for (var doc in usersSnapshot.docs) {
          var userData = doc.data();
          var manifestRef = firestore
              .collection('Trips')
              .doc(tripDocId)
              .collection('manifest')
              .doc(doc.id);
          batch.set(manifestRef, {
            'name': userData['info']?['name'] ?? 'بدون اسم',
            'status': 'waiting',
            'added_at': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
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

  Future<void> _deleteTrip() async {
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
              'هل أنت متأكد من رغبتك في حذف هذه الرحلة نهائياً؟',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.right,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: () => Navigator.pop(context, true),
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
        false;

    if (confirmDelete) {
      setState(() => isLoading = true);
      try {
        // 🌟 تحرير الباص ليعود متاحاً
        if (selectedBusId != null) {
          await FirebaseFirestore.instance
              .collection('Buses')
              .doc(selectedBusId)
              .update({'status': ''});
        }
        await FirebaseFirestore.instance
            .collection('Trips')
            .doc(widget.tripId)
            .delete();
        if (mounted) Navigator.pop(context, true);
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

              // 🌟 حقل الوجهة المخصصة يظهر فقط إذا اختار أخرى
              if (selectedTemplateId == 'other') ...[
                const SizedBox(height: 15),
                TextFormField(
                  initialValue: customDestination,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.right,
                  decoration: _inputDeco('اكتب وجهة الرحلة المخصصة'),
                  onChanged: (val) => customDestination = val,
                ),
              ],
              const SizedBox(height: 15),

              _buildDayDropdown(),
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

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA07B4F),
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
                  if (isEdit) ...[
                    const SizedBox(width: 15),
                    SizedBox(
                      height: 55,
                      width: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.withOpacity(0.15),
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

  Widget _buildDayDropdown() {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: DropdownButtonFormField<String>(
        value: selectedDay,
        isExpanded: true,
        dropdownColor: const Color(0xFF2D231E),
        iconEnabledColor: const Color(0xFFA07B4F),
        decoration: _inputDeco('اختر يوم الرحلة'),
        items: hajjDays
            .map(
              (day) => DropdownMenuItem<String>(
                value: day['key'],
                child: Text(
                  day['title']!,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            )
            .toList(),
        onChanged: (val) => setState(() => selectedDay = val),
      ),
    );
  }

  Widget _buildGroupDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('Groups').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const LinearProgressIndicator(color: Color(0xFFA07B4F));
        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: DropdownButtonFormField<String>(
            value: selectedGroupId,
            isExpanded: true,
            dropdownColor: const Color(0xFF2D231E),
            iconEnabledColor: const Color(0xFFA07B4F),
            decoration: _inputDeco('اختر المجموعة المسؤولة'),
            items: snapshot.data!.docs
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
        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: DropdownButtonFormField<String>(
            value: selectedTemplateId,
            isExpanded: true,
            dropdownColor: const Color(0xFF2D231E),
            iconEnabledColor: const Color(0xFFA07B4F),
            decoration: _inputDeco('الوجهة (اختر الرحلة)'),
            items: snapshot.data!.docs
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

  // 🌟 إخفاء الباصات المشغولة وجعلها باللون الرمادي
  Widget _buildBusDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('Buses').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const LinearProgressIndicator(color: Color(0xFFA07B4F));
        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: DropdownButtonFormField<String>(
            value: selectedBusId,
            isExpanded: true,
            dropdownColor: const Color(0xFF2D231E),
            iconEnabledColor: const Color(0xFFA07B4F),
            decoration: _inputDeco('رقم الباص'),
            items: snapshot.data!.docs.map((doc) {
              bool isInUse =
                  doc.data().toString().contains('status') &&
                  doc['status'] == 'in_use' &&
                  selectedBusId != doc.id;
              return DropdownMenuItem<String>(
                value: isInUse
                    ? null
                    : doc.id, // تعطيل الاختيار إذا كان مشغولاً
                child: Text(
                  doc.id + (isInUse ? ' (مشغول ⚠️)' : ''),
                  style: TextStyle(
                    color: isInUse ? Colors.white38 : Colors.white,
                  ),
                ),
              );
            }).toList(),
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
