import '../../../../core/errors/failure.dart';
import '../../../../core/utils/either.dart';
import '../entities/recent_search.dart';

abstract class RecentSearchRepository {
  Future<Either<Failure, List<RecentSearch>>> getRecentSearches();
  Future<Either<Failure, void>> saveSearch(String query);
  Future<Either<Failure, void>> deleteSearch(String id);
  Future<Either<Failure, void>> clearAllSearches();
}
