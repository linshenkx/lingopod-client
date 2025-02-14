import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/podcast.dart';
import '../providers/audio_provider.dart';

class PodcastListItem extends StatelessWidget {
  final Podcast podcast;
  final int index;

  const PodcastListItem({
    super.key,
    required this.podcast,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: context.read<AudioProvider>().isPlayingNotifier,
      builder: (context, isPlaying, _) {
        final audioProvider = context.watch<AudioProvider>();
        final isCurrentPlaying = audioProvider.currentIndex == index && isPlaying;

        return Card(
          elevation: 1,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              podcast.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isCurrentPlaying ? 
                  Theme.of(context).colorScheme.primary : null,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  _formatDateTime(podcast.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    isCurrentPlaying ? Icons.pause : Icons.play_arrow,
                    color: isCurrentPlaying ? 
                      Theme.of(context).colorScheme.primary : null,
                  ),
                  onPressed: () {
                    if (audioProvider.currentIndex == index) {
                      audioProvider.togglePlayPause();
                    } else {
                      audioProvider.playPodcast(index);
                    }
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) async {
                    switch (value) {
                      case 'copy':
                        await _copyUrl(context);
                        break;
                      case 'delete':
                        await _showDeleteConfirmation(context);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'copy',
                      child: Row(
                        children: [
                          Icon(Icons.content_copy, size: 20),
                          SizedBox(width: 8),
                          Text('复制链接'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '删除',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () => audioProvider.playPodcast(index),
          ),
        );
      },
    );
  }

  String _formatDateTime(int timestamp) {
    final localDateTime = DateTime.fromMillisecondsSinceEpoch(timestamp).toLocal();
    final now = DateTime.now();
    
    bool isSameDay = localDateTime.year == now.year &&
        localDateTime.month == now.month &&
        localDateTime.day == now.day;
        
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    bool isYesterday = localDateTime.year == yesterday.year &&
        localDateTime.month == yesterday.month &&
        localDateTime.day == yesterday.day;

    if (isSameDay) {
      return '今天 ${localDateTime.hour.toString().padLeft(2, '0')}:'
             '${localDateTime.minute.toString().padLeft(2, '0')}';
    } else if (isYesterday) {
      return '昨天 ${localDateTime.hour.toString().padLeft(2, '0')}:'
             '${localDateTime.minute.toString().padLeft(2, '0')}';
    } else if (now.difference(localDateTime).inDays < 7) {
      return '${now.difference(localDateTime).inDays}天前';
    } else {
      return '${localDateTime.year}-'
             '${localDateTime.month.toString().padLeft(2, '0')}-'
             '${localDateTime.day.toString().padLeft(2, '0')} '
             '${localDateTime.hour.toString().padLeft(2, '0')}:'
             '${localDateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _copyUrl(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: podcast.url));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('链接已复制到剪贴板')),
      );
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
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
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await context.read<AudioProvider>().deletePodcast(podcast.taskId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('删除成功')),
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
  }
} 