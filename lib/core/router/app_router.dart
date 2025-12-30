import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../ui/auth/login_screen.dart';
import '../../ui/auth/signup_screen.dart';
import '../../ui/teacher/teacher_dashboard.dart';
import '../../ui/student/student_dashboard.dart';
import '../../ui/student/join_class_screen.dart';
import '../../ui/student/qr_scanner_screen.dart';
import '../../models/profile_model.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final profile = ref.watch(profileProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final loggingIn =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';

      final user = authState.value?.session?.user;

      if (user == null) {
        // If not logged in and not on auth pages, go to login
        return loggingIn ? null : '/login';
      }

      // If logged in but on auth pages, decide where to go
      if (loggingIn) {
        if (profile.isLoading) return null; // Wait for profile

        final profileData = profile.value;
        if (profileData == null) {
          // Profile failed to load or doesn't exist yet
          return null;
        }

        return profileData.role == UserRole.teacher ? '/teacher' : '/student';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/teacher',
        builder: (context, state) => const TeacherDashboard(),
      ),
      GoRoute(
        path: '/student',
        builder: (context, state) => const StudentDashboard(),
        routes: [
          GoRoute(
            path: 'join',
            builder: (context, state) => const JoinClassScreen(),
          ),
          GoRoute(
            path: 'scan',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return QRScannerScreen(
                courseId: extra['courseId'],
                courseName: extra['courseName'],
              );
            },
          ),
        ],
      ),
    ],
  );
});
