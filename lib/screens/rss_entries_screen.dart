import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/rss_feed.dart';
import '../providers/rss_provider.dart';

class RssEntriesScreen extends StatefulWidget {
  final RssFeed feed;

  const RssEntriesScreen({
    super.key,
    required this.feed,
  });

  @override
  State<RssEntriesScreen> createState() => _RssEntriesScreenState();
}

class _RssEntriesScreenState extends State<RssEntriesScreen> {
  List<Map<String, dynamic>>? _entries;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final entries =
          await context.read<RssProvider>().getRssFeedEntries(widget.feed.id);
      if (mounted) {
        setState(() {
          _entries = entries;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.feed.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEntries,
            tooltip: '刷新',
          ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('错误: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEntries,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_entries == null || _entries!.isEmpty) {
      return const Center(
        child: Text('暂无内容'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEntries,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _entries!.length,
        itemBuilder: (context, index) {
          final entry = _entries![index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/rss_entry_detail',
                  arguments: entry,
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry['title'] ?? '无标题',
                      style: theme.textTheme.titleMedium,
                    ),
                    if (entry['published'] != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '发布时间: ${DateTime.fromMillisecondsSinceEpoch(entry['published']).toLocal().toString().split('.')[0]}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    if (entry['summary'] != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        entry['summary'],
                        style: theme.textTheme.bodyMedium,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
