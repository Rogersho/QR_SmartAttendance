import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';
import 'auth_provider.dart';

final teacherCoursesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      teacherId,
    ) async {
      return ref.watch(supabaseServiceProvider).getTeacherCourses(teacherId);
    });

final courseSessionsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, courseId) {
      return ref.watch(supabaseServiceProvider).streamCourseSessions(courseId);
    });

final sessionRecordsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      sessionId,
    ) async {
      return ref.watch(supabaseServiceProvider).getSessionRecords(sessionId);
    });

final classStudentsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      classId,
    ) async {
      return ref
          .watch(supabaseServiceProvider)
          .getClassEnrolledStudents(classId);
    });

final courseRecordsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, courseId) {
      return ref
          .watch(supabaseServiceProvider)
          .streamCourseAttendanceRecords(courseId);
    });
