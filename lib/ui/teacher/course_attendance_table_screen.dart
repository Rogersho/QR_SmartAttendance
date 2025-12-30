import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../services/pdf_service.dart';
import 'qr_generator_screen.dart';
import '../../providers/attendance_provider.dart';

class CourseAttendanceTableScreen extends ConsumerStatefulWidget {
  final String courseId;
  final String courseName;
  final String classId;
  final String className;

  const CourseAttendanceTableScreen({
    super.key,
    required this.courseId,
    required this.courseName,
    required this.classId,
    required this.className,
  });

  @override
  ConsumerState<CourseAttendanceTableScreen> createState() =>
      _CourseAttendanceTableScreenState();
}

class _CourseAttendanceTableScreenState
    extends ConsumerState<CourseAttendanceTableScreen> {
  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(classStudentsProvider(widget.classId));
    final sessionsAsync = ref.watch(courseSessionsProvider(widget.courseId));
    final recordsAsync = ref.watch(courseRecordsProvider(widget.courseId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('${widget.courseName} Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: () => _downloadAttendance(ref),
          ),
        ],
      ),
      body: studentsAsync.when(
        data: (students) {
          return sessionsAsync.when(
            data: (sessions) {
              return recordsAsync.when(
                data: (records) {
                  if (sessions.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildTable(students, sessions, records);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewSession,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Session', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Create first attendance in that courses',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _addNewSession,
            child: const Text('Start First Session'),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(
    List<Map<String, dynamic>> students,
    List<Map<String, dynamic>> sessions,
    List<Map<String, dynamic>> records,
  ) {
    // Sort sessions by date (oldest first for the table)
    final sortedSessions = List<Map<String, dynamic>>.from(sessions)
      ..sort((a, b) => a['attendance_date'].compareTo(b['attendance_date']));

    // Check for duplicate dates to decide if we need to show time
    final dateCounts = <String, int>{};
    for (var session in sortedSessions) {
      final date = session['attendance_date'] as String;
      dateCounts[date] = (dateCounts[date] ?? 0) + 1;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
          columns: [
            const DataColumn(
              label: Text(
                'Student Name',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ...sortedSessions.map((session) {
              final dateStr = session['attendance_date'];
              final date = dateStr != null
                  ? DateTime.parse(dateStr)
                  : DateTime.now();
              String label = DateFormat('MMM d').format(date);

              if (dateCounts[dateStr] != null && dateCounts[dateStr]! > 1) {
                final createdAtStr = session['created_at'];
                if (createdAtStr != null) {
                  final createdAt = DateTime.parse(createdAtStr).toLocal();
                  label += '\n${DateFormat('HH:mm').format(createdAt)}';
                }
              }

              return DataColumn(
                label: InkWell(
                  onLongPress: () => _confirmDeleteSession(session['id']),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => _confirmDeleteSession(session['id']),
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.delete_outline,
                            size: 16,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
          rows: students.map((student) {
            return DataRow(
              cells: [
                DataCell(Text(student['full_name'] ?? 'Unknown')),
                ...sortedSessions.map((session) {
                  final isPresent = records.any(
                    (r) =>
                        r['student_id'] == student['id'] &&
                        r['session_id'] == session['id'],
                  );
                  return DataCell(
                    InkWell(
                      onTap: () => _toggleAttendance(
                        studentId: student['id'],
                        sessionId: session['id'],
                        isPresent: isPresent,
                      ),
                      child: Center(
                        child: Icon(
                          isPresent
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color: isPresent
                              ? AppColors.success
                              : AppColors.error,
                          size: 24,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _toggleAttendance({
    required String studentId,
    required String sessionId,
    required bool isPresent,
  }) async {
    try {
      if (isPresent) {
        // Remove attendance
        await ref
            .read(supabaseServiceProvider)
            .deleteAttendanceRecord(
              courseId: widget.courseId,
              studentId: studentId,
              sessionId: sessionId,
            );
      } else {
        // Mark present
        await ref
            .read(supabaseServiceProvider)
            .submitAttendance(
              courseId: widget.courseId,
              studentId: studentId,
              sessionId: sessionId,
              lat: 0,
              lng: 0,
            );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating attendance: $e')),
        );
      }
    }
  }

  Future<void> _confirmDeleteSession(String sessionId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session?'),
        content: const Text(
          'This will permanently delete this attendance session and all student records associated with it. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref
            .read(supabaseServiceProvider)
            .deleteAttendanceSession(sessionId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting session: $e')));
        }
      }
    }
  }

  void _addNewSession() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRGeneratorScreen(
          courseId: widget.courseId,
          courseName: widget.courseName,
          attendanceDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        ),
      ),
    );
  }

  Future<void> _downloadAttendance(WidgetRef ref) async {
    final profile = ref.read(profileProvider).value;
    if (profile == null) return;

    final students = ref.read(classStudentsProvider(widget.classId)).value;
    final sessions = ref.read(courseSessionsProvider(widget.courseId)).value;
    final records = ref.read(courseRecordsProvider(widget.courseId)).value;

    if (students == null || sessions == null || records == null) return;

    final sortedSessions = List<Map<String, dynamic>>.from(sessions)
      ..sort((a, b) => a['attendance_date'].compareTo(b['attendance_date']));

    // Check for duplicate dates to decide if we need to show time
    final dateCounts = <String, int>{};
    for (var session in sortedSessions) {
      final date = session['attendance_date'] as String;
      dateCounts[date] = (dateCounts[date] ?? 0) + 1;
    }

    final dates = sortedSessions.map((s) {
      final dateStr = s['attendance_date'];
      final date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();

      // If this date appears multiple times, append the time from created_at
      if (dateCounts[dateStr] != null && dateCounts[dateStr]! > 1) {
        final createdAtStr = s['created_at'];
        if (createdAtStr != null) {
          final createdAt = DateTime.parse(createdAtStr).toLocal();
          return '${DateFormat('MMM d').format(date)}\n${DateFormat('HH:mm').format(createdAt)}';
        }
      }

      return DateFormat('MMM d').format(date);
    }).toList();

    final studentData = students.map((student) {
      final attendanceList = sortedSessions.map((session) {
        return records.any(
          (r) =>
              r['student_id'] == student['id'] &&
              r['session_id'] == session['id'],
        );
      }).toList();

      return {
        'name': student['full_name'] ?? 'Unknown',
        'attendance': attendanceList,
      };
    }).toList();

    try {
      await PdfService.generateAndDownloadAttendancePdf(
        teacher: profile,
        className: widget.className,
        courseName: widget.courseName,
        dates: dates,
        studentData: studentData,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
      }
    }
  }
}
