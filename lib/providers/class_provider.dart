import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/class_model.dart';
import '../models/profile_model.dart';
import 'auth_provider.dart';

final classListProvider = FutureProvider<List<ClassModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final profile = await ref.watch(profileProvider.future);
  if (profile == null) return [];

  if (profile.role == UserRole.teacher) {
    return await ref.watch(supabaseServiceProvider).getTeacherClasses(user.id);
  } else {
    return await ref
        .watch(supabaseServiceProvider)
        .getStudentEnrolledClasses(user.id);
  }
});

final courseListProvider = FutureProvider.family<List<CourseModel>, String>((
  ref,
  classId,
) async {
  return await ref.watch(supabaseServiceProvider).getClassCourses(classId);
});

final teacherStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, teacherId) async {
      return await ref
          .watch(supabaseServiceProvider)
          .getTeacherStats(teacherId);
    });

final studentStatsProvider =
    StreamProvider.family<Map<String, dynamic>, String>((ref, studentId) {
      return ref.watch(supabaseServiceProvider).streamStudentStats(studentId);
    });
