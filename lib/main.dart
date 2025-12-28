import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kathir_final/core/utils/app_colors.dart';
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
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // Ignore error
  }
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
        ChangeNotifierProvider(
            create: (_) => AppLocator.I.get<AuthViewModel>()),
        ChangeNotifierProvider(create: (_) => OrdersController()),
        ChangeNotifierProvider(create: (_) => FoodieState()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          final router = AppRouter.of(context);

          final lightBase = ThemeData.light(useMaterial3: true);
          final lightTheme = lightBase.copyWith(
            colorScheme: lightBase.colorScheme.copyWith(
              primary: AppColors.primary,
            ),
          );

          final darkBase = ThemeData.dark(useMaterial3: true);
          final darkTheme = darkBase.copyWith(
            scaffoldBackgroundColor: AppColors.backgroundDark,
            cardColor: AppColors.surfaceDark,
            dividerColor: AppColors.dividerDark,
            colorScheme: darkBase.colorScheme.copyWith(
              primary: AppColors.primary,
              surface: AppColors.surfaceDark,
              onSurface: AppColors.white,
              onPrimary: AppColors.white,
            ),
            textTheme: darkBase.textTheme
                .apply(
                  bodyColor: AppColors.white,
                  displayColor: AppColors.white,
                )
                .copyWith(
                  bodyMedium: const TextStyle(color: Colors.white70),
                  bodySmall: const TextStyle(color: Colors.white60),
                  titleSmall: const TextStyle(color: Colors.white70),
                ),
            iconTheme: const IconThemeData(color: Colors.white70),
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.backgroundDark,
              foregroundColor: AppColors.white,
              elevation: 0,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
            inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              fillColor: AppColors.surfaceDark,
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
                'Please create a .env file in the project root with SUPABASE_URL and SUPABASE_ANON_KEY',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'SUPABASE_URL=...\nSUPABASE_ANON_KEY=...',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
