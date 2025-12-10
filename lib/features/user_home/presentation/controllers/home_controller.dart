import '../viewmodels/home_viewmodel.dart';

class HomeController {
  final HomeViewModel vm;
  const HomeController(this.vm);
  Future<void> refresh() => vm.loadAll();
}

