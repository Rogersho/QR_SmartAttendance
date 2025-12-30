import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/profile_model.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<void> generateAndDownloadAttendancePdf({
    required ProfileModel teacher,
    required String className,
    required String courseName,
    required List<String> dates,
    required List<Map<String, dynamic>>
    studentData, // { name: string, attendance: [bool] }
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(teacher, className, courseName),
          pw.SizedBox(height: 24),
          _buildTable(dates, studentData),
          pw.SizedBox(height: 40),
          _buildSignature(teacher.fullName),
          pw.Spacer(),
          _buildFooter(),
        ],
      ),
    );

    final String fileName =
        "attendance_${courseName.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf";
    await Printing.sharePdf(bytes: await pdf.save(), filename: fileName);
  }

  static pw.Widget _buildHeader(
    ProfileModel teacher,
    String className,
    String courseName,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          teacher.institution.toUpperCase(),
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          "Attendance Report",
          style: pw.TextStyle(fontSize: 16, color: PdfColors.grey700),
        ),
        pw.Divider(thickness: 1),
        pw.SizedBox(height: 16),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("Teacher: ${teacher.fullName}"),
                pw.Text("Class: $className"),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text("Course: $courseName"),
                pw.Text(
                  "Date Generated: ${DateTime.now().toString().split(' ')[0]}",
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTable(
    List<String> dates,
    List<Map<String, dynamic>> students,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        // Header Row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                'Student Name',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            ...dates.map(
              (date) => pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(
                  date,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ),
          ],
        ),
        // Data Rows
        ...students.map((student) {
          final List<bool> attendance = List<bool>.from(student['attendance']);
          return pw.TableRow(
            verticalAlignment: pw.TableCellVerticalAlignment.middle,
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(
                  student['name'],
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              ...attendance.map(
                (isPresent) => pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Center(
                    child: pw.Text(
                      isPresent ? "V" : "X",
                      style: pw.TextStyle(
                        color: isPresent ? PdfColors.green : PdfColors.red,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  static pw.Widget _buildSignature(String teacherName) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          "Teacher's Declaration:",
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          "I hereby certify that the above attendance record is accurate and complete.",
        ),
        pw.SizedBox(height: 32),
        pw.Container(
          width: 200,
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(width: 1)),
          ),
        ),
        pw.Text("Signature: $teacherName"),
      ],
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              "Generated by SmartAttend App",
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
            // Page number is hard to do in static footer without context, but MultiPage handles it typically via footer param
            pw.Text(
              DateFormat('MMM d, y HH:mm').format(DateTime.now()),
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
          ],
        ),
      ],
    );
  }
}
