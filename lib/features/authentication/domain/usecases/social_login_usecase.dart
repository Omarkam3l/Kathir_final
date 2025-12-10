import '../../../../core/errors/failure.dart';
import '../../../../core/utils/either.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show OAuthProvider;

class SocialLoginUseCase {
  final AuthRepository repo;
  const SocialLoginUseCase(this.repo);

  Future<Either<Failure, UserEntity>> call(OAuthProvider provider) {
    switch (provider) {
      case OAuthProvider.google:
        return repo.signInWithGoogle();
      case OAuthProvider.facebook:
        return repo.signInWithFacebook();
      case OAuthProvider.apple:
        return repo.signInWithApple();
      default:
        return repo.signInWithGoogle();
    }
  }
}
