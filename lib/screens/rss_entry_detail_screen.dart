import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class RssEntryDetailScreen extends StatelessWidget {
  final Map<String, dynamic> entry;

  const RssEntryDetailScreen({
    super.key,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('文章详情'),
        actions: [
          if (entry['link'] != null)
            IconButton(
              icon: const Icon(Icons.open_in_browser),
              onPressed: () => _openInBrowser(context, entry['link']),
              tooltip: '在浏览器中打开',
            ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareEntry(context),
            tooltip: '分享',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry['title'] ?? '无标题',
              style: theme.textTheme.headlineSmall,
            ),
            if (entry['published'] != null) ...[
              const SizedBox(height: 8),
              Text(
                '发布时间: ${DateTime.fromMillisecondsSinceEpoch(entry['published']).toLocal().toString().split('.')[0]}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (entry['author'] != null) ...[
              const SizedBox(height: 4),
              Text(
                '作者: ${entry['author']}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            if (entry['content'] != null)
              SelectableText(
                entry['content'],
                style: theme.textTheme.bodyMedium,
              )
            else if (entry['summary'] != null)
              SelectableText(
                entry['summary'],
                style: theme.textTheme.bodyMedium,
              )
            else
              const Text('暂无内容'),
          ],
        ),
      ),
      floatingActionButton: entry['link'] != null
          ? FloatingActionButton(
              onPressed: () => _openInBrowser(context, entry['link']),
              child: const Icon(Icons.open_in_browser),
            )
          : null,
    );
  }

  Future<void> _openInBrowser(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无效的URL')),
        );
      }
      return;
    }

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('无法打开链接')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('打开链接失败: $e')),
        );
      }
    }
  }

  Future<void> _shareEntry(BuildContext context) async {
    final title = entry['title'] ?? '无标题';
    final url = entry['link'] ?? '';
    final text = '$title\n$url';

    try {
      await Share.share(text, subject: title);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分享失败: $e')),
        );
      }
    }
  }
}
