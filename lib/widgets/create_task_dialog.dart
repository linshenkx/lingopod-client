import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/style_params.dart';
import '../providers/task_provider.dart';
import '../providers/audio_provider.dart';

class CreateTaskDialog extends StatefulWidget {
  const CreateTaskDialog({super.key});

  @override
  State<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<CreateTaskDialog> {
  final TextEditingController _urlController = TextEditingController();
  bool _isPublic = false;
  var styleParams = StyleParams();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('创建新任务'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                hintText: '输入播客URL',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('公开任务'),
                Switch(
                  value: _isPublic,
                  onChanged: (value) {
                    setState(() {
                      _isPublic = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('对话长度:'),
            DropdownButton<String>(
              value: styleParams.contentLength,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'short', child: Text('简短(5-8轮)')),
                DropdownMenuItem(value: 'medium', child: Text('中等(8-12轮)')),
                DropdownMenuItem(value: 'long', child: Text('较长(12-15轮)')),
              ],
              onChanged: (value) {
                setState(() {
                  styleParams = styleParams.copyWith(contentLength: value);
                });
              },
            ),
            const SizedBox(height: 8),
            const Text('对话语气:'),
            DropdownButton<String>(
              value: styleParams.tone,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'casual', child: Text('轻松')),
                DropdownMenuItem(value: 'formal', child: Text('正式')),
                DropdownMenuItem(value: 'humorous', child: Text('幽默')),
              ],
              onChanged: (value) {
                setState(() {
                  styleParams = styleParams.copyWith(tone: value);
                });
              },
            ),
            const SizedBox(height: 8),
            const Text('情感色彩:'),
            DropdownButton<String>(
              value: styleParams.emotion,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'neutral', child: Text('中性')),
                DropdownMenuItem(value: 'enthusiastic', child: Text('热情')),
                DropdownMenuItem(value: 'professional', child: Text('专业')),
              ],
              onChanged: (value) {
                setState(() {
                  styleParams = styleParams.copyWith(emotion: value);
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () async {
            final url = _urlController.text.trim();
            if (url.isNotEmpty) {
              await context.read<TaskProvider>().submitTask(
                    url,
                    isPublic: _isPublic,
                    styleParams: styleParams,
                  );
              if (context.mounted) {
                Navigator.pop(context);
                // 创建任务后刷新播放列表
                context.read<AudioProvider>().refreshPodcastList();
              }
            }
          },
          child: const Text('创建'),
        ),
      ],
    );
  }
}
