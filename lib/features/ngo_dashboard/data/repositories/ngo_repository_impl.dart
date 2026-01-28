import '../../../../core/errors/failure.dart';
import '../../../../core/utils/either.dart';
import '../datasources/ngo_remote_datasource.dart';
import '../../../user_home/domain/entities/ngo.dart';

class NgoRepositoryImpl {
  final NgoRemoteDataSource remote;
  const NgoRepositoryImpl(this.remote);

  Future<Either<Failure, List<Ngo>>> fetchVerifiedNgos() async {
    try {
      final r = await remote.fetchVerifiedNgos();
      return Right(r);
    } catch (e) {
      return Left(Failure('fetchVerifiedNgos failed', cause: e));
    }
  }
}
