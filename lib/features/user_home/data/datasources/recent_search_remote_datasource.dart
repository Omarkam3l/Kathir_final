import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/recent_search.dart';

abstract class RecentSearchRemoteDataSource {
  Future<List<RecentSearch>> getRecentSearches();
  Future<void> saveSearch(String query);
  Future<void> deleteSearch(String id);
  Future<void> clearAllSearches();
}

class SupabaseRecentSearchDataSource implements RecentSearchRemoteDataSource {
  final SupabaseClient client;
  static const _table = 'recent_searches';
  static const _maxSearches = 5;

  const SupabaseRecentSearchDataSource(this.client);

  String? get _userId => client.auth.currentUser?.id;

  @override
  Future<List<RecentSearch>> getRecentSearches() async {
    final uid = _userId;
    if (uid == null) return [];

    final res = await client
        .from(_table)
        .select()
        .eq('user_id', uid)
        .order('searched_at', ascending: false)
        .limit(_maxSearches);

    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(_fromJson)
        .toList();
  }

  @override
  Future<void> saveSearch(String query) async {
    final uid = _userId;
    if (uid == null) return;

    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return;

    // Upsert: insert or update searched_at if query already exists
    await client.from(_table).upsert(
      {
        'user_id': uid,
        'query': trimmed,
        'searched_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'user_id,query',
    );

    // Enforce max 5: delete oldest rows beyond the limit
    await _enforceLimit(uid);
  }

  @override
  Future<void> deleteSearch(String id) async {
    final uid = _userId;
    if (uid == null) return;

    await client.from(_table).delete().eq('id', id).eq('user_id', uid);
  }

  @override
  Future<void> clearAllSearches() async {
    final uid = _userId;
    if (uid == null) return;

    await client.from(_table).delete().eq('user_id', uid);
  }

  Future<void> _enforceLimit(String uid) async {
    // Fetch all rows ordered oldest first
    final rows = await client
        .from(_table)
        .select('id')
        .eq('user_id', uid)
        .order('searched_at', ascending: true);

    final list = (rows as List).cast<Map<String, dynamic>>();
    if (list.length <= _maxSearches) return;

    // Delete the oldest rows that exceed the limit
    final toDelete = list
        .take(list.length - _maxSearches)
        .map((r) => r['id'] as String)
        .toList();

    await client.from(_table).delete().inFilter('id', toDelete);
  }

  RecentSearch _fromJson(Map<String, dynamic> json) => RecentSearch(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        query: json['query'] as String,
        searchedAt: DateTime.parse(json['searched_at'] as String),
      );
}
