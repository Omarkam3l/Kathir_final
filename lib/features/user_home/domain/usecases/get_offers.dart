import '../../../../core/errors/failure.dart';
import '../../../../core/utils/either.dart';
import '../entities/offer.dart';
import '../repositories/home_repository.dart';

class GetOffers {
  final HomeRepository repo;
  const GetOffers(this.repo);
  Future<Either<Failure, List<Offer>>> call() => repo.getOffers();
}

