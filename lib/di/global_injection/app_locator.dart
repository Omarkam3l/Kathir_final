typedef FactoryFn<T> = T Function();

class AppLocator {
  static final AppLocator I = AppLocator._();
  AppLocator._();

  final Map<Type, Object> _singletons = {};
  final Map<Type, FactoryFn<Object>> _factories = {};

  void registerSingleton<T>(T instance) {
    _singletons[T] = instance as Object;
  }

  void registerFactory<T>(FactoryFn<T> factory) {
    _factories[T] = () => factory() as Object;
  }

  T get<T>() {
    final s = _singletons[T];
    if (s != null) return s as T;
    final f = _factories[T];
    if (f != null) return f() as T;
    throw StateError('No registration for type');
  }
}

