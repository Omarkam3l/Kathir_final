import '../../../../core/errors/failure.dart';
import '../../../../core/utils/either.dart';
import '../repositories/recent_search_repository.dart';

class ClearRecentSearches {
  final RecentSearchRepository repository;
  const ClearRecentSearches(this.repository);

  Future<Either<Failure, void>> call() => repository.clearAllSearches();
}
