import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/audio_service.dart';
import 'services/api_service.dart';
import 'providers/theme_provider.dart';
import 'providers/audio_provider.dart';
import 'providers/task_provider.dart';
import 'screens/player_screen.dart';
import 'providers/settings_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/settings_screen.dart';
import 'providers/navigation_provider.dart';
import 'screens/main_screen.dart';
import 'config/style_config.dart';

// 添加全局 navigatorKey
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('Starting app...');

  final settingsProvider = SettingsProvider();
  await settingsProvider.init();

  final apiService = ApiService(settingsProvider);
  final authProvider = AuthProvider(apiService);
  await authProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (context) => AudioProvider(
            AudioService(),
            apiService,
            context.read<SettingsProvider>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => TaskProvider(context.read<SettingsProvider>()),
        ),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, AuthProvider>(
      builder: (context, themeProvider, authProvider, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'LingoPod 译播客',
          theme: StyleConfig.getLightTheme(),
          darkTheme: StyleConfig.getDarkTheme(),
          themeMode: themeProvider.themeMode,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('zh', 'CN'),
            Locale('en', 'US'),
          ],
          builder: (context, child) {
            // 添加全局响应式布局支持
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaleFactor: 1.0,
              ),
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  physics: const BouncingScrollPhysics(),
                  scrollbars: true,
                ),
                child: child!,
              ),
            );
          },
          home: authProvider.isAuthenticated
              ? const MainScreen()
              : const LoginScreen(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/home': (context) => const MainScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/player': (context) => PlayerScreen(
                  onClose: () => Navigator.of(context).pop(),
                ),
          },
        );
      },
    );
  }
}
