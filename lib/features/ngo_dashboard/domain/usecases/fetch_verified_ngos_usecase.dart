import '../repositories/ngo_repository.dart';

class FetchVerifiedNgosUseCase {
  final NgoRepository repo;
  const FetchVerifiedNgosUseCase(this.repo);

  Future call() => repo.fetchVerifiedNgos();
}
