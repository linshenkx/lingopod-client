import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../providers/settings_provider.dart';
import '../models/task.dart';
import '../models/style_params.dart';

class TaskProvider with ChangeNotifier {
  final ApiService _apiService;

  List<Task> _tasks = [];
  List<Task> get tasks => _tasks;

  // 新增加载状态
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _currentTaskId;
  String? _taskStatus;
  String? _taskProgress;
  bool _isPolling = false;
  String? _currentStep;
  int? _stepProgress;

  String? get taskStatus => _taskStatus;
  String? get taskProgress => _taskProgress;
  bool get isProcessing => _isPolling;
  String? get currentStep => _currentStep;
  int? get stepProgress => _stepProgress;
  String? get currentTaskId => _currentTaskId;

  String? _error;
  String? get error => _error;

  TaskProvider(SettingsProvider settingsProvider)
      : _apiService = ApiService(settingsProvider);

  // 新增获取任务列表的方法
  Future<void> fetchTasks({
    String? status,
    bool? isPublic,
    String? titleKeyword,
    String? urlKeyword,
    int? startDate,
    int? endDate,
  }) async {
    try {
      _error = null;
      _isLoading = true;
      notifyListeners();

      final tasksData = await _apiService.fetchUserTasks(
        status: status,
        isPublic: isPublic,
        titleKeyword: titleKeyword,
        urlKeyword: urlKeyword,
        startDate: startDate,
        endDate: endDate,
      );

      _tasks = tasksData.map((json) => Task.fromJson(json)).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = '获取任务列表失败: $e';
      notifyListeners();
    }
  }

  // 保留原有的提交任务方法
  Future<void> submitTask(
    String url, {
    bool isPublic = false,
    StyleParams? styleParams,
  }) async {
    try {
      final taskId = await _apiService.createPodcastTask(
        url,
        isPublic: isPublic,
        styleParams: styleParams,
      );

      if (taskId.isEmpty) {
        throw Exception('无效的任务ID');
      }

      // 创建临时 Task 对象并添加到列表
      final newTask = Task(
        id: taskId,
        url: url,
        status: 'processing',
        progress: 'waiting',
        isPublic: isPublic,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        userId: 0, // 这里暂时用0,因为还没有获取到真实的userId
        createdBy: 0, // 同上
        styleParams: styleParams,
      );
      _tasks.insert(0, newTask);
      notifyListeners();

      // 开始轮询任务状态
      _pollTaskStatus(taskId);
    } catch (e) {
      debugPrint('创建任务失败: $e');
      // 直接抛出原始错误
      rethrow;
    }
  }

  Future<void> _pollTaskStatus(String taskId) async {
    try {
      bool shouldContinue = true;

      while (shouldContinue) {
        try {
          final taskStatus = await _apiService.getTaskStatus(taskId);

          switch (taskStatus['status']) {
            case 'processing':
              // 更新进度和当前步骤
              final index = _tasks.indexWhere((t) => t.id == taskId);
              if (index != -1) {
                _tasks[index] = _tasks[index].copyWith(
                  progress: taskStatus['progress']?.toString() ?? 'processing',
                  currentStep: taskStatus['current_step'],
                  currentStepIndex: taskStatus['current_step_index'],
                  totalSteps: taskStatus['total_steps'],
                  progressMessage: taskStatus['progress_message'],
                );
                notifyListeners();
              }
              await Future.delayed(const Duration(seconds: 2));
              break;

            case 'completed':
              final index = _tasks.indexWhere((t) => t.id == taskId);
              if (index != -1) {
                _tasks[index] = _tasks[index].copyWith(
                  status: 'completed',
                  progress: 'completed',
                  currentStep: '处理完成',
                  progressMessage: taskStatus['progress_message'],
                );
                notifyListeners();
              }
              shouldContinue = false;
              break;

            case 'failed':
              final index = _tasks.indexWhere((t) => t.id == taskId);
              if (index != -1) {
                _tasks[index] = _tasks[index].copyWith(
                  status: 'failed',
                  progress: 'failed',
                  currentStep: '处理失败',
                  errorMessage: taskStatus['progress_message'] ??
                      taskStatus['error'] ??
                      '未知错误',
                );
                notifyListeners();
              }
              shouldContinue = false;
              break;

            default:
              shouldContinue = false;
              break;
          }
        } catch (e) {
          // 网络错误或其他异常
          final index = _tasks.indexWhere((t) => t.id == taskId);
          if (index != -1) {
            _tasks[index] = _tasks[index].copyWith(
              status: 'failed',
              progress: 'failed',
              currentStep: '处理失败',
              errorMessage: '网络错误: ${e.toString()}',
            );
            notifyListeners();
          }
          shouldContinue = false;
        }
      }
    } catch (e) {
      debugPrint('轮询任务状态失败: $e');
    }
  }

  void _resetStatus() {
    _currentTaskId = null;
    _taskStatus = null;
    _taskProgress = null;
    _currentStep = null;
    _stepProgress = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _isPolling = false;
    super.dispose();
  }

  Future<void> retryTask(String taskId) async {
    try {
      await _apiService.retryTask(taskId);

      // 更新任务状态为处理中
      final index = _tasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        _tasks[index] = _tasks[index].copyWith(
          status: 'processing',
          progress: 'waiting',
          currentStep: null,
        );
        notifyListeners();

        // 重新开始轮询
        _pollTaskStatus(taskId);
      }
    } catch (e) {
      print('重试任务失败: $e');
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _apiService.deletePodcast(taskId);

      // 从列表中移除任务
      _tasks.removeWhere((t) => t.id == taskId);
      notifyListeners();
    } catch (e) {
      print('删除任务失败: $e');
    }
  }

  Future<void> updateTask(
    String taskId, {
    String? title,
    bool? isPublic,
  }) async {
    try {
      await _apiService.updateTask(taskId, title: title, isPublic: isPublic);
      await fetchTasks();
    } catch (e) {
      debugPrint('更新任务失败: $e');
    }
  }

  Future<Task> getTaskDetail(String taskId) async {
    try {
      final taskData = await _apiService.getTaskStatus(taskId);
      return Task.fromJson(taskData);
    } catch (e) {
      throw Exception('获取任务详情失败');
    }
  }

  // 在本地更新任务状态
  void updateTaskLocally(Task updatedTask) {
    final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      notifyListeners();
    }
  }
}
