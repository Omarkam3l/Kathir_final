import '../../../../core/errors/failure.dart';
import '../../../../core/utils/either.dart';
import '../repositories/recent_search_repository.dart';

class DeleteRecentSearch {
  final RecentSearchRepository repository;
  const DeleteRecentSearch(this.repository);

  Future<Either<Failure, void>> call(String id) =>
      repository.deleteSearch(id);
}
