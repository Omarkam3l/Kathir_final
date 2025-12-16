import '../../domain/entities/user_entity.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/either.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> signIn(String email, String password);
  Future<Either<Failure, UserEntity>> signUpUser(
      String fullName, String email, String password);
  Future<Either<Failure, UserEntity>> signUpNGO(
      String orgName, String fullName, String email, String password,
      {String? phone});
  Future<Either<Failure, UserEntity>> signUpRestaurant(
      String orgName, String fullName, String email, String password,
      {String? phone});
  Future<Either<Failure, UserEntity>> signInWithGoogle();
  Future<Either<Failure, UserEntity>> signInWithFacebook();
  Future<Either<Failure, UserEntity>> signInWithApple();
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, String>> uploadDocuments(
      String userId, String fileName, List<int> bytes);
  Future<Either<Failure, void>> sendPasswordResetEmail(String email);
  Future<Either<Failure, UserEntity>> verifySignupOtp(String email, String otp);
  Future<Either<Failure, void>> verifyRecoveryOtp(String email, String otp);
  Future<Either<Failure, void>> updatePassword(String newPassword);
}
