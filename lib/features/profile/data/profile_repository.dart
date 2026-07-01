import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../domain/models/profile.dart';

abstract class ProfileRepository {
  Future<Profile> fetchMyProfile();

  Future<void> updateProfile(Profile profile);

  Future<String> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String fileExtension,
  });
}

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<Profile> fetchMyProfile() async {
    final userId = _client.auth.currentUser!.id;
    final row = await _client.from('profiles').select().eq('id', userId).single();
    return Profile.fromMap(row);
  }

  @override
  Future<void> updateProfile(Profile profile) async {
    await _client.from('profiles').update({
      'display_name': profile.displayName,
      'bio': profile.bio,
      'avatar_url': profile.avatarUrl,
      'city': profile.city,
      'budget_min': profile.budgetMin,
      'budget_max': profile.budgetMax,
      'is_smoker': profile.isSmoker,
      'has_pets': profile.hasPets,
      'cleanliness_level': profile.cleanlinessLevel,
      'schedule': profile.schedule,
    }).eq('id', profile.id);
  }

  @override
  Future<String> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final path = '$userId/avatar.$fileExtension';
    await _client.storage
        .from('avatars')
        .uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));
    return _client.storage.from('avatars').getPublicUrl(path);
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return SupabaseProfileRepository(supabase);
});
