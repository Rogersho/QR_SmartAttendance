import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/class_provider.dart';
import '../../core/constants/app_colors.dart';
import 'package:animate_do/animate_do.dart';

class StudentDashboard extends ConsumerWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, profile.value?.fullName ?? 'Student'),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInUp(
                    duration: const Duration(milliseconds: 500),
                    child: profile.when(
                      data: (p) => p == null
                          ? const SizedBox()
                          : ref
                                .watch(studentStatsProvider(p.id))
                                .when(
                                  data: (stats) =>
                                      _AttendanceSummaryCard(stats: stats),
                                  loading: () => const _AttendanceSummaryCard(
                                    isLoading: true,
                                  ),
                                  error: (_, __) =>
                                      const _AttendanceSummaryCard(),
                                ),
                      loading: () =>
                          const _AttendanceSummaryCard(isLoading: true),
                      error: (_, __) => const _AttendanceSummaryCard(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FadeInUp(
                    duration: const Duration(milliseconds: 500),
                    delay: const Duration(milliseconds: 200),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Your Enrolled Courses',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          onPressed: () => context.push('/student/join'),
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeInUp(
                    duration: const Duration(milliseconds: 500),
                    delay: const Duration(milliseconds: 400),
                    child: const _EnrolledCoursesList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/student/join'),
        backgroundColor: AppColors.secondary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Join New Class',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, String name) {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.secondary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.secondary, AppColors.secondaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  Icons.person_pin_rounded,
                  size: 150,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello,',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.white),
          onPressed: () => ProviderScope.containerOf(
            context,
          ).read(authControllerProvider.notifier).signOut(),
        ),
      ],
    );
  }
}

class _AttendanceSummaryCard extends StatelessWidget {
  final Map<String, dynamic>? stats;
  final bool isLoading;

  const _AttendanceSummaryCard({this.stats, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 120,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final totalClasses = stats?['totalClasses'] ?? 0;
    final totalAttendance = stats?['totalAttendance'] ?? 0;
    final rateStr = stats?['attendanceRate'] ?? '0%';
    final rate = double.tryParse(rateStr.replaceAll('%', '')) ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Overall Attendance',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  rateStr,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Present: $totalAttendance / In $totalClasses Classes',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              value: rate / 100,
              strokeWidth: 10,
              backgroundColor: Colors.grey[100],
              color: AppColors.secondary,
              strokeCap: StrokeCap.round,
            ),
          ),
        ],
      ),
    );
  }
}

class _EnrolledCoursesList extends ConsumerWidget {
  const _EnrolledCoursesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(classListProvider);

    return classesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (classes) {
        if (classes.isEmpty) {
          return const Center(
            child: Text('You are not enrolled in any classes.'),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: classes.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final cls = classes[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[100]!),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.bookmark_rounded,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cls.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          cls.description ?? 'No teacher info',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: AppColors.secondary,
                    ),
                    onPressed: () =>
                        _showModulePicker(context, ref, cls.id, cls.name),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showModulePicker(
    BuildContext context,
    WidgetRef ref,
    String classId,
    String className,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final coursesAsync = ref.watch(courseListProvider(classId));

            return Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Module for $className',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  coursesAsync.when(
                    data: (courses) {
                      if (courses.isEmpty) {
                        return const Center(
                          child: Text('No modules found for this class.'),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        itemCount: courses.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final course = courses[index];
                          return ListTile(
                            leading: const Icon(
                              Icons.book_rounded,
                              color: AppColors.secondary,
                            ),
                            title: Text(course.name),
                            subtitle: Text(course.code ?? 'No code'),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              context.push(
                                '/student/scan',
                                extra: {
                                  'courseId': course.id,
                                  'courseName': course.name,
                                },
                              );
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey[200]!),
                            ),
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('Error: $err')),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
