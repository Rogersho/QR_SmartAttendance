import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../services/supabase_service.dart';
import '../models/profile_model.dart';

final supabaseServiceProvider = Provider((ref) => SupabaseService());

final authStateProvider = StreamProvider<sb.AuthState>((ref) {
  return ref.watch(supabaseServiceProvider).authStateChanges;
});

final currentUserProvider = Provider<sb.User?>((ref) {
  final authState = ref.watch(authStateProvider).value;
  return authState?.session?.user ??
      ref.watch(supabaseServiceProvider).currentUser;
});

final profileProvider = FutureProvider<ProfileModel?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return await ref.watch(supabaseServiceProvider).getProfile(user.id);
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  final SupabaseService _service;
  AuthController(this._service) : super(const AsyncValue.data(null));

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _service.signIn(email, password);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? title,
    String? institution,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _service.signUp(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
        title: title,
        institution: institution,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
      return AuthController(ref.watch(supabaseServiceProvider));
    });
