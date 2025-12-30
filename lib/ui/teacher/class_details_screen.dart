import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/class_provider.dart';
import '../../core/constants/app_colors.dart';
import 'package:animate_do/animate_do.dart';
import 'session_setup_screen.dart';
import 'course_attendance_table_screen.dart';

class ClassDetailsScreen extends ConsumerWidget {
  final String classId;
  final String className;

  const ClassDetailsScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(courseListProvider(classId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(className),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: coursesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (courses) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildActionCard(
                        context,
                        title: 'Take Attendance',
                        subtitle: 'Start a new session for this class',
                        icon: Icons.qr_code_scanner_rounded,
                        color: AppColors.primary,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SessionSetupScreen(
                                classId: classId,
                                className: className,
                                courses: courses,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Modules / Subjects',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              if (courses.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('No modules added yet.')),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final course = courses[index];
                      return FadeInUp(
                        duration: const Duration(milliseconds: 400),
                        delay: Duration(milliseconds: 100 * index),
                        animate: true,
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(
                                0.1,
                              ),
                              child: const Icon(
                                Icons.book_outlined,
                                color: AppColors.primary,
                              ),
                            ),
                            title: Text(
                              course.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(course.code ?? 'No code'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CourseAttendanceTableScreen(
                                        courseId: course.id,
                                        courseName: course.name,
                                        classId: classId,
                                        className: className,
                                      ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    }, childCount: courses.length),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {}, // Add module
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return FadeInDown(
      duration: const Duration(milliseconds: 500),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
