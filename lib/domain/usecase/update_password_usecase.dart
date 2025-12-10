import '../repo/auth_repository.dart';

class UpdatePasswordUseCase {
  final AuthRepository repo;
  const UpdatePasswordUseCase(this.repo);
  Future<void> call(String newPassword) => repo.updatePassword(newPassword);
}
