import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/meal_plan.dart';
import '../models/chart_data.dart';

class PdfService {
  static Future<void> generateMealPlanPdf(
    MealPlan mealPlan,
    String modelName,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "HealthBuddy - Personalized Diet Plan",
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.purple700,
                    ),
                  ),
                  pw.Text(
                    "Model: $modelName",
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(color: PdfColors.purple100),
              pw.SizedBox(height: 10),

              pw.Text(
                mealPlan.title,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),

              // Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {0: const pw.FixedColumnWidth(80)},
                children: [
                  // Days Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.purple50,
                    ),
                    children: [
                      _buildHeaderCell("Meal"),
                      ...mealPlan.days.map((d) => _buildHeaderCell(d.day)),
                    ],
                  ),
                  // Breakfast
                  _buildDataRow(
                    "Breakfast",
                    mealPlan.days.map((d) => d.breakfast).toList(),
                  ),
                  // Snack 1
                  _buildDataRow(
                    "Snack 1",
                    mealPlan.days.map((d) => d.snack1).toList(),
                  ),
                  // Lunch
                  _buildDataRow(
                    "Lunch",
                    mealPlan.days.map((d) => d.lunch).toList(),
                  ),
                  // Snack 2
                  _buildDataRow(
                    "Snack 2",
                    mealPlan.days.map((d) => d.snack2).toList(),
                  ),
                  // Dinner
                  _buildDataRow(
                    "Dinner",
                    mealPlan.days.map((d) => d.dinner).toList(),
                  ),
                ],
              ),

              pw.Spacer(),

              // Footer
              pw.Divider(color: PdfColors.grey300),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "© Copyright HealthBuddy ${DateTime.now().year}",
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Text(
                    "Generated on: ${DateTime.now().toString().split(' ')[0]}",
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File(
      "${output.path}/meal_plan_${DateTime.now().millisecondsSinceEpoch}.pdf",
    );
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)], text: 'My ${mealPlan.title}');
  }

  static Future<void> generateChartPdf(
    ChartData chartData,
    String modelName,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "HealthBuddy - Data Insight",
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue700,
                    ),
                  ),
                  pw.Text(
                    "Model: $modelName",
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(color: PdfColors.blue100),
              pw.SizedBox(height: 10),

              pw.Text(
                chartData.title,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 40),

              // Chart Data Summary (since fl_chart doesn't work in PDF, we list data)
              pw.Text(
                "Data Analysis Summary:",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blue50),
                    children: [
                      _buildHeaderCell("Metric / Label"),
                      _buildHeaderCell("Value"),
                    ],
                  ),
                  ...chartData.data.map(
                    (d) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(d.label),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            d.value.toString(),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // Footer
              pw.Divider(color: PdfColors.grey300),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "© Copyright HealthBuddy ${DateTime.now().year}",
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Text(
                    "Generated on: ${DateTime.now().toString().split(' ')[0]}",
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File(
      "${output.path}/chart_${DateTime.now().millisecondsSinceEpoch}.pdf",
    );
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)], text: 'My Health Data Chart');
  }

  static pw.Widget _buildHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.purple700,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.TableRow _buildDataRow(String label, List<String?> values) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
        ...values.map(
          (v) => pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Text(v ?? "-", style: const pw.TextStyle(fontSize: 10)),
          ),
        ),
      ],
    );
  }
}
