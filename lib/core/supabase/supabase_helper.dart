import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'supabase_helper_exception.dart';

String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? 'https://vpxghgwfswotlwtulqrz.supabase.co';
String get supabaseKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
class SupabaseHelper {
  SupabaseClient get client => Supabase.instance.client;

  Future<AuthResponse> signIn(String email, String password) async {
    try {
      return await client.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      throw SupabaseHelperException('signIn failed');
    }
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    try {
      return await client.auth.signUp(email: email, password: password, data: data);
    } catch (e) {
      throw SupabaseHelperException('signUp failed');
    }
  }

  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      throw SupabaseHelperException('signOut failed');
    }
  }

  Future<void> signInWithOAuth(OAuthProvider provider, {String? redirectTo}) async {
    try {
      await client.auth.signInWithOAuth(provider, redirectTo: redirectTo);
    } catch (e) {
      throw SupabaseHelperException('oauth failed');
    }
  }

  Future<List<Map<String, dynamic>>> selectAll(String table) async {
    try {
      final res = await client.from(table).select();
      return (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw SupabaseHelperException('selectAll failed');
    }
  }

  Future<List<Map<String, dynamic>>> selectFiltered(
    String table,
    Map<String, dynamic> filters,
  ) async {
    try {
      var qb = client.from(table).select();
      for (final entry in filters.entries) {
        qb = qb.eq(entry.key, entry.value);
      }
      final res = await qb;
      return (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw SupabaseHelperException('selectFiltered failed');
    }
  }

  Future<void> insert(String table, Map<String, dynamic> data) async {
    try {
      await client.from(table).insert(data);
    } catch (e) {
      throw SupabaseHelperException('insert failed');
    }
  }

  Future<void> update(
      String table, Map<String, dynamic> data, String id) async {
    try {
      await client.from(table).update(data).eq('id', id);
    } catch (e) {
      throw SupabaseHelperException('update failed');
    }
  }

  Future<void> delete(String table, String id) async {
    try {
      await client.from(table).delete().eq('id', id);
    } catch (e) {
      throw SupabaseHelperException('delete failed');
    }
  }

  Future<String> uploadDocument({
    required String bucket,
    required String path,
    required List<int> bytes,
    String contentType = 'application/octet-stream',
  }) async {
    try {
      final fp = await client.storage.from(bucket).uploadBinary(
            path,
            Uint8List.fromList(bytes),
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );
      return client.storage.from(bucket).getPublicUrl(fp);
    } catch (e) {
      throw SupabaseHelperException('uploadDocument failed: $e');
    }
  }

  Future<void> upsertProfile(String id, Map<String, dynamic> data) async {
    try {
      await client.from('profiles').upsert({'id': id, ...data});
    } catch (e) {
      throw SupabaseHelperException('upsertProfile failed');
    }
  }
}
