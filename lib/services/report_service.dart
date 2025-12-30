import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

class ReportService {
  Future<File> generateCSVReport(
    String courseName,
    List<Map<String, dynamic>> attendanceData,
  ) async {
    List<List<dynamic>> rows = [];

    // Headers
    rows.add(['Student Name', 'Student ID', 'Date/Time', 'Status']);

    for (var data in attendanceData) {
      rows.add([
        data['student_name'],
        data['student_id'],
        data['timestamp'],
        data['status'],
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);

    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/${courseName.replaceAll(" ", "_")}_attendance.csv',
    );
    return await file.writeAsString(csv);
  }

  Future<File> generatePDFReport(
    String courseName,
    List<Map<String, dynamic>> attendanceData,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Attendance Report: $courseName',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Generated on: ${DateTime.now().toString()}'),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headers: ['Student Name', 'ID', 'Date/Time'],
                data: attendanceData
                    .map(
                      (d) => [
                        d['student_name'],
                        d['student_id'],
                        d['timestamp'],
                      ],
                    )
                    .toList(),
              ),
            ],
          );
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/${courseName.replaceAll(" ", "_")}_attendance.pdf',
    );
    return await file.writeAsBytes(await pdf.save());
  }
}
