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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final audioProvider = context.read<AudioProvider>();
      await audioProvider.refreshPodcastList();

    if (context.mounted && audioProvider.filteredPodcastList.isNotEmpty) {
        if (audioProvider.currentPodcast == null) {
          audioProvider.setCurrentPodcast(
            audioProvider.filteredPodcastList[0],
            autoPlay: false
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {    
    return Scaffold(
      appBar: AppBar(
        title: const Text('LingoPod 译播客'),
        actions: [
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
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: UrlInputForm(),
          ),
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
          Expanded(
            child: Consumer<AudioProvider>(
              builder: (context, audioProvider, child) {
                if (audioProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (audioProvider.filteredPodcastList.isEmpty) {
                  return const Center(child: Text('暂无播客'));
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
    );
  }
} 