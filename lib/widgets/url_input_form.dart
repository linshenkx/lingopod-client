import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/audio_provider.dart';

class UrlInputForm extends StatefulWidget {
  const UrlInputForm({super.key});

  @override
  State<UrlInputForm> createState() => _UrlInputFormState();
}

class _UrlInputFormState extends State<UrlInputForm> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 设置任务完成回调
    Future.microtask(() {
      context.read<TaskProvider>().setOnTaskCompleted(() async {
        // 刷新播客列表
        await context.read<AudioProvider>().refreshPodcastList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _urlController,
            decoration: InputDecoration(
              hintText: '输入播客URL...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入URL';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          Consumer<TaskProvider>(
            builder: (context, taskProvider, child) {
              // 显示任务状态
              if (taskProvider.taskStatus != null) {
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getStatusColor(taskProvider.taskStatus!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          _getStatusIcon(taskProvider.taskStatus!),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              taskProvider.taskProgress ?? '',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              }
              return const SizedBox(height: 8);
            },
          ),
          SizedBox(
            width: double.infinity,
            child: Consumer<TaskProvider>(
              builder: (context, taskProvider, child) {
                return ElevatedButton(
                  onPressed: taskProvider.isProcessing
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            final url = _urlController.text;
                            _urlController.clear();
                            await taskProvider.submitTask(url);
                          }
                        },
                  child: Text(taskProvider.isProcessing ? '处理中...' : '提交任务'),
                );
              },
            ),
          ),
        ],
      ),
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

  Widget _getStatusIcon(String status) {
    switch (status) {
      case 'processing':
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
      case 'completed':
        return const Icon(Icons.check_circle, color: Colors.white);
      case 'failed':
        return const Icon(Icons.error, color: Colors.white);
      default:
        return const Icon(Icons.info, color: Colors.white);
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
} 