import 'package:go_router/go_router.dart';
import 'boss_chat_screen.dart';

List<GoRoute> bossChatRoutes() => [
  GoRoute(
    path: '/boss-chat',
    builder: (context, state) => const BossChatScreen(),
  ),
];
