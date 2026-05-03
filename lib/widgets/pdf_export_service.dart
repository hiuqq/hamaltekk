import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfExportService {
  /// دالة تصدير التقرير اليومي إلى PDF
  static Future<void> exportDailyReport({
    required String dayTitle,
    required Map<String, dynamic> data,
  }) async {
    final pdf = pw.Document();

    // 🌟 تعريف اللون الذهبي الخاص بالتطبيق (Hex: A07B4F) ليعمل داخل الـ PDF
    final PdfColor myGoldColor = PdfColor.fromInt(0xFFA07B4F);
    final PdfColor darkBg = PdfColor.fromInt(0xFF1E1E1E);

    // تحميل خط "Cairo" من قوقل لدعم الحروف العربية بشكل صحيح
    final font = await PdfGoogleFonts.cairoMedium();
    final fontBold = await PdfGoogleFonts.cairoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // --- الهيدر (العنوان والشعار) ---
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 20,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.black,
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(10),
                    ),
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
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            'نظام إدارة الحشود والتقارير اليومية',
                            style: const pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      pw.Text(
                        dayTitle,
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 30),

                // --- ملخص البيانات ---
                pw.Text(
                  'ملخص الإحصائيات اليومية:',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: myGoldColor,
                  ),
                ),
                pw.SizedBox(height: 10),

                pw.TableHelper.fromTextArray(
                  border: pw.TableBorder.all(
                    color: PdfColors.grey300,
                    width: 0.5,
                  ),
                  headerAlignment: pw.Alignment.centerRight,
                  cellAlignment: pw.Alignment.centerRight,
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  headerDecoration: pw.BoxDecoration(color: darkBg),
                  cellStyle: const pw.TextStyle(fontSize: 12),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3), // عمود المسمى
                    1: const pw.FlexColumnWidth(2), // عمود القيمة
                  },
                  data: <List<String>>[
                    <String>['المؤشر الإحصائي', 'البيانات المسجلة'],
                    <String>[
                      'نسبة إنجاز المهام اليومية',
                      '${((data['taskCompletion'] ?? 0) * 100).toInt()}%',
                    ],
                    <String>[
                      'إجمالي عدد الحجاج في المجموعة',
                      '${data['totalPilgrims'] ?? 0}',
                    ],
                    <String>[
                      'عدد الحجاج الذين تم تصعيدهم',
                      '${data['boardedPilgrims'] ?? 0}',
                    ],
                    <String>[
                      'عدد الحجاج المتأخرين / المفقودين',
                      '${data['delayedPilgrims'] ?? 0}',
                    ],
                    <String>[
                      'إجمالي عدد الرحلات المنفذة',
                      '${data['totalTrips'] ?? 0}',
                    ],
                    <String>[
                      'متوسط وقت تصعيد الحافلة',
                      '${data['avgBoardingTime'] ?? 0} دقيقة',
                    ],
                  ],
                ),

                pw.SizedBox(height: 40),

                // --- قسم التوقيعات ---
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      children: [
                        pw.Text(
                          'ختم الحملة',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 40),
                        pw.Container(
                          width: 100,
                          height: 1,
                          color: PdfColors.grey,
                        ),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text(
                          'توقيع المشرف المسؤول',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 40),
                        pw.Container(
                          width: 100,
                          height: 1,
                          color: PdfColors.grey,
                        ),
                      ],
                    ),
                  ],
                ),

                pw.Spacer(),

                // --- الفوتر ---
                pw.Divider(color: PdfColors.grey300),
                pw.Center(
                  child: pw.Text(
                    'تم استخراج هذا التقرير تلقائياً بتاريخ: ${DateTime.now().toString().substring(0, 16)}',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // تشغيل واجهة الطباعة أو الحفظ في الجوال
    // 🌟 الحل المخصص للجوال: تحويل الـ PDF لبيانات ومشاركتها مباشرة
    final Uint8List bytes = await pdf.save();

    await Printing.sharePdf(bytes: bytes, filename: 'تقرير_$dayTitle.pdf');
  }
}
