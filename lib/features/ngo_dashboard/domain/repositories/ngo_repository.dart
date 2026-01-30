import '../../../user_home/domain/entities/ngo.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/either.dart';

abstract class NgoRepository {
  Future<Either<Failure, List<Ngo>>> fetchVerifiedNgos();
}
