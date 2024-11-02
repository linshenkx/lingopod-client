import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../providers/settings_provider.dart';

class TaskProvider with ChangeNotifier {
  final ApiService _apiService;
  String? _currentTaskId;
  String? _taskStatus;
  String? _taskProgress;
  bool _isPolling = false;

  String? get taskStatus => _taskStatus;
  String? get taskProgress => _taskProgress;
  bool get isProcessing => _isPolling;

  TaskProvider(SettingsProvider settingsProvider) 
      : _apiService = ApiService(settingsProvider);

  Future<void> submitTask(String url) async {
    try {
      // 重置状态
      _taskStatus = 'processing';
      _taskProgress = '处理中...';
      notifyListeners();

      // 创建新任务
      _currentTaskId = await _apiService.createPodcastTask(url);
      
      // 开始轮询状态
      _startPolling();
    } catch (e) {
      _taskStatus = 'failed';
      _taskProgress = '创建任务失败: $e';
      notifyListeners();
    }
  }

  void _startPolling() {
    if (_currentTaskId == null || _isPolling) return;
    
    _isPolling = true;
    _pollTaskStatus();
  }

  Future<void> _pollTaskStatus() async {
    if (_currentTaskId == null) return;

    try {
      await _apiService.pollTaskStatus(
        _currentTaskId!,
        onProgress: (task) {
          _taskStatus = 'processing';
          _taskProgress = task['progress'] ?? '处理中...';
          notifyListeners();
        },
        onComplete: () async {
          _taskStatus = 'completed';
          _taskProgress = '任务完成';
          _isPolling = false;
          notifyListeners();
          
          // 触发任务完成回调
          if (_onTaskCompleted != null) {
            await _onTaskCompleted!();
          }
          
          // 延迟清除状态
          Future.delayed(const Duration(seconds: 3), () {
            _resetStatus();
          });
        },
        onError: (error) {
          _taskStatus = 'failed';
          _taskProgress = '任务失败: $error';
          _isPolling = false;
          notifyListeners();
          
          // 延迟清除状态
          Future.delayed(const Duration(seconds: 5), () {
            _resetStatus();
          });
        },
      );
    } catch (e) {
      _taskStatus = 'failed';
      _taskProgress = '获取任务状态失败: $e';
      _isPolling = false;
      notifyListeners();
    }
  }

  void _resetStatus() {
    _currentTaskId = null;
    _taskStatus = null;
    _taskProgress = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _isPolling = false;
    super.dispose();
  }

  // 添加任务完成回调
  Function? _onTaskCompleted;
  void setOnTaskCompleted(Function callback) {
    _onTaskCompleted = callback;
  }
}
