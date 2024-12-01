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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().setOnTaskCompleted(() async {
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
              hintText: '请输入要转换为播客的链接',
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
              if (taskProvider.taskStatus != null) {
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getStatusColor(taskProvider.taskStatus!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
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
                          if (taskProvider.currentStep != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              '当前步骤: ${taskProvider.currentStep}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            if (taskProvider.stepProgress != null)
                              LinearProgressIndicator(
                                value: taskProvider.stepProgress! / 100,
                                backgroundColor: Colors.white24,
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                          ],
                        ],
                      ),
                    ),
                    if (taskProvider.taskStatus == 'failed') ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => taskProvider.retryTask(),
                              icon: const Icon(Icons.refresh),
                              label: const Text('重试'),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (taskProvider.taskStatus != 'completed') ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => taskProvider.deleteTask(),
                              icon: const Icon(Icons.delete),
                              label: const Text('删除'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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