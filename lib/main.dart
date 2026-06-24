import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_messenger.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'core/constants/app_constants.dart';
import 'core/ui/app_skeleton.dart';
import 'providers/backend_connection_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/cattle_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/cattle_analysis_provider.dart';
import 'providers/camera_provider.dart';
import 'services/settings_service.dart';
import 'services/analysis_cache_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    debugPrint(
      '⚠️ SUPABASE_URL or SUPABASE_ANON_KEY is missing from .env — '
      'auth will not work.',
    );
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  await AnalysisCacheService().init();
  await SettingsService.instance.initialize();

  runApp(const CattleAIApp());
}

class CattleAIApp extends StatelessWidget {
  const CattleAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BackendConnectionProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => CattleProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => CattleAnalysisProvider()),
        ChangeNotifierProvider(create: (_) => CameraProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
            locale: settings.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            scaffoldMessengerKey: AppMessenger.key,
            home: const _AuthWrapper(),
          );
        },
      ),
    );
  }
}

class _AuthWrapper extends StatelessWidget {
  const _AuthWrapper();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const AppBootstrapSkeleton();
        }

        if (auth.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<CattleProvider>().initialize();
          });
          return const HomeScreen();
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<CattleProvider>().clearData();
        });

        return const LoginScreen();
      },
    );
  }
}
