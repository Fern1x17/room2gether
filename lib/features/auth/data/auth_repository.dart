import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';

abstract class AuthRepository {
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required DateTime birthdate,
  });

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required DateTime birthdate,
  }) {
    // El trigger handle_new_user lee 'birthdate' (yyyy-MM-dd) de los metadatos.
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {'birthdate': birthdate.toIso8601String().substring(0, 10)},
    );
  }

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signOut() {
    return _client.auth.signOut();
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(supabase);
});
