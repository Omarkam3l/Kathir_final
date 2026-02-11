import 'package:supabase/supabase.dart';
import '../../../di/global_injection/app_locator.dart';
import '../data/datasources/home_remote_datasource.dart';
import '../data/repositories/home_repository_impl.dart';
import '../domain/repositories/home_repository.dart';
import '../domain/usecases/get_offers.dart';
import '../domain/usecases/get_top_rated_restaurants.dart';
import '../domain/usecases/get_available_meals.dart';
import '../presentation/viewmodels/home_viewmodel.dart';

void registerUserHomeDependencies() {
  final client = AppLocator.I.get<SupabaseClient>();
  final ds = SupabaseHomeRemoteDataSource(client);
  AppLocator.I.registerSingleton<HomeRemoteDataSource>(ds);

  final repo = HomeRepositoryImpl(ds);
  AppLocator.I.registerSingleton<HomeRepository>(repo);

  AppLocator.I.registerFactory<GetOffers>(() => GetOffers(repo));
  AppLocator.I.registerFactory<GetTopRatedRestaurants>(() => GetTopRatedRestaurants(repo));
  AppLocator.I.registerFactory<GetAvailableMeals>(() => GetAvailableMeals(repo));

  // Changed from registerFactory to registerLazySingleton for state persistence
  AppLocator.I.registerLazySingleton<HomeViewModel>(() => HomeViewModel(
        getOffers: AppLocator.I.get<GetOffers>(),
        getTopRestaurants: AppLocator.I.get<GetTopRatedRestaurants>(),
        getMeals: AppLocator.I.get<GetAvailableMeals>(),
      ));
}

