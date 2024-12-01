// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingopod_client/main.dart';
import 'package:lingopod_client/providers/audio_provider.dart';
import 'package:lingopod_client/providers/auth_provider.dart';
import 'package:lingopod_client/providers/navigation_provider.dart';
import 'package:lingopod_client/providers/settings_provider.dart';
import 'package:lingopod_client/providers/task_provider.dart';
import 'package:lingopod_client/providers/theme_provider.dart';
import 'package:lingopod_client/screens/login_screen.dart';
import 'package:lingopod_client/services/api_service.dart';
import 'package:lingopod_client/services/audio_service.dart';
import 'package:provider/provider.dart';


void main() {
  group('App Widget Tests', () {
    late SettingsProvider settingsProvider;

    setUp(() async {
      settingsProvider = SettingsProvider();
      await settingsProvider.init();
    });

    testWidgets('App starts with login screen when not authenticated', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settingsProvider),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => AuthProvider(ApiService(settingsProvider))),
            ChangeNotifierProvider(create: (_) => NavigationProvider()),
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
          child: const MyApp(),
        ),
      );

      // 验证是否显示登录界面
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('LingoPod 译播客'), findsOneWidget);
      
      // 验证登录界面的基本元素
      expect(find.byIcon(Icons.person), findsOneWidget); // 用户名图标
      expect(find.byIcon(Icons.lock), findsOneWidget);  // 密码图标
      expect(find.text('登录'), findsOneWidget);
      expect(find.text('还没有账号？立即注册'), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('Theme toggle works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settingsProvider),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => AuthProvider(ApiService(settingsProvider))),
          ],
          child: const MyApp(),
        ),
      );

      // 找到主题切换按钮
      final themeButton = find.byIcon(Icons.light_mode).first;
      
      // 点击切换主题
      await tester.tap(themeButton);
      await tester.pumpAndSettle();

      // 验证主题是否切换（通过检查图标变化）
      expect(find.byIcon(Icons.dark_mode), findsOneWidget);
    });
  });
}
