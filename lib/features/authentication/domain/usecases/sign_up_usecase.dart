import '../../../../core/errors/failure.dart';
import '../../../../core/utils/either.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

enum SignUpRole { user, ngo, restaurant }

class SignUpUseCase {
  final AuthRepository repo;
  const SignUpUseCase(this.repo);
  Future<Either<Failure, UserEntity>> call({
    required SignUpRole role,
    required String fullName,
    required String email,
    required String password,
    String? organizationName,
    String? phone,
  }) {
    switch (role) {
      case SignUpRole.user:
        return repo.signUpUser(fullName, email, password);
      case SignUpRole.ngo:
        return repo.signUpNGO(organizationName ?? '', fullName, email, password, phone: phone);
      case SignUpRole.restaurant:
        return repo.signUpRestaurant(organizationName ?? '', fullName, email, password, phone: phone);
    }
  }
}

