import 'package:flutter/material.dart';
import 'app/bootstrap/di_bootstrap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'features/_shared/providers/theme_provider.dart';
import 'features/authentication/presentation/blocs/auth_provider.dart';
import 'features/orders/presentation/controllers/orders_controller.dart';
import 'features/profile/presentation/providers/foodie_state.dart';
import 'features/authentication/presentation/viewmodels/auth_viewmodel.dart';
import 'di/global_injection/app_locator.dart';
import 'features/_shared/router/app_router.dart';
import 'core/supabase/supabase_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final hasConfig = supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;
  if (hasConfig) {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
    await bootstrapDI();
    runApp(const MyApp());
  } else {
    runApp(const MissingConfigApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppLocator.I.get<AuthViewModel>()),
        ChangeNotifierProvider(create: (_) => OrdersController()),
        ChangeNotifierProvider(create: (_) => FoodieState()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          final router = AppRouter.of(context);

          final lightBase = ThemeData.light(useMaterial3: true);
          final lightTheme = lightBase.copyWith(
            colorScheme: lightBase.colorScheme.copyWith(
              primary: const Color(0xFF4DD0E1),
            ),
          );

          final darkBase = ThemeData.dark(useMaterial3: true);
          final darkTheme = darkBase.copyWith(
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            dividerColor: Colors.white12,
            colorScheme: darkBase.colorScheme.copyWith(
              primary: const Color(0xFF4DD0E1),
              surface: const Color(0xFF1E1E1E),
              onSurface: Colors.white,
              onPrimary: Colors.white,
            ),
            textTheme: darkBase.textTheme.apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ).copyWith(
              bodyMedium: const TextStyle(color: Colors.white70),
              bodySmall: const TextStyle(color: Colors.white60),
              titleSmall: const TextStyle(color: Colors.white70),
            ),
            iconTheme: const IconThemeData(color: Colors.white70),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF121212),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4DD0E1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4DD0E1),
                side: const BorderSide(color: Color(0xFF4DD0E1)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF4DD0E1),
              ),
            ),
            inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              fillColor: Color(0xFF1E1E1E),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              labelStyle: TextStyle(color: Colors.white70),
              hintStyle: TextStyle(color: Colors.white60),
            ),
          );

          return MaterialApp.router(
            title: 'Flutter Demo',
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: theme.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            debugShowCheckedModeBanner: false,
            routerConfig: router,
          );
        },
      ),
    );
  }
}

class MissingConfigApp extends StatelessWidget {
  const MissingConfigApp({super.key});
  @override
  Widget build(BuildContext context) {
    final base = ThemeData.light(useMaterial3: true);
    return MaterialApp(
      title: 'Configuration Required',
      theme: base.copyWith(
        colorScheme: base.colorScheme.copyWith(primary: Colors.deepPurple),
      ),
      home: const MissingConfigScreen(),
    );
  }
}

class MissingConfigScreen extends StatelessWidget {
  const MissingConfigScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Missing Supabase configuration',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 12),
              Text(
                'Run with --dart-define SUPABASE_URL=YOUR_URL and SUPABASE_ANON_KEY=YOUR_KEY',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Example (web-server): flutter run -d web-server --no-devtools --dart-define SUPABASE_URL=YOUR_URL --dart-define SUPABASE_ANON_KEY=XXXX',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Example (windows): flutter run -d windows --dart-define SUPABASE_URL=YOUR_URL --dart-define SUPABASE_ANON_KEY=XXXX',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
