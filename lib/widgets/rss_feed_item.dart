import 'package:flutter/material.dart';
import '../models/rss_feed.dart';

class RssFeedItem extends StatelessWidget {
  final RssFeed feed;
  final VoidCallback onRefresh;
  final VoidCallback onDelete;

  const RssFeedItem({
    super.key,
    required this.feed,
    required this.onRefresh,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/rss_entries',
            arguments: feed,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      feed.title,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: onRefresh,
                    tooltip: '刷新',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: onDelete,
                    tooltip: '删除',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                feed.url,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              if (feed.lastFetch != null) ...[
                const SizedBox(height: 4),
                Text(
                  '上次更新: ${feed.lastFetchDateTime.toLocal().toString().split('.')[0]}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
