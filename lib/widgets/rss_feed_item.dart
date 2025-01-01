import 'package:flutter/material.dart';
import '../models/rss_feed.dart';

class RssFeedItem extends StatefulWidget {
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
  State<RssFeedItem> createState() => _RssFeedItemState();
}

class _RssFeedItemState extends State<RssFeedItem> {
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      await Future(() => widget.onRefresh());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

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
            arguments: widget.feed,
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
                      widget.feed.title,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    icon: _isRefreshing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.refresh),
                    onPressed: _isRefreshing ? null : _handleRefresh,
                    tooltip: '刷新',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: widget.onDelete,
                    tooltip: '删除',
                  ),
                ],
              ),
              if (widget.feed.url.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  widget.feed.url,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (widget.feed.lastFetch != null) ...[
                const SizedBox(height: 4),
                Text(
                  '最后更新: ${DateTime.fromMillisecondsSinceEpoch(widget.feed.lastFetch!).toLocal().toString().split('.')[0]}',
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
