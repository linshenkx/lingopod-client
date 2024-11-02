import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_constants.dart';
import '../models/podcast.dart';
import '../providers/settings_provider.dart';

class ApiService {
  static const timeout = Duration(seconds: 30);
  final SettingsProvider _settingsProvider;
  
  ApiService(this._settingsProvider);

  String get baseUrl => _settingsProvider.baseUrl;

  String _getFullUrl(String? path) {
    if (path == null) return '';
    if (path.startsWith('http')) return path;
    final uri = Uri.parse(baseUrl);
    final baseHost = '${uri.scheme}://${uri.host}:${uri.port}';
    return '$baseHost$path';
  }

  Future<List<Podcast>> getPodcastList() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl${ApiConstants.getList}'),
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        final String decodedBody = utf8.decode(response.bodyBytes);
        final List<dynamic> data = json.decode(decodedBody);
        return data.map((json) {
          json['audio_url_cn'] = _getFullUrl(json['audioUrlCn']);
          json['audio_url_en'] = _getFullUrl(json['audioUrlEn']);
          json['subtitle_url_cn'] = _getFullUrl(json['subtitleUrlCn']);
          json['subtitle_url_en'] = _getFullUrl(json['subtitleUrlEn']);
          return Podcast.fromJson(json);
        }).toList();
      }
      
      throw _handleErrorResponse(response);
    } catch (e) {
      throw Exception('获取播客列表失败: $e');
    }
  }

  Future<String> createPodcastTask(String url) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConstants.postTask}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'url': url}),
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        final String decodedBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = json.decode(decodedBody);
        final taskId = data['taskId'];
        if (taskId == null) {
          throw Exception('服务器返回的 taskId 为空');
        }
        return taskId.toString();
      }
      
      throw _handleErrorResponse(response);
    } catch (e) {
      throw Exception('创建任务失败: $e');
    }
  }

  Future<Map<String, dynamic>> getTaskStatus(String taskId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl${ApiConstants.getTask}?taskId=$taskId'))
          .timeout(timeout);
      
      if (response.statusCode == 200) {
        final String decodedBody = utf8.decode(response.bodyBytes);
        return json.decode(decodedBody);
      }
      
      throw _handleErrorResponse(response);
    } catch (e) {
      throw Exception('获取任务状态失败: $e');
    }
  }

  Future<void> pollTaskStatus(String taskId, {
    required Function(Map<String, dynamic>) onProgress,
    required Function() onComplete,
    required Function(String) onError,
  }) async {
    bool shouldContinue = true;
    
    while (shouldContinue) {
      try {
        final task = await getTaskStatus(taskId);
        
        switch (task['status']) {
          case 'completed':
            onComplete();
            shouldContinue = false;
            break;
          case 'failed':
            onError(task['message'] ?? '任务失败');
            shouldContinue = false;
            break;
          case 'processing':
            onProgress(task);
            await Future.delayed(const Duration(seconds: 2));
            break;
          default:
            shouldContinue = false;
            onError('未知状态');
        }
      } catch (e) {
        shouldContinue = false;
        onError(e.toString());
      }
    }
  }

  Exception _handleErrorResponse(http.Response response) {
    try {
      final String decodedBody = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> error = json.decode(decodedBody);
      return Exception(error['message'] ?? '未知错误');
    } catch (e) {
      return Exception('请求失败: ${response.statusCode}');
    }
  }

  Future<bool> deletePodcast(String taskId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl${ApiConstants.deleteTask}/$taskId'),
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        return true;
      }
      
      throw _handleErrorResponse(response);
    } catch (e) {
      throw Exception('删除播客失败: $e');
    }
  }
}
