import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kathir_final/core/utils/app_colors.dart';
import 'package:kathir_final/core/utils/page_transitions.dart';
import 'app/bootstrap/di_bootstrap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'features/_shared/providers/theme_provider.dart';
import 'features/_shared/providers/locale_provider.dart';
import 'features/authentication/presentation/blocs/auth_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
            create: (_) => AppLocator.I.get<AuthViewModel>()),
        ChangeNotifierProvider(create: (_) => OrdersController()),
        ChangeNotifierProvider(create: (_) => FoodieState()),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, theme, localeProvider, _) {
          final router = AppRouter.of(context);

          final lightBase = ThemeData.light(useMaterial3: true);
          final lightTheme = lightBase.copyWith(
            scaffoldBackgroundColor: const Color(0xFFF0F0F0),
            cardColor: Colors.white,
            dividerColor: Colors.black12,
            colorScheme: lightBase.colorScheme.copyWith(
<<<<<<< HEAD
              primary: const Color(0xFF4DD0E1),
              secondary: const Color(0xFF005F7B),
              surface: Colors.white,
              onSurface: const Color(0xFF08314A),
              onPrimary: Colors.white,
            ),
            textTheme: lightBase.textTheme.apply(
              bodyColor: const Color(0xFF08314A),
              displayColor: const Color(0xFF08314A),
            ).copyWith(
              bodyMedium: const TextStyle(color: Color(0xFF08314A)),
              bodySmall: TextStyle(color: const Color(0xFF08314A).withOpacity(0.7)),
              titleSmall: TextStyle(color: const Color(0xFF08314A).withOpacity(0.8)),
            ),
            iconTheme: const IconThemeData(color: Color(0xFF08314A)),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFF0F0F0),
              foregroundColor: Color(0xFF08314A),
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
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              border: InputBorder.none,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF4DD0E1)),
              ),
              labelStyle: TextStyle(color: const Color(0xFF08314A).withOpacity(0.7)),
              hintStyle: TextStyle(color: const Color(0xFF08314A).withOpacity(0.5)),
=======
              primary: AppColors.primary,
>>>>>>> 56f87e16bb79ac3fb1fe1ae2f0ea37bbc4ec224f
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
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: SlidePushPageTransitionsBuilder(),
                TargetPlatform.iOS: SlidePushPageTransitionsBuilder(),
                TargetPlatform.windows: SlidePushPageTransitionsBuilder(),
                TargetPlatform.macOS: SlidePushPageTransitionsBuilder(),
                TargetPlatform.linux: SlidePushPageTransitionsBuilder(),
              },
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
            dialogTheme: const DialogTheme(
              backgroundColor: Color(0xFF1E1E1E),
              titleTextStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              contentTextStyle: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            snackBarTheme: const SnackBarThemeData(
              backgroundColor: Color(0xFF2C2C2C),
              contentTextStyle: TextStyle(color: Colors.white),
            ),
          );

          return MaterialApp.router(
            title: 'Flutter Demo',
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: theme.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            debugShowCheckedModeBanner: false,
            routerConfig: router,
            locale: localeProvider.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
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
