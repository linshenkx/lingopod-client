import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';

class PlaylistBottomSheet extends StatelessWidget {
  const PlaylistBottomSheet({super.key});

  String _getPlayModeText(PlayMode mode) {
    switch (mode) {
      case PlayMode.sequence:
        return '顺序播放';
      case PlayMode.loop:
        return '列表循环';
      case PlayMode.single:
        return '单曲循环';
      case PlayMode.random:
        return '随机播放';
    }
  }

  IconData _getPlayModeIcon(PlayMode mode) {
    switch (mode) {
      case PlayMode.sequence:
        return Icons.repeat_one_outlined;
      case PlayMode.loop:
        return Icons.repeat;
      case PlayMode.single:
        return Icons.repeat_one;
      case PlayMode.random:
        return Icons.shuffle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // 顶部标题栏
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '播放列表',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        // 播放模式切换按钮
                        TextButton.icon(
                          onPressed: audioProvider.togglePlayMode,
                          icon: Icon(
                            _getPlayModeIcon(audioProvider.playMode),
                            size: 20,
                          ),
                          label: Text(_getPlayModeText(audioProvider.playMode)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${audioProvider.filteredPodcastList.length}个播客',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // 播放列表
              Expanded(
                child: ListView.builder(
                  itemCount: audioProvider.filteredPodcastList.length,
                  itemBuilder: (context, index) {
                    final podcast = audioProvider.filteredPodcastList[index];
                    final isPlaying = podcast == audioProvider.currentPodcast;
                    
                    return ListTile(
                      leading: Icon(
                        isPlaying ? Icons.volume_up : Icons.music_note,
                        color: isPlaying ? colorScheme.primary : null,
                      ),
                      title: Text(
                        podcast.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isPlaying ? colorScheme.primary : null,
                          fontWeight: isPlaying ? FontWeight.bold : null,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 删除按钮
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('确认删除'),
                                  content: const Text('确定要删除这个播客吗？'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('取消'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: Text(
                                        '删除',
                                        style: TextStyle(color: colorScheme.error),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              
                              if (confirm == true) {
                                try {
                                  await audioProvider.deletePodcast(podcast.taskId);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('播客已删除')),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('删除失败: $e')),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        audioProvider.playPodcast(index);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
