import 'package:flutter/foundation.dart';
import '../../domain/usecases/fetch_verified_ngos_usecase.dart';
import '../../../user_home/domain/entities/ngo.dart';

class NgoDashboardViewModel extends ChangeNotifier {
  final FetchVerifiedNgosUseCase fetchVerifiedNgos;
  List<Ngo> ngos = [];
  bool isLoading = false;
  String? error;

  NgoDashboardViewModel(this.fetchVerifiedNgos);

  Future<void> loadNgos() async {
    isLoading = true;
    error = null;
    notifyListeners();
    final res = await fetchVerifiedNgos();
    res.fold(
      (l) => error = l.message,
      (r) => ngos = r,
    );
    isLoading = false;
    notifyListeners();
  }
}
