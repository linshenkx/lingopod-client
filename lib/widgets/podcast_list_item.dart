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
    final audioProvider = context.watch<AudioProvider>();
    final isCurrentPlaying = audioProvider.currentIndex == index && 
                           audioProvider.isPlaying;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onLongPress: () => _showOptionsDialog(context),
        onTap: () {
          if (podcast.status == 'completed') {
            context.read<AudioProvider>().playPodcast(index);
          }
        },
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  podcast.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isCurrentPlaying ? 
                      Theme.of(context).colorScheme.primary : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildStatusChip(context),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                _formatDateTime(podcast.createdAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (podcast.status == 'processing') ...[
                const SizedBox(height: 8),
                _buildProgressIndicator(context),
              ],
              if (isCurrentPlaying) ...[
                const SizedBox(height: 4),
                Text(
                  '正在播放',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (podcast.status == 'completed') ...[
                IconButton(
                  icon: Icon(
                    isCurrentPlaying ? Icons.pause : Icons.play_arrow,
                    color: isCurrentPlaying ? 
                      Theme.of(context).colorScheme.primary : null,
                  ),
                  onPressed: () {
                    if (isCurrentPlaying) {
                      context.read<AudioProvider>().togglePlayPause();
                    } else {
                      context.read<AudioProvider>().playPodcast(index);
                    }
                  },
                ),
              ],
              if (podcast.status == 'failed') ...[
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => _retryTask(context),
                ),
              ],
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
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    final color = _getStatusColor(podcast.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getStatusText(podcast.status),
        style: TextStyle(
          color: color,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (podcast.currentStep != null) ...[
          Text(
            '当前步骤: ${podcast.currentStep}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
        ],
        if (podcast.stepProgress != null)
          LinearProgressIndicator(
            value: podcast.stepProgress! / 100,
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'processing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'processing':
        return '处理中';
      case 'completed':
        return '已完成';
      case 'failed':
        return '失败';
      default:
        return '等待中';
    }
  }

  Future<void> _retryTask(BuildContext context) async {
    try {
      await context.read<AudioProvider>().retryTask(podcast.taskId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已重新开始处理')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('重试失败: $e')),
        );
      }
    }
  }

  // 显示选项对话框（长按时显示）
  Future<void> _showOptionsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('播客选项'),
        children: [
          ListTile(
            leading: const Icon(Icons.link),
            title: Text(
              podcast.url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.content_copy),
              onPressed: () {
                _copyUrl(context);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  // 复制链接
  Future<void> _copyUrl(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: podcast.url));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('链接已复制到剪贴板')),
      );
    }
  }

  String _formatDateTime(int timestamp) {
    // 转换时间戳为DateTime对象
    final localDateTime = DateTime.fromMillisecondsSinceEpoch(timestamp).toLocal();
    final now = DateTime.now();
    final difference = now.difference(localDateTime);

    if (difference.inDays == 0) {
      // 今天
      return '今天 ${localDateTime.hour.toString().padLeft(2, '0')}:'
             '${localDateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      // 昨天
      return '昨天 ${localDateTime.hour.toString().padLeft(2, '0')}:'
             '${localDateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      // 一周内
      return '${difference.inDays}天前';
    } else {
      // 超过一周
      return '${localDateTime.year}-'
             '${localDateTime.month.toString().padLeft(2, '0')}-'
             '${localDateTime.day.toString().padLeft(2, '0')} '
             '${localDateTime.hour.toString().padLeft(2, '0')}:'
             '${localDateTime.minute.toString().padLeft(2, '0')}';
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