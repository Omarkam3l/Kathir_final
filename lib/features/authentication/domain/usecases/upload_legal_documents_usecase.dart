import '../../../../core/errors/failure.dart';
import '../../../../core/utils/either.dart';
import '../repositories/auth_repository.dart';

class UploadLegalDocumentsUseCase {
  final AuthRepository repo;
  const UploadLegalDocumentsUseCase(this.repo);
  Future<Either<Failure, String>> call(String userId, String fileName, List<int> bytes) =>
      repo.uploadDocuments(userId, fileName, bytes);
}

