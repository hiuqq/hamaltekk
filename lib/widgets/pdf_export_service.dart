import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfExportService {
  static Future<void> exportDailyReport({
    required String dayTitle,
    required Map<String, dynamic> data,
  }) async {
    final pdf = pw.Document();

    // 🌟 الألوان (مع درجات الشفافية الجاهزة)
    final PdfColor myGoldColor = PdfColor.fromInt(0xFFA07B4F);
    final PdfColor myGoldColorHalf = PdfColor.fromInt(0x80A07B4F); // شفافية 50%
    final PdfColor myGoldColorLight = PdfColor.fromInt(
      0x4DA07B4F,
    ); // شفافية 30%

    final PdfColor darkBg = PdfColor.fromInt(0xFF121212);
    final PdfColor cardBg = PdfColor.fromInt(0xFF1E1E1E);

    final PdfColor redAccent = PdfColor.fromInt(0xFFFF5252);
    final PdfColor redAccentLight = PdfColor.fromInt(0x80FF5252);

    final PdfColor greenAccent = PdfColor.fromInt(0xFF4CAF50);
    final PdfColor greenAccentLight = PdfColor.fromInt(0x804CAF50);

    final PdfColor orangeAccent = PdfColor.fromInt(0xFFFFAB40);
    final PdfColor orangeAccentLight = PdfColor.fromInt(0x80FFAB40);

    final PdfColor whiteLight = PdfColor.fromInt(0x1AFFFFFF);

    // خط عربي
    final font = await PdfGoogleFonts.cairoMedium();
    final fontBold = await PdfGoogleFonts.cairoBold();

    // استخراج المتغيرات
    int totalPilgrims = data['totalPilgrims'] ?? 0;
    int boardedPilgrims = data['boardedPilgrims'] ?? 0;
    int delayedPilgrims = data['delayedPilgrims'] ?? 0;
    double progress = totalPilgrims > 0
        ? (boardedPilgrims / totalPilgrims)
        : 0.0;
    int taskCompletionInt = ((data['taskCompletion'] ?? 0) * 100).toInt();
    int avgResponseGap = data['avgResponseGap'] ?? 0;

    // 🌟 حساب نسب شريط التقدم للـ PDF 🌟
    int fillFlex = (progress * 100).clamp(0, 100).toInt();
    int emptyFlex = 100 - fillFlex;

    pdf.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(30),
          theme: pw.ThemeData.withFont(base: font, bold: fontBold),
          // خلفية سوداء لكامل صفحة الـ PDF
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(color: darkBg),
          ),
        ),
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // ==================== الهيدر ====================
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: cardBg,
                    borderRadius: pw.BorderRadius.circular(15),
                    border: pw.Border.all(color: myGoldColorHalf, width: 1.5),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'تطبيق حملتك',
                            style: pw.TextStyle(
                              color: myGoldColor,
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            'تقرير المشرف اليومي',
                            style: const pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      pw.Text(
                        dayTitle,
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 25),

                // ==================== شريط تفويج الحجاج ====================
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: cardBg,
                    borderRadius: pw.BorderRadius.circular(15),
                    border: pw.Border.all(color: whiteLight, width: 1),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'حالة تفويج الحجاج',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            '${(progress * 100).toInt()}%',
                            style: pw.TextStyle(
                              color: myGoldColor,
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 10),
                      // 🌟 رسم شريط التقدم بطريقة متوافقة مع الـ PDF 🌟
                      pw.Container(
                        height: 12,
                        width: double.infinity,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey800,
                          borderRadius: pw.BorderRadius.circular(10),
                        ),
                        child: pw.Row(
                          children: [
                            if (fillFlex > 0)
                              pw.Expanded(
                                flex: fillFlex,
                                child: pw.Container(
                                  decoration: pw.BoxDecoration(
                                    color: myGoldColor,
                                    borderRadius: pw.BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            if (emptyFlex > 0)
                              pw.Expanded(
                                flex: emptyFlex,
                                child: pw.SizedBox(),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 15),

                // ==================== مؤشر الاستجابة ====================
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: cardBg,
                    borderRadius: pw.BorderRadius.circular(15),
                    border: pw.Border.all(
                      color: (avgResponseGap <= 5
                          ? greenAccentLight
                          : (avgResponseGap <= 15
                                ? orangeAccentLight
                                : redAccentLight)),
                      width: 1.5,
                    ),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'مؤشر سرعة استجابة الحجاج',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Row(
                        children: [
                          pw.Text(
                            '$avgResponseGap',
                            style: pw.TextStyle(
                              color: myGoldColor,
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(width: 5),
                          pw.Text(
                            'دقيقة',
                            style: const pw.TextStyle(
                              color: PdfColors.grey300,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 15),

                // ==================== كروت صغيرة (متوسط المدة / المتأخرين) ====================
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _buildSmallCard(
                        'متوسط مدة التصعيد',
                        '${data['avgBoardingTime'] ?? 0} دقيقة',
                        cardBg,
                        PdfColors.white,
                        whiteLight,
                      ),
                    ),
                    pw.SizedBox(width: 15),
                    pw.Expanded(
                      child: _buildSmallCard(
                        'الحجاج المتأخرين',
                        '$delayedPilgrims حاج',
                        cardBg,
                        delayedPilgrims > 0 ? redAccent : PdfColors.white,
                        delayedPilgrims > 0 ? redAccentLight : whiteLight,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 25),

                // ==================== كارد البلاغات الجديد ====================
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: cardBg,
                    borderRadius: pw.BorderRadius.circular(15),
                    border: pw.Border.all(color: myGoldColorLight, width: 1.5),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'إدارة بلاغات الحجاج',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Divider(color: PdfColors.grey800),
                      pw.SizedBox(height: 10),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                        children: [
                          _buildMiniStat(
                            'الإجمالي',
                            '${data['totalRequests'] ?? 0}',
                            PdfColors.white,
                          ),
                          _buildMiniStat(
                            'تم الحل',
                            '${data['resolvedRequests'] ?? 0}',
                            greenAccent,
                          ),
                          _buildMiniStat(
                            'مؤجلة',
                            '${data['pendingRequests'] ?? 0}',
                            orangeAccent,
                          ),
                          _buildMiniStat(
                            'جديدة',
                            '${data['newRequests'] ?? 0}',
                            (data['newRequests'] ?? 0) > 0
                                ? redAccent
                                : PdfColors.grey,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 15),

                // ==================== المهام والإعاشة ====================
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _buildSmallCard(
                        'إنجاز مهام اليوم',
                        '$taskCompletionInt%',
                        cardBg,
                        myGoldColor,
                        whiteLight,
                      ),
                    ),
                    pw.SizedBox(width: 15),
                    pw.Expanded(
                      child: _buildSmallCard(
                        'إشعارات الإعاشة',
                        '${data['mealsCount'] ?? 0} وجبات',
                        cardBg,
                        myGoldColor,
                        whiteLight,
                      ),
                    ),
                  ],
                ),

                pw.Spacer(),

                // ==================== التوقيع والفوتر ====================
                pw.Divider(color: PdfColors.grey800),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'الختم والاعتماد: .........................',
                      style: pw.TextStyle(
                        color: PdfColors.grey300,
                        fontSize: 12,
                      ),
                    ),
                    pw.Text(
                      'توقيع المشرف: .........................',
                      style: pw.TextStyle(
                        color: PdfColors.grey300,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Center(
                  child: pw.Text(
                    'تم استخراج هذا التقرير تلقائياً عبر تطبيق "حملتك" بتاريخ: ${DateTime.now().toString().substring(0, 16)}',
                    style: const pw.TextStyle(
                      color: PdfColors.grey,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    final Uint8List bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: 'تقرير_$dayTitle.pdf');
  }

  // 🌟 دوال مساعدة لبناء الكروت داخل الـ PDF
  static pw.Widget _buildSmallCard(
    String title,
    String value,
    PdfColor bg,
    PdfColor valueColor,
    PdfColor borderColor,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: pw.BorderRadius.circular(15),
        border: pw.Border.all(color: borderColor, width: 1),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            title,
            style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 12),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            value,
            style: pw.TextStyle(
              color: valueColor,
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMiniStat(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          label,
          style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 10),
        ),
      ],
    );
  }
}
