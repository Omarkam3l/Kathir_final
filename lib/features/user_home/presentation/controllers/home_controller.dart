import '../viewmodels/home_viewmodel.dart';

class HomeController {
  final HomeViewModel vm;
  const HomeController(this.vm);
  
  /// Smart refresh: only loads if needed
  Future<void> refresh() => vm.loadIfNeeded();
  
  /// Force refresh: always loads (for pull-to-refresh)
  Future<void> forceRefresh() => vm.loadAll(forceRefresh: true);
}

