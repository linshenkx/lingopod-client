import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/audio_service.dart';
import 'services/api_service.dart';
import 'providers/theme_provider.dart';
import 'providers/audio_provider.dart';
import 'providers/task_provider.dart';
import 'screens/home_screen.dart';
import 'screens/player_screen.dart';
import 'providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('Starting app...');

  final settingsProvider = SettingsProvider();
  await settingsProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (context) => AudioProvider(
            AudioService(),
            ApiService(context.read<SettingsProvider>()),
            context.read<SettingsProvider>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => TaskProvider(context.read<SettingsProvider>()),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'LingoPod 译播客',
            theme: ThemeData(
              useMaterial3: true,
              platform: TargetPlatform.iOS,
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              platform: TargetPlatform.iOS,
              brightness: Brightness.dark,
            ),
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
            home: const HomeScreen(),
            routes: {
              '/player': (context) => PlayerScreen(
                onClose: () => Navigator.of(context).pop(),
              ),
            },
          );
        },
      ),
    ),
  );
}
