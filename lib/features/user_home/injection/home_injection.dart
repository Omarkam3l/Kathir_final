import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../di/global_injection/app_locator.dart';
import '../data/datasources/home_remote_datasource.dart';
import '../data/datasources/recent_search_remote_datasource.dart';
import '../data/repositories/home_repository_impl.dart';
import '../data/repositories/recent_search_repository_impl.dart';
import '../domain/repositories/home_repository.dart';
import '../domain/repositories/recent_search_repository.dart';
import '../domain/usecases/get_offers.dart';
import '../domain/usecases/get_top_rated_restaurants.dart';
import '../domain/usecases/get_available_meals.dart';
import '../domain/usecases/get_recent_searches.dart';
import '../domain/usecases/save_recent_search.dart';
import '../domain/usecases/delete_recent_search.dart';
import '../domain/usecases/clear_recent_searches.dart';
import '../presentation/viewmodels/home_viewmodel.dart';
import '../presentation/viewmodels/recent_search_viewmodel.dart';

void registerUserHomeDependencies() {
  final client = AppLocator.I.get<SupabaseClient>();

  // Home
  final ds = SupabaseHomeRemoteDataSource(client);
  AppLocator.I.registerSingleton<HomeRemoteDataSource>(ds);

  final repo = HomeRepositoryImpl(ds);
  AppLocator.I.registerSingleton<HomeRepository>(repo);

  AppLocator.I.registerFactory<GetOffers>(() => GetOffers(repo));
  AppLocator.I.registerFactory<GetTopRatedRestaurants>(() => GetTopRatedRestaurants(repo));
  AppLocator.I.registerFactory<GetAvailableMeals>(() => GetAvailableMeals(repo));

  AppLocator.I.registerLazySingleton<HomeViewModel>(() => HomeViewModel(
        getOffers: AppLocator.I.get<GetOffers>(),
        getTopRestaurants: AppLocator.I.get<GetTopRatedRestaurants>(),
        getMeals: AppLocator.I.get<GetAvailableMeals>(),
      ));

  // Recent Searches
  final recentDs = SupabaseRecentSearchDataSource(client);
  AppLocator.I.registerSingleton<RecentSearchRemoteDataSource>(recentDs);

  final recentRepo = RecentSearchRepositoryImpl(recentDs);
  AppLocator.I.registerSingleton<RecentSearchRepository>(recentRepo);

  AppLocator.I.registerLazySingleton<RecentSearchViewModel>(() => RecentSearchViewModel(
        getRecentSearches: GetRecentSearches(recentRepo),
        saveRecentSearch: SaveRecentSearch(recentRepo),
        deleteRecentSearch: DeleteRecentSearch(recentRepo),
        clearRecentSearches: ClearRecentSearches(recentRepo),
      ));
}

