import '../../../../core/errors/failure.dart';
import '../../../../core/utils/either.dart';
import '../entities/recent_search.dart';
import '../repositories/recent_search_repository.dart';

class GetRecentSearches {
  final RecentSearchRepository repository;
  const GetRecentSearches(this.repository);

  Future<Either<Failure, List<RecentSearch>>> call() =>
      repository.getRecentSearches();
}
