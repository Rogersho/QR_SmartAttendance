import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import 'package:animate_do/animate_do.dart';
import '../../providers/attendance_provider.dart';

class SessionRecordsScreen extends ConsumerWidget {
  final String sessionId;
  final String sessionDate;
  final String courseName;
  final String? classId;
  final String? courseId;

  const SessionRecordsScreen({
    super.key,
    required this.sessionId,
    required this.sessionDate,
    required this.courseName,
    this.classId,
    this.courseId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(sessionRecordsProvider(sessionId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(courseName, style: const TextStyle(fontSize: 16)),
            Text(
              sessionDate.isNotEmpty
                  ? DateFormat(
                      'MMM d, yyyy',
                    ).format(DateTime.parse(sessionDate))
                  : 'Unknown Date',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          if (classId != null && courseId != null)
            IconButton(
              icon: const Icon(Icons.person_add_rounded),
              onPressed: () => _showManualAttendanceDialog(context, ref),
            ),
        ],
      ),
      body: recordsAsync.when(
        data: (records) {
          if (records.isEmpty) {
            return const Center(child: Text('No attendance recorded.'));
          }
          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final profile = record['profiles'];
              return FadeInLeft(
                duration: const Duration(milliseconds: 300),
                delay: Duration(milliseconds: 50 * index),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(profile['full_name']?[0].toUpperCase() ?? '?'),
                  ),
                  title: Text(profile['full_name'] ?? 'Unknown Student'),
                  subtitle: Text(profile['email'] ?? 'No Email'),
                  trailing: Text(
                    record['created_at'] != null
                        ? DateFormat(
                            'HH:mm',
                          ).format(DateTime.parse(record['created_at']))
                        : '--:--',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showManualAttendanceDialog(BuildContext context, WidgetRef ref) async {
    final students = await ref
        .read(supabaseServiceProvider)
        .getClassEnrolledStudents(classId!);

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Manually Mark Attendance',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return ListTile(
                      title: Text(student['full_name']),
                      subtitle: Text(student['email']),
                      onTap: () async {
                        try {
                          await ref
                              .read(supabaseServiceProvider)
                              .submitAttendance(
                                courseId: courseId!,
                                studentId: student['id'],
                                sessionId: sessionId,
                                lat: 0,
                                lng: 0,
                              );
                          if (context.mounted) {
                            Navigator.pop(context);
                            ref.invalidate(sessionRecordsProvider(sessionId));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Marked ${student['full_name']} as present',
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            String errorMessage = 'Error: $e';
                            if (e.toString().contains('23505')) {
                              errorMessage =
                                  'Student is already marked present for this session.';
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(errorMessage),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
