import 'package:flutter/foundation.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/recent_search.dart';
import '../../domain/repositories/recent_search_repository.dart';
import '../datasources/recent_search_remote_datasource.dart';

class RecentSearchRepositoryImpl implements RecentSearchRepository {
  final RecentSearchRemoteDataSource remote;
  const RecentSearchRepositoryImpl(this.remote);

  @override
  Future<Either<Failure, List<RecentSearch>>> getRecentSearches() async {
    try {
      final result = await remote.getRecentSearches();
      return Right(result);
    } catch (e) {
      debugPrint('[RecentSearch] getRecentSearches error: $e');
      return const Right([]); // Return empty list on error (non-blocking)
    }
  }

  @override
  Future<Either<Failure, void>> saveSearch(String query) async {
    try {
      await remote.saveSearch(query);
      return const Right(null);
    } catch (e) {
      debugPrint('[RecentSearch] saveSearch error: $e');
      return const Right(null); // Silent fail – search must continue
    }
  }

  @override
  Future<Either<Failure, void>> deleteSearch(String id) async {
    try {
      await remote.deleteSearch(id);
      return const Right(null);
    } catch (e) {
      debugPrint('[RecentSearch] deleteSearch error: $e');
      return Left(Failure('Failed to delete search', cause: e));
    }
  }

  @override
  Future<Either<Failure, void>> clearAllSearches() async {
    try {
      await remote.clearAllSearches();
      return const Right(null);
    } catch (e) {
      debugPrint('[RecentSearch] clearAllSearches error: $e');
      return Left(Failure('Failed to clear searches', cause: e));
    }
  }
}
