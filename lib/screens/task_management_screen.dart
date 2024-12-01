import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import 'package:flutter/services.dart';  // 用于 Clipboard
import 'dart:async';

class TaskManagementScreen extends StatefulWidget {
  const TaskManagementScreen({super.key});

  @override
  _TaskManagementScreenState createState() => _TaskManagementScreenState();
}

class _TaskManagementScreenState extends State<TaskManagementScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _titleFilterController = TextEditingController();
  final TextEditingController _urlFilterController = TextEditingController();
  bool _isPublic = false;
  String _statusFilter = 'all';
  String _visibilityFilter = 'all';
  DateTime? _startDate;
  DateTime? _endDate;
  Timer? _refreshTimer;

  // 复制到剪贴板的工具方法
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('复制成功!')),
      );
    });
  }

  // 构建筛选器区域
  Widget _buildFilters() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 第一行筛选条件
            Row(
              children: [
                // 状态筛选
                DropdownButton<String>(
                  value: _statusFilter,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('全部状态')),
                    DropdownMenuItem(value: 'pending', child: Text('等待中')),
                    DropdownMenuItem(value: 'processing', child: Text('处理中')),
                    DropdownMenuItem(value: 'completed', child: Text('已完成')),
                    DropdownMenuItem(value: 'failed', child: Text('失败')),
                  ],
                  onChanged: (value) => setState(() => _statusFilter = value!),
                ),
                const SizedBox(width: 16),
                
                // 可见性筛选
                DropdownButton<String>(
                  value: _visibilityFilter,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('全部')),
                    DropdownMenuItem(value: 'public', child: Text('仅看公开')),
                    DropdownMenuItem(value: 'private', child: Text('仅看私有')),
                  ],
                  onChanged: (value) => setState(() => _visibilityFilter = value!),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 第二行筛选条件
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleFilterController,
                    decoration: const InputDecoration(
                      labelText: '标题',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _urlFilterController,
                    decoration: const InputDecoration(
                      labelText: 'URL',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 操作按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _resetFilters,
                  icon: const Icon(Icons.clear),
                  label: const Text('重置'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => context.read<TaskProvider>().fetchTasks(
                    status: _statusFilter == 'all' ? null : _statusFilter,
                    isPublic: _visibilityFilter == 'public' ? true : 
                             _visibilityFilter == 'private' ? false : null,
                    titleKeyword: _titleFilterController.text,
                    urlKeyword: _urlFilterController.text,
                    startDate: _startDate?.millisecondsSinceEpoch,
                    endDate: _endDate?.millisecondsSinceEpoch,
                  ),
                  icon: const Icon(Icons.search),
                  label: const Text('查询'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 重置筛选条件
  void _resetFilters() {
    setState(() {
      _statusFilter = 'all';
      _visibilityFilter = 'all';
      _titleFilterController.clear();
      _urlFilterController.clear();
      _startDate = null;
      _endDate = null;
    });
  }

  // 编辑任务对话框
  void _showEditTaskDialog(Task task) {
    final TextEditingController titleController = TextEditingController(text: task.title);
    bool isPublic = task.isPublic;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑任务'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: '标题'),
            ),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setState) => SwitchListTile(
                title: const Text('公开任务'),
                value: isPublic,
                onChanged: (value) => setState(() => isPublic = value),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<TaskProvider>().updateTask(
                task.id,
                title: titleController.text,
                isPublic: isPublic,
              );
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // 页面初始化时获取任务列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().fetchTasks();
      _startAutoRefresh();
    });
  }

  // 开始自动刷新
  void _startAutoRefresh() {
    // 每3秒更新一次状态
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _updateInProgressTasks();
    });
  }

  // 更新进行中的任务状态
  void _updateInProgressTasks() async {
    final taskProvider = context.read<TaskProvider>();
    final tasks = taskProvider.tasks;
    
    for (final task in tasks) {
      // 只更新处理中和等待中的任务状态
      if (task.status == 'processing' || task.status == 'pending') {
        try {
          final updatedTask = await taskProvider.getTaskDetail(task.id);
          
          // 如果任务状态有变化，更新UI
          if (updatedTask.status != task.status ||
              updatedTask.currentStep != task.currentStep ||
              updatedTask.currentStepIndex != task.currentStepIndex ||
              updatedTask.progressMessage != task.progressMessage) {
            
            // 找到任务在列表中的位置
            final index = tasks.indexWhere((t) => t.id == task.id);
            if (index != -1) {
              setState(() {
                tasks[index] = updatedTask;
              });
            }
          }
          
          // 如果任务完成或失败，刷新整个列表
          if (updatedTask.status == 'completed' || updatedTask.status == 'failed') {
            taskProvider.fetchTasks();
            break;
          }
        } catch (e) {
          debugPrint('Failed to update task ${task.id}: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('任务管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateTaskDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: Consumer<TaskProvider>(
              builder: (context, taskProvider, child) {
                if (taskProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (taskProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(taskProvider.error!),
                        ElevatedButton(
                          onPressed: () => taskProvider.fetchTasks(),
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  );
                }

                if (taskProvider.tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('暂无任务'),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _showCreateTaskDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('创建任务'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => taskProvider.fetchTasks(),
                  child: ListView.builder(
                    itemCount: taskProvider.tasks.length,
                    itemBuilder: (context, index) {
                      final task = taskProvider.tasks[index];
                      return _buildTaskItem(context, task);
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

  Widget _buildTaskItem(BuildContext context, Task task) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListTile(
            title: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () => _copyToClipboard(task.url),
                  tooltip: '复制URL',
                ),
                Expanded(
                  child: Text(
                    task.title ?? task.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            subtitle: task.status != 'completed' ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // 显示当前步骤和进度
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _truncateText(task.currentStep ?? '准备中', 12),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    if (task.currentStepIndex != null && task.totalSteps != null)
                      Text(
                        '${_calculateProgress(task)}%',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                // 进度条
                LinearProgressIndicator(
                  value: _calculateProgress(task) / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getProgressColor(task.status),
                  ),
                ),
                // 进度消息
                if (task.progressMessage != null) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _copyToClipboard(task.progressMessage!),
                    child: Tooltip(
                      message: task.progressMessage!,
                      child: Text(
                        _truncateText(task.progressMessage!, 12),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ) : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditTaskDialog(task),
                ),
                if (task.status == 'failed')
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => context.read<TaskProvider>().retryTask(task.id),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _showDeleteConfirmDialog(task),
                  tooltip: '删除任务',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateTaskDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('创建新任务'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final url = _urlController.text.trim();
                if (url.isNotEmpty) {
                  context.read<TaskProvider>().submitTask(
                    url, 
                    isPublic: _isPublic
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('创建'),
            ),
          ],
        );
      },
    );
  }

  void _retryTask(Task task) {
    context.read<TaskProvider>().retryTask(task.id);
  }

  void _showDeleteConfirmDialog(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个任务吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              context.read<TaskProvider>().deleteTask(task.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'processing':
        return '处理中';
      case 'completed':
        return '已完成';
      case 'failed':
        return '失败';
      case 'pending':
        return '等待中';
      default:
        return '未知状态';
    }
  }

  String _formatDateTime(int timestamp) {
    final localDateTime = DateTime.fromMillisecondsSinceEpoch(timestamp).toLocal();
    final now = DateTime.now();
    final difference = now.difference(localDateTime);

    if (difference.inDays == 0) {
      return '今天 ${localDateTime.hour.toString().padLeft(2, '0')}:'
             '${localDateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return '昨天 ${localDateTime.hour.toString().padLeft(2, '0')}:'
             '${localDateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${localDateTime.year}-'
             '${localDateTime.month.toString().padLeft(2, '0')}-'
             '${localDateTime.day.toString().padLeft(2, '0')} '
             '${localDateTime.hour.toString().padLeft(2, '0')}:'
             '${localDateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _urlController.dispose();
    _titleFilterController.dispose();
    _urlFilterController.dispose();
    super.dispose();
  }

  // 计算进度百分比
  int _calculateProgress(Task task) {
    if (task.currentStepIndex == null || task.totalSteps == null) return 0;
    return ((task.currentStepIndex! + 1) / task.totalSteps! * 100).round();
  }

  // 截断文本
  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  // 获取进度条颜色
  Color _getProgressColor(String status) {
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
} 