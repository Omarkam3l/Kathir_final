import '../repositories/profile_repository.dart';

/// Updates the profile's legal_docs_url after a document is uploaded to storage.
class UpdateProfileLegalDocsUseCase {
  final ProfileRepository repo;
  const UpdateProfileLegalDocsUseCase(this.repo);

  Future<void> call(String userId, String documentUrl) async {
    final res = await repo.createOrUpdate(userId, {'legal_docs_url': documentUrl});
    res.fold((l) => throw Exception(l.message), (_) {});
  }
}
