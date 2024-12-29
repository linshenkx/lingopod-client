import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/rss_provider.dart';
import '../models/rss_feed.dart';
import '../widgets/rss_feed_item.dart';
import '../widgets/add_rss_feed_dialog.dart';

class RssFeedsScreen extends StatefulWidget {
  const RssFeedsScreen({super.key});

  @override
  State<RssFeedsScreen> createState() => _RssFeedsScreenState();
}

class _RssFeedsScreenState extends State<RssFeedsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  _SortBy _sortBy = _SortBy.title;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<RssProvider>().loadFeeds());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<RssFeed> _getFilteredAndSortedFeeds(List<RssFeed> feeds) {
    // 过滤
    var filteredFeeds = feeds.where((feed) {
      final query = _searchQuery.toLowerCase();
      return feed.title.toLowerCase().contains(query) ||
          feed.url.toLowerCase().contains(query);
    }).toList();

    // 排序
    filteredFeeds.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case _SortBy.title:
          comparison = a.title.compareTo(b.title);
          break;
        case _SortBy.url:
          comparison = a.url.compareTo(b.url);
          break;
        case _SortBy.lastUpdate:
          final aDate = a.lastFetch ?? 0;
          final bDate = b.lastFetch ?? 0;
          comparison = aDate.compareTo(bDate);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filteredFeeds;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RSS订阅管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortDialog,
            tooltip: '排序',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddFeedDialog(context),
            tooltip: '添加',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索订阅源...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: Consumer<RssProvider>(
              builder: (context, rssProvider, child) {
                if (rssProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (rssProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('错误: ${rssProvider.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            rssProvider.clearError();
                            rssProvider.loadFeeds();
                          },
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  );
                }

                final filteredFeeds =
                    _getFilteredAndSortedFeeds(rssProvider.feeds);

                if (rssProvider.feeds.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('暂无RSS订阅'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _showAddFeedDialog(context),
                          child: const Text('添加订阅'),
                        ),
                      ],
                    ),
                  );
                }

                if (filteredFeeds.isEmpty) {
                  return const Center(
                    child: Text('没有找到匹配的订阅源'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => rssProvider.loadFeeds(),
                  child: ListView.builder(
                    itemCount: filteredFeeds.length,
                    itemBuilder: (context, index) {
                      final feed = filteredFeeds[index];
                      return RssFeedItem(
                        feed: feed,
                        onRefresh: () => rssProvider.refreshFeed(feed.id),
                        onDelete: () => _showDeleteConfirmDialog(context, feed),
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

  Future<void> _showSortDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('排序方式'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<_SortBy>(
                  title: const Text('按标题'),
                  value: _SortBy.title,
                  groupValue: _sortBy,
                  onChanged: (value) {
                    setState(() => _sortBy = value!);
                    this.setState(() {});
                  },
                ),
                RadioListTile<_SortBy>(
                  title: const Text('按URL'),
                  value: _SortBy.url,
                  groupValue: _sortBy,
                  onChanged: (value) {
                    setState(() => _sortBy = value!);
                    this.setState(() {});
                  },
                ),
                RadioListTile<_SortBy>(
                  title: const Text('按最后更新时间'),
                  value: _SortBy.lastUpdate,
                  groupValue: _sortBy,
                  onChanged: (value) {
                    setState(() => _sortBy = value!);
                    this.setState(() {});
                  },
                ),
                SwitchListTile(
                  title: Text(_sortAscending ? '升序' : '降序'),
                  value: _sortAscending,
                  onChanged: (value) {
                    setState(() => _sortAscending = value);
                    this.setState(() {});
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('关闭'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAddFeedDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddRssFeedDialog(),
    );

    if (result == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('RSS订阅添加成功')),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmDialog(
      BuildContext context, RssFeed feed) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除订阅 "${feed.title}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await context.read<RssProvider>().deleteFeed(feed.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('RSS订阅删除成功')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败: $e')),
          );
        }
      }
    }
  }
}

enum _SortBy {
  title,
  url,
  lastUpdate,
}
