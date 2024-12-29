import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/task_provider.dart';
import 'home_screen.dart';
import 'task_management_screen.dart';
import 'rss_feeds_screen.dart';
import 'settings_screen.dart';
import '../widgets/mini_player.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<NavigationProvider>(
        builder: (context, navigationProvider, child) {
          return IndexedStack(
            index: navigationProvider.currentIndex,
            children: const [
              HomeScreen(),
              TaskManagementScreen(),
              RssFeedsScreen(),
              SettingsScreen(),
            ],
          );
        },
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini Player
          const MiniPlayer(),
          // 底部导航栏
          Consumer<NavigationProvider>(
            builder: (context, navigationProvider, child) {
              return BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                currentIndex: navigationProvider.currentIndex,
                onTap: (index) {
                  navigationProvider.setCurrentIndex(index);
                },
                items: [
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: '首页',
                  ),
                  BottomNavigationBarItem(
                    icon: Consumer<TaskProvider>(
                      builder: (context, taskProvider, child) {
                        final hasProcessingTasks = taskProvider.tasks.any(
                            (task) =>
                                task.status == 'processing' ||
                                task.status == 'pending');
                        return Stack(
                          children: [
                            Icon(hasProcessingTasks
                                ? Icons.sync
                                : Icons.task_alt),
                            if (hasProcessingTasks)
                              const Positioned(
                                right: 0,
                                top: 0,
                                child: Icon(Icons.fiber_manual_record,
                                    size: 12, color: Colors.blue),
                              ),
                          ],
                        );
                      },
                    ),
                    label: '任务',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.rss_feed),
                    label: 'RSS',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.settings),
                    label: '设置',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
