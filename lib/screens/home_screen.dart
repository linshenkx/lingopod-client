import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/podcast_list_item.dart';
import '../widgets/url_input_form.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 添加 FocusNode 来管理焦点
  final FocusNode _searchFocusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      
      final audioProvider = context.read<AudioProvider>();
      await audioProvider.refreshPodcastList();

      if (!mounted) return;
      
      if (audioProvider.filteredPodcastList.isNotEmpty) {
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
  void dispose() {
    _searchFocusNode.dispose(); // 记得释放
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector( // 添加 GestureDetector
      onTap: () {
        // 点击空白处时取消焦点
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
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
                focusNode: _searchFocusNode, // 使用 FocusNode
                autofocus: false,
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
      ),
    );
  }
} 