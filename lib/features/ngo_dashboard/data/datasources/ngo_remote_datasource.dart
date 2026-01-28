import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../user_home/data/models/ngo_model.dart';
import '../../../user_home/domain/entities/ngo.dart';

abstract class NgoRemoteDataSource {
  Future<List<Ngo>> fetchVerifiedNgos();
}

class SupabaseNgoRemoteDataSource implements NgoRemoteDataSource {
  final SupabaseClient client;
  const SupabaseNgoRemoteDataSource(this.client);

  @override
  Future<List<Ngo>> fetchVerifiedNgos() async {
    final res = await client
        .from('ngos')
        .select()
        .eq('verified', true);
    final data = (res as List).cast<Map<String, dynamic>>();
    return data.map((e) => NgoModel.fromJson(e)).toList();
  }
}
