import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../models/style_params.dart';
import '../widgets/create_task_dialog.dart';
import '../config/style_config.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class TaskManagementScreen extends StatefulWidget {
  const TaskManagementScreen({super.key});

  @override
  _TaskManagementScreenState createState() => _TaskManagementScreenState();
}

class _TaskManagementScreenState extends State<TaskManagementScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _titleFilterController = TextEditingController();
  final TextEditingController _urlFilterController = TextEditingController();
  bool _isPublic = false;
  String _statusFilter = 'all';
  String _visibilityFilter = 'all';
  DateTime? _startDate;
  DateTime? _endDate;
  Timer? _refreshTimer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: StyleConfig.animDurationNormal,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().fetchTasks();
      _startAutoRefresh();
    });
  }

  Widget _buildFilters() {
    return Card(
      margin: EdgeInsets.all(StyleConfig.spacingM),
      child: Padding(
        padding: EdgeInsets.all(StyleConfig.spacingM),
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isWideScreen =
                constraints.maxWidth > StyleConfig.tabletBreakpoint;
            return Column(
              children: [
                if (isWideScreen)
                  Row(
                    children: [
                      Expanded(child: _buildFilterDropdowns()),
                      SizedBox(width: StyleConfig.spacingM),
                      Expanded(child: _buildSearchFields()),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildFilterDropdowns(),
                      SizedBox(height: StyleConfig.spacingM),
                      _buildSearchFields(),
                    ],
                  ),
                SizedBox(height: StyleConfig.spacingM),
                _buildFilterActions(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterDropdowns() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _statusFilter,
            decoration: InputDecoration(
              labelText: '状态',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(StyleConfig.radiusM),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: StyleConfig.spacingM,
                vertical: StyleConfig.spacingS,
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('全部状态')),
              DropdownMenuItem(value: 'pending', child: Text('等待中')),
              DropdownMenuItem(value: 'processing', child: Text('处理中')),
              DropdownMenuItem(value: 'completed', child: Text('已完成')),
              DropdownMenuItem(value: 'failed', child: Text('失败')),
            ],
            onChanged: (value) => setState(() => _statusFilter = value!),
          ),
        ),
        SizedBox(width: StyleConfig.spacingM),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _visibilityFilter,
            decoration: InputDecoration(
              labelText: '可见性',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(StyleConfig.radiusM),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: StyleConfig.spacingM,
                vertical: StyleConfig.spacingS,
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('全部')),
              DropdownMenuItem(value: 'public', child: Text('仅看公开')),
              DropdownMenuItem(value: 'private', child: Text('仅看私有')),
            ],
            onChanged: (value) => setState(() => _visibilityFilter = value!),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchFields() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _titleFilterController,
            decoration: InputDecoration(
              labelText: '标题',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(StyleConfig.radiusM),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: StyleConfig.spacingM,
                vertical: StyleConfig.spacingS,
              ),
            ),
          ),
        ),
        SizedBox(width: StyleConfig.spacingM),
        Expanded(
          child: TextField(
            controller: _urlFilterController,
            decoration: InputDecoration(
              labelText: 'URL',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(StyleConfig.radiusM),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: StyleConfig.spacingM,
                vertical: StyleConfig.spacingS,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          onPressed: _resetFilters,
          icon: const Icon(Icons.clear),
          label: const Text('重置'),
        ),
        SizedBox(width: StyleConfig.spacingM),
        ElevatedButton.icon(
          onPressed: () => context.read<TaskProvider>().fetchTasks(
                status: _statusFilter == 'all' ? null : _statusFilter,
                isPublic: _visibilityFilter == 'public'
                    ? true
                    : _visibilityFilter == 'private'
                        ? false
                        : null,
                titleKeyword: _titleFilterController.text,
                urlKeyword: _urlFilterController.text,
                startDate: _startDate?.millisecondsSinceEpoch,
                endDate: _endDate?.millisecondsSinceEpoch,
              ),
          icon: const Icon(Icons.search),
          label: const Text('查询'),
        ),
      ],
    );
  }

  Widget _buildTaskList() {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        if (taskProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (taskProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  taskProvider.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                SizedBox(height: StyleConfig.spacingM),
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
                SizedBox(height: StyleConfig.spacingM),
                ElevatedButton.icon(
                  onPressed: _showCreateTaskDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('创建任务'),
                ),
              ],
            ),
          );
        }

        return FadeTransition(
          opacity: _fadeAnimation,
          child: RefreshIndicator(
            onRefresh: () => taskProvider.fetchTasks(),
            child: ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: StyleConfig.spacingM,
                vertical: StyleConfig.spacingS,
              ),
              itemCount: taskProvider.tasks.length,
              itemBuilder: (context, index) {
                return _buildTaskItem(context, taskProvider.tasks[index]);
              },
            ),
          ),
        );
      },
    );
  }

  // 复制到剪贴板的工具方法
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('复制成功!')),
      );
    });
  }

  // 编辑任务对话框
  void _showEditTaskDialog(Task task) {
    final TextEditingController titleController =
        TextEditingController(text: task.title);
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
    final audioProvider = context.read<AudioProvider>();
    final tasks = taskProvider.tasks;
    bool needRefreshAll = false;

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

          // 如果任务完成或失败，标记需要刷新
          if (updatedTask.status == 'completed' ||
              updatedTask.status == 'failed') {
            needRefreshAll = true;
          }
        } catch (e) {
          debugPrint('Failed to update task ${task.id}: $e');
          // 获取单个任务失败时继续处理其他任务
          continue;
        }
      }
    }

    // 如果有任务完成或失败，刷新整个列表
    if (needRefreshAll) {
      taskProvider.fetchTasks();
      // 同时刷新播放列表
      await audioProvider.refreshPodcastList();
    }
  }

  Widget _buildTaskItem(BuildContext context, Task task) {
    final theme = Theme.of(context);
    final errorTextStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.error,
      height: 1.5,
    );

    // 处理 URL 显示
    String displayUrl = task.url;
    if (displayUrl.length > 60) {
      final uri = Uri.parse(displayUrl);
      final host = uri.host;
      final path = uri.path;
      final shortPath = path.length > 30
          ? '${path.substring(0, 15)}...${path.substring(path.length - 15)}'
          : path;
      displayUrl = '$host$shortPath';
    }

    return Card(
      margin: EdgeInsets.only(bottom: StyleConfig.spacingS),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(StyleConfig.radiusS),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(StyleConfig.radiusS),
        onTap: () => _showTaskDetails(task),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: StyleConfig.spacingM,
            vertical: StyleConfig.spacingS,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title ?? displayUrl,
                          style: theme.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (task.url.isNotEmpty) ...[
                          const SizedBox(height: StyleConfig.spacingXS),
                          InkWell(
                            onTap: () => _copyToClipboard(task.url),
                            child: Text(
                              displayUrl,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _buildTaskActions(task),
                ],
              ),
              if (task.status != 'completed' && task.status != 'failed') ...[
                const SizedBox(height: StyleConfig.spacingS),
                _buildProgressIndicator(task),
              ],
              if (task.progressMessage != null &&
                  task.status != 'failed' &&
                  task.status != 'completed') ...[
                const SizedBox(height: StyleConfig.spacingS),
                _buildProgressMessage(task.progressMessage!),
              ],
              if (task.status == 'failed' && task.errorMessage != null) ...[
                const SizedBox(height: StyleConfig.spacingS),
                _buildErrorMessage(task.errorMessage!, errorTextStyle),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(Task task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                task.currentStep ?? '准备中',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.8),
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (task.currentStepIndex != null && task.totalSteps != null)
              Text(
                '${_calculateProgress(task)}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.8),
                    ),
              ),
          ],
        ),
        const SizedBox(height: StyleConfig.spacingXS),
        LinearProgressIndicator(
          value: task.currentStepIndex != null && task.totalSteps != null
              ? (task.currentStepIndex! + 1) / task.totalSteps!
              : null,
          backgroundColor: Colors.grey[200],
          valueColor:
              AlwaysStoppedAnimation<Color>(_getProgressColor(task.status)),
        ),
      ],
    );
  }

  Widget _buildProgressMessage(String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(StyleConfig.spacingS),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(StyleConfig.radiusS),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Theme.of(context).colorScheme.primary,
            size: 16,
          ),
          SizedBox(width: StyleConfig.spacingXS),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    height: 1.4,
                  ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String message, TextStyle? errorTextStyle) {
    return InkWell(
      onTap: () => _copyToClipboard(message),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(StyleConfig.spacingS),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(StyleConfig.radiusS),
          border: Border.all(
            color: Theme.of(context).colorScheme.error.withOpacity(0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 16,
            ),
            SizedBox(width: StyleConfig.spacingXS),
            Expanded(
              child: Text(
                message,
                style:
                    errorTextStyle?.copyWith(fontSize: StyleConfig.fontSizeS),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: StyleConfig.spacingXS),
            Tooltip(
              message: '点击复制错误信息',
              child: Icon(
                Icons.copy,
                color: Theme.of(context).colorScheme.error.withOpacity(0.7),
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTaskDetails(Task task) {
    // TODO: 实现任务详情页面
  }

  void _showCreateTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateTaskDialog(),
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
            onPressed: () async {
              await context.read<TaskProvider>().deleteTask(task.id);
              if (context.mounted) {
                Navigator.pop(context);
                // 删除任务后刷新播放列表
                context.read<AudioProvider>().refreshPodcastList();
              }
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
    final localDateTime =
        DateTime.fromMillisecondsSinceEpoch(timestamp).toLocal();
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
    _animationController.dispose();
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

  Widget _buildTaskActions(Task task) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit, size: 20),
          onPressed: () => _showEditTaskDialog(task),
          tooltip: '编辑',
          visualDensity: VisualDensity.compact,
          constraints: BoxConstraints.tight(Size.square(StyleConfig.spacingXL)),
        ),
        if (task.status == 'failed')
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => _retryTask(task),
            tooltip: '重试',
            visualDensity: VisualDensity.compact,
            constraints:
                BoxConstraints.tight(Size.square(StyleConfig.spacingXL)),
          ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: () => _showDeleteConfirmDialog(task),
          tooltip: '删除任务',
          visualDensity: VisualDensity.compact,
          constraints: BoxConstraints.tight(Size.square(StyleConfig.spacingXL)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('任务管理'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateTaskDialog,
            tooltip: '创建新任务',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(child: _buildTaskList()),
        ],
      ),
    );
  }
}
