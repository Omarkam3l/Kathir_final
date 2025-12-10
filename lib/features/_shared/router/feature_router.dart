import 'package:go_router/go_router.dart';

typedef RouteModule = List<GoRoute> Function();

List<GoRoute> mergeRoutes(List<List<GoRoute>> modules) {
  final list = <GoRoute>[];
  for (final m in modules) {
    list.addAll(m);
  }
  return list;
}

