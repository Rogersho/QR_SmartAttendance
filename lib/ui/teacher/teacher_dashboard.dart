import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/class_provider.dart';
import '../../core/constants/app_colors.dart';
import 'create_class_screen.dart';
import 'class_details_screen.dart';
import 'package:animate_do/animate_do.dart';
import 'attendance_history_screen.dart';

class TeacherDashboard extends ConsumerStatefulWidget {
  const TeacherDashboard({super.key});

  @override
  ConsumerState<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends ConsumerState<TeacherDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final statsAsync = ref.watch(teacherStatsProvider(profile.value?.id ?? ''));

    final List<Widget> pages = [
      _buildHome(profile, statsAsync),
      const AttendanceHistoryScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded),
              label: 'Attendance',
            ),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateClassScreen(),
                ),
              ),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'New Class',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildHome(AsyncValue profile, AsyncValue statsAsync) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(context, profile.value?.fullName ?? 'Teacher'),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInUp(
                  duration: const Duration(milliseconds: 500),
                  child: statsAsync.when(
                    data: (stats) => _StatsSection(stats: stats),
                    loading: () => const _StatsSection(isLoading: true),
                    error: (err, st) => const _StatsSection(),
                  ),
                ),
                const SizedBox(height: 32),
                FadeInUp(
                  duration: const Duration(milliseconds: 500),
                  delay: const Duration(milliseconds: 200),
                  child: _buildSectionHeader('Your Classes', onSeeAll: () {}),
                ),
                const SizedBox(height: 16),
                FadeInUp(
                  duration: const Duration(milliseconds: 500),
                  delay: const Duration(milliseconds: 400),
                  child: const _ClassesList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context, String name) {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  Icons.school_rounded,
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
                      'Welcome back,',
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

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        if (onSeeAll != null)
          TextButton(onPressed: onSeeAll, child: const Text('See All')),
      ],
    );
  }
}

class _StatsSection extends StatelessWidget {
  final Map<String, dynamic>? stats;
  final bool isLoading;

  const _StatsSection({this.stats, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Classes',
            value: isLoading ? '...' : (stats?['totalClasses'] ?? '0'),
            icon: Icons.class_rounded,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: 'Attendance',
            value: isLoading ? '...' : (stats?['totalAttendance'] ?? '0'),
            icon: Icons.check_circle_rounded,
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassesList extends ConsumerWidget {
  const _ClassesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(classListProvider);

    return classesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (classes) {
        if (classes.isEmpty) {
          return const Center(
            child: Text('No classes found. Create one to get started!'),
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
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.book_rounded,
                      color: AppColors.primary,
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
                          cls.description ?? 'No description',
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
                      Icons.chevron_right_rounded,
                      color: AppColors.primary,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ClassDetailsScreen(
                            classId: cls.id,
                            className: cls.name,
                          ),
                        ),
                      );
                    },
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
