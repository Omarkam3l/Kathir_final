import '../../../../core/errors/failure.dart';
import '../../../../core/utils/either.dart';
import '../repositories/recent_search_repository.dart';

class SaveRecentSearch {
  final RecentSearchRepository repository;
  const SaveRecentSearch(this.repository);

  Future<Either<Failure, void>> call(String query) =>
      repository.saveSearch(query);
}
