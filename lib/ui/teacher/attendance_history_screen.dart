import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import 'package:animate_do/animate_do.dart';
import 'session_records_screen.dart';
import '../../providers/attendance_provider.dart';

class AttendanceHistoryScreen extends ConsumerWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).value;
    if (profile == null)
      return const Center(child: CircularProgressIndicator());

    final coursesAsync = ref.watch(teacherCoursesProvider(profile.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Attendance History'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: coursesAsync.when(
        data: (courses) {
          if (courses.isEmpty) {
            return const Center(child: Text('You have no courses yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return FadeInUp(
                duration: const Duration(milliseconds: 400),
                delay: Duration(milliseconds: 100 * index),
                child: _CourseHistoryCard(course: course),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _CourseHistoryCard extends ConsumerWidget {
  final Map<String, dynamic> course;
  const _CourseHistoryCard({required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.book_rounded, color: AppColors.primary),
        ),
        title: Text(
          course['name'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(course['code'] ?? 'No code'),
        children: [_SessionsList(courseId: course['id'])],
      ),
    );
  }
}

class _SessionsList extends ConsumerWidget {
  final String courseId;
  const _SessionsList({required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(courseSessionsProvider(courseId));

    return sessionsAsync.when(
      data: (sessions) {
        if (sessions.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No attendance sessions found.'),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sessions.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final session = sessions[index];
            final dateStr = session['attendance_date'];
            final date = dateStr != null
                ? DateTime.parse(dateStr)
                : DateTime.now();
            final count = session['attendance_records']?[0]?['count'] ?? 0;
            final courseData = session['courses'] as Map<String, dynamic>?;

            return ListTile(
              title: Text(
                dateStr != null && dateStr.isNotEmpty
                    ? DateFormat('EEEE, MMM d, yyyy').format(date)
                    : 'Unknown Date',
              ),
              subtitle: Text('Present: $count Students'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SessionRecordsScreen(
                      sessionId: session['id'] ?? '',
                      sessionDate: dateStr ?? DateTime.now().toIso8601String(),
                      courseName: courseData?['name'] ?? 'Course',
                      classId: courseData?['class_id'],
                      courseId: courseId,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }
}
