// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lingopod_app/providers/settings_provider.dart';
import 'package:flutter_lingopod_app/providers/theme_provider.dart';
import 'package:flutter_lingopod_app/providers/audio_provider.dart';
import 'package:flutter_lingopod_app/providers/task_provider.dart';
import 'package:flutter_lingopod_app/services/audio_service.dart';
import 'package:flutter_lingopod_app/services/api_service.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // 创建必要的 providers
    final settingsProvider = SettingsProvider();
    await settingsProvider.init();

    // 构建测试用的 widget tree
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settingsProvider),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(
            create: (context) => AudioProvider(
              AudioPlayerService(),
              ApiService(context.read<SettingsProvider>()),
              context.read<SettingsProvider>(),
            ),
          ),
          ChangeNotifierProvider(
            create: (context) => TaskProvider(context.read<SettingsProvider>()),
          ),
        ],
        child: MaterialApp(
          home: Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return MaterialApp(
                title: 'LingoPod 译播客',
                theme: ThemeData(
                  useMaterial3: true,
                  fontFamily: '.SF Pro Text',
                  platform: TargetPlatform.iOS,
                ),
                darkTheme: ThemeData(
                  useMaterial3: true,
                  fontFamily: '.SF Pro Text',
                  platform: TargetPlatform.iOS,
                  brightness: Brightness.dark,
                ),
                themeMode: themeProvider.themeMode,
                home: const Scaffold(
                  body: Center(
                    child: Text('LingoPod 译播客'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    // 验证应用标题是否正确显示
    expect(find.text('LingoPod 译播客'), findsOneWidget);
    
    // 等待所有动画完成
    await tester.pumpAndSettle();
  });
}
