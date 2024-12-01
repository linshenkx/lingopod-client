import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/podcast_list_item.dart';
import '../widgets/url_input_form.dart';
import '../widgets/mini_player.dart';
import '../screens/settings_screen.dart';
import '../screens/task_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AudioProvider>().refreshPodcastList();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {    
    return Scaffold(
      appBar: AppBar(
        title: const Text('LingoPod 译播客'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              context.read<ThemeProvider>().toggleTheme();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新列表',
            onPressed: () {
              context.read<AudioProvider>().refreshPodcastList();
            },
          ),
          Consumer<TaskProvider>(
            builder: (context, taskProvider, child) {
              final hasProcessingTasks = taskProvider.tasks.any(
                (task) => task.status == 'processing' || task.status == 'pending'
              );
              
              final hasFailedTasks = taskProvider.tasks.any(
                (task) => task.status == 'failed'
              );

              return Stack(
                children: [
                  IconButton(
                    icon: hasProcessingTasks
                      ? const Icon(Icons.sync, color: Colors.blue)
                      : const Icon(Icons.task_alt),
                    tooltip: '任务管理',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TaskManagementScreen(),
                        ),
                      );
                    },
                  ),
                  if (hasProcessingTasks)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: RotationTransition(
                        turns: AlwaysStoppedAnimation(
                          DateTime.now().millisecondsSinceEpoch / 1000
                        ),
                        child: const Icon(
                          Icons.sync,
                          size: 12,
                          color: Colors.blue,
                        ),
                      ),
                    )
                  else if (hasFailedTasks)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.error,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // URL输入表单
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: UrlInputForm(),
          ),
          // 搜索框
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextFormField(
              decoration: InputDecoration(
                hintText: '搜索播客...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                context.read<AudioProvider>().searchPodcasts(value);
              },
            ),
          ),
          const SizedBox(height: 16),
          // 播客列表
          Expanded(
            child: Consumer<AudioProvider>(
              builder: (context, audioProvider, child) {
                if (audioProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                
                if (audioProvider.filteredPodcastList.isEmpty) {
                  return const Center(
                    child: Text('暂无播客'),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: () async {
                    await audioProvider.refreshPodcastList();
                    return Future.value();
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: audioProvider.filteredPodcastList.length,
                    itemBuilder: (context, index) {
                      return PodcastListItem(
                        podcast: audioProvider.filteredPodcastList[index],
                        index: index,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Consumer<AudioProvider>(
        builder: (context, audioProvider, child) {
          return audioProvider.currentPodcast != null
              ? const MiniPlayer()
              : const SizedBox.shrink();
        },
      ),
    );
  }
} 