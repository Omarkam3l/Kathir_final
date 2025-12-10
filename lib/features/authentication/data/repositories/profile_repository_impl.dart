import '../../../../core/errors/failure.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remote;
  const ProfileRepositoryImpl(this.remote);

  @override
  Future<Either<Failure, ProfileEntity>> getById(String id) async {
    try {
      final p = await remote.getById(id);
      return Right(p);
    } catch (e) {
      return Left(Failure('getById failed', cause: e));
    }
  }

  @override
  Future<Either<Failure, ProfileEntity>> createOrUpdate(String id, Map<String, dynamic> data) async {
    try {
      final p = await remote.createOrUpdate(id, data);
      return Right(p);
    } catch (e) {
      return Left(Failure('createOrUpdate failed', cause: e));
    }
  }
}
