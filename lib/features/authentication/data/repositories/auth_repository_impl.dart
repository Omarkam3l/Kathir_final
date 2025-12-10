import '../../../../core/errors/failure.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remote;
  const AuthRepositoryImpl(this.remote);

  @override
  Future<Either<Failure, UserEntity>> signIn(
      String email, String password) async {
    try {
      final u = await remote.signIn(email, password);
      return Right(u);
    } catch (e) {
      return Left(Failure('signIn failed', cause: e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signUpUser(
      String fullName, String email, String password) async {
    try {
      final u = await remote.signUpUser(fullName, email, password);
      return Right(u);
    } catch (e) {
      return Left(Failure('signUpUser failed', cause: e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signUpNGO(
      String orgName, String fullName, String email, String password,
      {String? phone}) async {
    try {
      final u = await remote.signUpNGO(orgName, fullName, email, password,
          phone: phone);
      return Right(u);
    } catch (e) {
      return Left(Failure('signUpNGO failed', cause: e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signUpRestaurant(
      String orgName, String fullName, String email, String password,
      {String? phone}) async {
    try {
      final u = await remote
          .signUpRestaurant(orgName, fullName, email, password, phone: phone);
      return Right(u);
    } catch (e) {
      return Left(Failure('signUpRestaurant failed', cause: e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async {
    try {
      final u = await remote.signInWithGoogle();
      return Right(u);
    } catch (e) {
      return Left(Failure('signInWithGoogle failed', cause: e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithFacebook() async {
    try {
      final u = await remote.signInWithFacebook();
      return Right(u);
    } catch (e) {
      return Left(Failure('signInWithFacebook failed', cause: e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithApple() async {
    try {
      final u = await remote.signInWithApple();
      return Right(u);
    } catch (e) {
      return Left(Failure('signInWithApple failed', cause: e));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remote.signOut();
      return const Right(null);
    } catch (e) {
      return Left(Failure('signOut failed', cause: e));
    }
  }

  @override
  Future<Either<Failure, String>> uploadDocuments(
      String userId, String fileName, List<int> bytes) async {
    try {
      final url = await remote.uploadDocuments(userId, fileName, bytes);
      return Right(url);
    } catch (e) {
      return Left(Failure('uploadDocuments failed', cause: e));
    }
  }
}
