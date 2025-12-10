import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/supabase/supabase_helper.dart';
import '../models/profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<ProfileModel> getById(String id);
  Future<ProfileModel> createOrUpdate(String id, Map<String, dynamic> data);
}

class SupabaseProfileRemoteDataSource implements ProfileRemoteDataSource {
  final SupabaseClient client;
  final SupabaseHelper helper;
  const SupabaseProfileRemoteDataSource(this.client, this.helper);

  @override
  Future<ProfileModel> getById(String id) async {
    final rows = await helper.selectFiltered('profiles', {'id': id});
    return ProfileModel.fromJson(rows.first);
  }

  @override
  Future<ProfileModel> createOrUpdate(String id, Map<String, dynamic> data) async {
    await helper.upsertProfile(id, data);
    final rows = await helper.selectFiltered('profiles', {'id': id});
    return ProfileModel.fromJson(rows.first);
  }
}
