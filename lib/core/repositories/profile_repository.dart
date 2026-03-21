import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';

class ProfileRepository {
  ProfileRepository(this._client);
  final SupabaseClient _client;

  Future<Profile?> getProfile(String userId) async {
    final res = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (res == null) return null;
    return Profile.fromMap(res as Map<String, dynamic>);
  }

  Future<void> updateProfile(String userId, {String? fullName}) async {
    await _client.from('profiles').update({
      'full_name': fullName,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }
}
