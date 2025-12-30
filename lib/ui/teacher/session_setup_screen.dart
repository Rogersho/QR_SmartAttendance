import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/class_model.dart';
import '../../core/constants/app_colors.dart';
import 'qr_generator_screen.dart';

class SessionSetupScreen extends StatefulWidget {
  final String classId;
  final String className;
  final List<CourseModel> courses;

  const SessionSetupScreen({
    super.key,
    required this.classId,
    required this.className,
    required this.courses,
  });

  @override
  State<SessionSetupScreen> createState() => _SessionSetupScreenState();
}

class _SessionSetupScreenState extends State<SessionSetupScreen> {
  DateTime _selectedDate = DateTime.now();
  CourseModel? _selectedCourse;

  @override
  void initState() {
    super.initState();
    if (widget.courses.isNotEmpty) {
      _selectedCourse = widget.courses.first;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Setup Attendance')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Module',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<CourseModel>(
                  isExpanded: true,
                  value: _selectedCourse,
                  items: widget.courses.map((course) {
                    return DropdownMenuItem(
                      value: course,
                      child: Text(course.name),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCourse = val),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Select Date',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppColors.primary),
                    const SizedBox(width: 16),
                    Text(
                      DateFormat('EEEE, MMMM d, y').format(_selectedDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedCourse == null
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QRGeneratorScreen(
                              courseId: _selectedCourse!.id,
                              courseName: _selectedCourse!.name,
                              attendanceDate: DateFormat(
                                'yyyy-MM-dd',
                              ).format(_selectedDate),
                            ),
                          ),
                        );
                      },
                child: const Text('Start Attendance Session'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
