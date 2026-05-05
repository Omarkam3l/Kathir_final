import 'package:flutter/foundation.dart';
import '../../domain/entities/recent_search.dart';
import '../../domain/usecases/get_recent_searches.dart';
import '../../domain/usecases/save_recent_search.dart';
import '../../domain/usecases/delete_recent_search.dart';
import '../../domain/usecases/clear_recent_searches.dart';

class RecentSearchViewModel extends ChangeNotifier {
  final GetRecentSearches _getRecentSearches;
  final SaveRecentSearch _saveRecentSearch;
  final DeleteRecentSearch _deleteRecentSearch;
  final ClearRecentSearches _clearRecentSearches;

  List<RecentSearch> searches = const [];
  bool isLoading = false;

  RecentSearchViewModel({
    required GetRecentSearches getRecentSearches,
    required SaveRecentSearch saveRecentSearch,
    required DeleteRecentSearch deleteRecentSearch,
    required ClearRecentSearches clearRecentSearches,
  })  : _getRecentSearches = getRecentSearches,
        _saveRecentSearch = saveRecentSearch,
        _deleteRecentSearch = deleteRecentSearch,
        _clearRecentSearches = clearRecentSearches;

  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    final result = await _getRecentSearches();
    result.fold(
      (_) => searches = const [],
      (list) => searches = list,
    );

    isLoading = false;
    notifyListeners();
  }

  Future<void> save(String query) async {
    if (query.trim().isEmpty) return;
    await _saveRecentSearch(query);
    await load();
  }

  Future<void> delete(String id) async {
    final result = await _deleteRecentSearch(id);
    result.fold(
      (_) {}, // Keep list unchanged on error
      (_) => searches = searches.where((s) => s.id != id).toList(),
    );
    notifyListeners();
  }

  Future<void> clearAll() async {
    final result = await _clearRecentSearches();
    result.fold(
      (_) {}, // Keep list unchanged on error
      (_) => searches = const [],
    );
    notifyListeners();
  }
}
