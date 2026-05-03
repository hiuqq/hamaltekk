import 'package:flutter/material.dart';
import 'package:hamaltekk/screens/daily_report_detail_screen.dart';

class DailyReportsListScreen extends StatelessWidget {
  const DailyReportsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // قائمة الأيام المربوطة بمفاتيح الفايربيس الفعلية
    final List<Map<String, String>> hajjDays = [
      {'key': 'day_8', 'title': 'يوم التروية', 'date': '8 ذو الحجة'},
      {'key': 'day_9', 'title': 'يوم عرفة', 'date': '9 ذو الحجة'},
      {'key': 'day_10', 'title': 'يوم النحر (العيد)', 'date': '10 ذو الحجة'},
      {'key': 'day_11', 'title': 'أول أيام التشريق', 'date': '11 ذو الحجة'},
      {'key': 'day_12', 'title': 'ثاني أيام التشريق', 'date': '12 ذو الحجة'},
      {'key': 'day_13', 'title': 'ثالث أيام التشريق', 'date': '13 ذو الحجة'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'التقارير اليومية',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFA07B4F)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/black.png'), // خلفيتك الفخمة
            fit: BoxFit.cover,
            opacity: 0.1,
          ),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: hajjDays.length,
            itemBuilder: (context, index) {
              final day = hajjDays[index];
              return _buildDayCard(
                context,
                day['title']!,
                day['date']!,
                day['key']!,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDayCard(
    BuildContext context,
    String title,
    String date,
    String dayKey,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            // 🌟 الانتقال الفعلي لشاشة التقرير مع تمرير البيانات اللازمة
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DailyReportDetailScreen(
                  dayKey: dayKey, // يمرر مفتاح اليوم مثل 'day_8'
                  dayTitle: title, // يمرر مسمى اليوم مثل 'يوم التروية'
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA07B4F).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.analytics_outlined,
                        color: Color(0xFFA07B4F),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          date,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white30,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
