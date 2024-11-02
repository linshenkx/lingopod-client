import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/podcast_list_item.dart';
import '../widgets/url_input_form.dart';
import '../widgets/mini_player.dart';
import '../screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // 初始加载
    context.read<AudioProvider>().refreshPodcastList();
    // 启动自动刷新
    context.read<AudioProvider>().startAutoRefresh();
  }

  @override
  void dispose() {
    // 停止自动刷新
    context.read<AudioProvider>().stopAutoRefresh();
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
                if (audioProvider.filteredPodcastList.isEmpty) {
                  return const Center(
                    child: Text('暂无播客'),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: () => audioProvider.refreshPodcastList(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80), // 为迷你播放器留出空间
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