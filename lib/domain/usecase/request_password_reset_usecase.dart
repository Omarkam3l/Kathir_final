import '../repo/auth_repository.dart';

class RequestPasswordResetUseCase {
  final AuthRepository repo;
  const RequestPasswordResetUseCase(this.repo);
  Future<void> call(String email) => repo.requestPasswordReset(email);
}
