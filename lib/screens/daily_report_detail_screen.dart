import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hamaltekk/widgets/pdf_export_service.dart';

class DailyReportDetailScreen extends StatefulWidget {
  final String dayKey;
  final String dayTitle;

  const DailyReportDetailScreen({
    super.key,
    required this.dayKey,
    required this.dayTitle,
  });

  @override
  State<DailyReportDetailScreen> createState() =>
      _DailyReportDetailScreenState();
}

class _DailyReportDetailScreenState extends State<DailyReportDetailScreen> {
  // ==========================================
  // 🌟 دالة جلب وتحليل البيانات المعزولة
  // ==========================================
  Future<Map<String, dynamic>> _fetchDashboardData() async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {};

    var userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .get();
    var userData = userDoc.data() as Map<String, dynamic>? ?? {};
    var info = userData['info'] ?? {};
    var groupId = userData['group_id'];

    if (groupId == null) return {};

    // 1. حساب مهام اليوم
    double completionRate = 0.0;
    List<Map<String, dynamic>> todayTasks = [];
    var tasksList = info['active_hajj_tasks']?[widget.dayKey];
    if (tasksList != null && tasksList is List) {
      int totalTasks = tasksList.length;
      int completedTasks = 0;
      for (var t in tasksList) {
        if (t is Map) {
          bool isCompleted = t['is_completed'] == true;
          if (isCompleted) completedTasks++;
          todayTasks.add({
            'title': t['title'] ?? 'مهمة بدون عنوان',
            'is_completed': isCompleted,
          });
        }
      }
      if (totalTasks > 0) completionRate = completedTasks / totalTasks;
    }

    // 2. حساب إجمالي الحجاج
    var pilgrimsQuery = await FirebaseFirestore.instance
        .collection('Users')
        .where('type', isEqualTo: 'p')
        .where('group_id', isEqualTo: groupId)
        .get();
    int totalPilgrims = pilgrimsQuery.docs.length;

    // 3. تحليل رحلات النقل (لهذا اليوم فقط) ومؤشر الاستجابة
    var tripsQuery = await FirebaseFirestore.instance
        .collection('Trips')
        .where('group_id', isEqualTo: groupId)
        .where('day', isEqualTo: widget.dayKey)
        .get();

    int totalTrips = tripsQuery.docs.length;
    int boardedPilgrims = 0;
    int delayedPilgrims = 0;
    int totalBoardingMinutes = 0;
    int tripsWithTime = 0;

    int totalResponseGapMinutes = 0;
    int validGapsCount = 0;

    for (var doc in tripsQuery.docs) {
      var data = doc.data();
      Timestamp? tripStart = data['start_time'];
      Timestamp? tripEnd = data['end_time'];

      var manifestSnapshot = await FirebaseFirestore.instance
          .collection('Trips')
          .doc(doc.id)
          .collection('manifest')
          .get();

      Timestamp? firstScanTime;

      for (var pilgrimDoc in manifestSnapshot.docs) {
        var pData = pilgrimDoc.data();
        if (pData['status'] == 'waiting') {
          delayedPilgrims++;
        } else {
          boardedPilgrims++;
          Timestamp? scannedAt = pData['scanned_at'];
          if (scannedAt != null) {
            if (firstScanTime == null ||
                scannedAt.toDate().isBefore(firstScanTime.toDate())) {
              firstScanTime = scannedAt;
            }
          }
        }
      }

      if (tripStart != null && tripEnd != null) {
        totalBoardingMinutes += tripEnd
            .toDate()
            .difference(tripStart.toDate())
            .inMinutes;
        tripsWithTime++;
      }

      if (tripStart != null && firstScanTime != null) {
        int gap = firstScanTime
            .toDate()
            .difference(tripStart.toDate())
            .inMinutes;
        if (gap < 0) gap = gap * -1;
        totalResponseGapMinutes += gap;
        validGapsCount++;
      }
    }

    int avgBoardingTime = tripsWithTime > 0
        ? (totalBoardingMinutes / tripsWithTime).round()
        : 0;
    int avgResponseGap = validGapsCount > 0
        ? (totalResponseGapMinutes / validGapsCount).round()
        : 0;

    // 4. جلب إشعارات الإعاشة
    var mealsQuery = await FirebaseFirestore.instance
        .collection('Meal_Notifications')
        .where('supervisor_id', isEqualTo: uid)
        .where('day', isEqualTo: widget.dayKey)
        .get();

    int mealsCount = mealsQuery.docs.length;
    List<String> providedMealsList = mealsQuery.docs
        .map((doc) => doc['meal_type'] as String)
        .toList();
    String providedMealsText = providedMealsList.isEmpty
        ? 'لا يوجد وجبات'
        : providedMealsList.join('، ');

    // 🌟 5. الإحصائيات المحدثة لبلاغات الحجاج (المنطق الجديد) 🌟
    var requestsQuery = await FirebaseFirestore.instance
        .collection('SupportRequests')
        .where('group_id', isEqualTo: groupId)
        .where('day', isEqualTo: widget.dayKey)
        .get();

    int totalRequests = requestsQuery.docs.length;
    int newRequests = requestsQuery.docs
        .where((doc) => doc['status'] == 'new')
        .length; // الجديدة اللي مارد عليها المشرف
    int pendingRequests = requestsQuery.docs
        .where((doc) => doc['status'] == 'pending')
        .length; // المؤجلة
    int resolvedRequests = requestsQuery.docs
        .where((doc) => doc['status'] == 'resolved')
        .length; // المحلولة

    return {
      'taskCompletion': completionRate,
      'todayTasks': todayTasks,
      'totalPilgrims': totalPilgrims,
      'totalTrips': totalTrips,
      'boardedPilgrims': boardedPilgrims,
      'delayedPilgrims': delayedPilgrims,
      'avgBoardingTime': avgBoardingTime,
      'avgResponseGap': avgResponseGap,
      'mealsCount': mealsCount,
      'providedMealsText': providedMealsText,
      // الداتا المحدثة 🌟
      'totalRequests': totalRequests,
      'newRequests': newRequests,
      'pendingRequests': pendingRequests,
      'resolvedRequests': resolvedRequests,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'تقرير ${widget.dayTitle}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFA07B4F)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/black.png'),
            fit: BoxFit.cover,
            opacity: 0.1,
          ),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: FutureBuilder<Map<String, dynamic>>(
            future: _fetchDashboardData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFA07B4F)),
                );
              }
              if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    "حدث خطأ في جلب بيانات التقرير",
                    style: TextStyle(color: Colors.redAccent),
                  ),
                );
              }

              final data = snapshot.data ?? {};
              double taskCompletion = data['taskCompletion'] ?? 0.0;
              List<Map<String, dynamic>> todayTasks = data['todayTasks'] ?? [];
              int avgBoardingTime = data['avgBoardingTime'] ?? 0;
              int avgResponseGap = data['avgResponseGap'] ?? 0;
              int totalTrips = data['totalTrips'] ?? 0;
              int totalPilgrims = data['totalPilgrims'] ?? 0;
              int boardedPilgrims = data['boardedPilgrims'] ?? 0;
              int delayedPilgrims = data['delayedPilgrims'] ?? 0;
              int mealsCount = data['mealsCount'] ?? 0;
              String providedMealsText =
                  data['providedMealsText'] ?? 'لا يوجد وجبات';

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBoardingProgressBar(
                      totalPilgrims,
                      boardedPilgrims,
                      delayedPilgrims,
                    ),
                    const SizedBox(height: 20),

                    _buildResponseGapCard(avgResponseGap, totalTrips > 0),
                    const SizedBox(height: 15),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTimeCard(
                            'متوسط مدة التصعيد',
                            '$avgBoardingTime',
                            'دقيقة',
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildTimeCard(
                            'الحجاج المتأخرين',
                            '$delayedPilgrims',
                            'حاج',
                            isAlert: delayedPilgrims > 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    // 🌟 4. كارد إحصائيات بلاغات الحجاج المُحدث 🌟
                    _buildRequestsSummaryCard(data),
                    const SizedBox(height: 25),

                    // 5. المهام والإنجاز
                    Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              SizedBox(
                                width: 100,
                                height: 100,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CircularProgressIndicator(
                                      value: taskCompletion,
                                      strokeWidth: 10,
                                      backgroundColor: Colors.white12,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                            Color(0xFFA07B4F),
                                          ),
                                    ),
                                    Center(
                                      child: Text(
                                        '${(taskCompletion * 100).toInt()}%',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'إنجاز مهام اليوم',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildLegendItem(
                                    'مكتملة',
                                    const Color(0xFFA07B4F),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildLegendItem(
                                    'قيد الانتظار',
                                    Colors.white12,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (todayTasks.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            const Divider(color: Colors.white12),
                            const SizedBox(height: 10),
                            ...todayTasks
                                .map(
                                  (t) => _buildTaskListItem(
                                    t['title'],
                                    t['is_completed'],
                                  ),
                                )
                                .toList(),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),

                    // 6. إحصائيات الإعاشة
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: const Color(0xFFA07B4F).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFA07B4F).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.restaurant_menu,
                              color: Color(0xFFA07B4F),
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'إحصائيات الإعاشة',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'عدد الإشعارات: $mealsCount',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  'الوجبات: $providedMealsText',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),

                    const Text(
                      'ملخص رحلات اليوم',
                      style: TextStyle(
                        color: Color(0xFFA07B4F),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 1.8,
                      children: [
                        _buildStatCard(
                          'عدد الرحلات اليوم',
                          '$totalTrips',
                          Icons.directions_bus,
                        ),
                        _buildStatCard(
                          'إجمالي حجاج الحملة',
                          '$totalPilgrims',
                          Icons.groups,
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA07B4F),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: () async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('جاري إنشاء التقرير...'),
                              backgroundColor: Color(0xFF1E1E1E),
                            ),
                          );
                          await PdfExportService.exportDailyReport(
                            dayTitle: widget.dayTitle,
                            data: data,
                          );
                        },
                        icon: const Icon(
                          Icons.picture_as_pdf,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'تصدير التقرير (PDF)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ==========================================
  // الويدجت (Widgets) الفرعية
  // ==========================================

  // 🌟 كارد إدارة بلاغات الحجاج المُحدث 🌟
  Widget _buildRequestsSummaryCard(Map<String, dynamic> data) {
    int newReq = data['newRequests'] ?? 0;
    int pendingReq = data['pendingRequests'] ?? 0;
    int resolvedReq = data['resolvedRequests'] ?? 0;

    // التنبيه يصير أحمر إذا فيه طلبات جديدة (new) محد لمسها، ويصير برتقالي إذا فيه مؤجلة
    Color borderColor = newReq > 0
        ? Colors.redAccent.withOpacity(0.5)
        : (pendingReq > 0
              ? Colors.orangeAccent.withOpacity(0.3)
              : const Color(0xFFA07B4F).withOpacity(0.3));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.support_agent, color: Color(0xFFA07B4F), size: 24),
              SizedBox(width: 10),
              Text(
                'إدارة بلاغات الحجاج',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(color: Colors.white10),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat(
                'الإجمالي',
                '${data['totalRequests'] ?? 0}',
                Colors.white,
              ),
              _buildMiniStat('تم الحل ✅', '$resolvedReq', Colors.green),
              _buildMiniStat('مؤجلة ⏳', '$pendingReq', Colors.orangeAccent),
              _buildMiniStat(
                'جديدة ⚠️',
                '$newReq',
                newReq > 0 ? Colors.redAccent : Colors.white54,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildResponseGapCard(int gapMinutes, bool hasTrips) {
    Color indicatorColor;
    String evaluationText;
    IconData evaluationIcon;

    if (!hasTrips) {
      indicatorColor = Colors.white38;
      evaluationText = 'لا توجد رحلات حتى الآن';
      evaluationIcon = Icons.access_time;
    } else if (gapMinutes <= 5) {
      indicatorColor = const Color(0xFF4CAF50);
      evaluationText = 'استجابة سريعة جداً - تنظيم ممتاز';
      evaluationIcon = Icons.bolt;
    } else if (gapMinutes <= 15) {
      indicatorColor = Colors.orangeAccent;
      evaluationText = 'استجابة متوسطة - يوجد تأخير بسيط';
      evaluationIcon = Icons.warning_amber_rounded;
    } else {
      indicatorColor = Colors.redAccent;
      evaluationText = 'استجابة بطيئة - خلل في توجيه الحجاج';
      evaluationIcon = Icons.error_outline;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: indicatorColor.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: indicatorColor, size: 22),
              const SizedBox(width: 8),
              const Text(
                'مؤشر سرعة استجابة الحجاج',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    hasTrips ? '$gapMinutes' : '-',
                    style: TextStyle(
                      color: indicatorColor,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'دقيقة',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: indicatorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  evaluationText,
                  style: TextStyle(
                    color: indicatorColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBoardingProgressBar(int total, int boarded, int delayed) {
    double progress = total > 0 ? (boarded / total) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'حالة تفويج الحجاج',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(
                color: Color(0xFFA07B4F),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFA07B4F)),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeCard(
    String title,
    String value,
    String unit, {
    bool isAlert = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isAlert
              ? Colors.redAccent.withOpacity(0.5)
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            '$value $unit',
            style: TextStyle(
              color: isAlert ? Colors.redAccent : Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: const Color(0xFFA07B4F)),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskListItem(String title, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isCompleted ? const Color(0xFFA07B4F) : Colors.white38,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isCompleted ? Colors.white : Colors.white70,
                fontSize: 13,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
