typedef FactoryFn<T> = T Function();

class AppLocator {
  static final AppLocator I = AppLocator._();
  AppLocator._();

  final Map<Type, Object> _singletons = {};
  final Map<Type, FactoryFn<Object>> _factories = {};
  final Map<Type, FactoryFn<Object>> _lazySingletons = {};

  void registerSingleton<T>(T instance) {
    _singletons[T] = instance as Object;
  }

  void registerFactory<T>(FactoryFn<T> factory) {
    _factories[T] = () => factory() as Object;
  }

  /// Register a lazy singleton: created on first access, then cached
  void registerLazySingleton<T>(FactoryFn<T> factory) {
    _lazySingletons[T] = () => factory() as Object;
  }

  T get<T>() {
    // Check if already instantiated singleton
    final s = _singletons[T];
    if (s != null) return s as T;
    
    // Check if lazy singleton exists
    final lazy = _lazySingletons[T];
    if (lazy != null) {
      // Create instance and cache it
      final instance = lazy();
      _singletons[T] = instance;
      _lazySingletons.remove(T); // Remove factory after instantiation
      return instance as T;
    }
    
    // Fall back to factory
    final f = _factories[T];
    if (f != null) return f() as T;
    
    throw StateError('No registration for type $T');
  }
}

