import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_constants.dart';
import '../models/podcast.dart';
import '../providers/settings_provider.dart';
import '../models/user.dart';
import '../services/auth_manager.dart';

class ApiService {
  static const timeout = Duration(seconds: 30);
  final SettingsProvider _settingsProvider;
  
  ApiService(this._settingsProvider);

  String get baseUrl => _settingsProvider.baseUrl;

  String _getTaskFileUrl(String taskId, String? filename) {
    if (filename == null) return '';
    final uri = Uri.parse(baseUrl);
    final baseHost = '${uri.scheme}://${uri.host}:${uri.port}/api/v1/tasks/files';
    final token = AuthManager().token;
    if (token != null && token.isNotEmpty) {
      return '$baseHost/$taskId/$filename?token=$token';
    }
    return '$baseHost/$taskId/$filename';
  }

  Future<List<Podcast>> getPodcastList({
    int limit = 10,
    int offset = 0,
    String? status,
    bool? isPublic,
    String? titleKeyword,
    String? urlKeyword,
  }) async {
    try {
      final queryParams = {
        'limit': limit.toString(),
        'offset': offset.toString(),
        if (status != null) 'status': status,
        if (isPublic != null) 'is_public': isPublic.toString(),
        if (titleKeyword != null) 'title_keyword': titleKeyword,
        if (urlKeyword != null) 'url_keyword': urlKeyword,
      };

      final uri = Uri.parse('$baseUrl${ApiConstants.tasks}')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: _headers,
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        final String decodedBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> responseData = json.decode(decodedBody);
        final List<dynamic> data = responseData['items'] as List<dynamic>;
        
        return data.map((json) {
          final taskId = json['taskId'];
          json['audio_url_cn'] = _getTaskFileUrl(taskId, json['audioUrlCn']);
          json['audio_url_en'] = _getTaskFileUrl(taskId, json['audioUrlEn']);
          json['subtitle_url_cn'] = _getTaskFileUrl(taskId, json['subtitleUrlCn']);
          json['subtitle_url_en'] = _getTaskFileUrl(taskId, json['subtitleUrlEn']);
          return Podcast.fromJson(json);
        }).toList();
      }
      
      throw _handleErrorResponse(response);
    } catch (e) {
      throw Exception('获取播客列表失败: $e');
    }
  }

  Future<String> createPodcastTask(String url, {bool isPublic = false}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConstants.tasks}'),
        headers: _headers,
        body: json.encode({
          'url': url,
          'is_public': isPublic
        }),
      ).timeout(timeout);
      
      if (response.statusCode == 201) {
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
      final response = await http.get(
        Uri.parse('$baseUrl${ApiConstants.task(taskId)}'),
        headers: _headers,
      ).timeout(timeout);
      
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
        Uri.parse('$baseUrl${ApiConstants.task(taskId)}'),
        headers: _headers,
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        return true;
      }
      
      throw _handleErrorResponse(response);
    } catch (e) {
      throw Exception('删除播客失败: $e');
    }
  }

  Future<void> retryTask(String taskId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConstants.taskRetry(taskId)}'),
        headers: _headers,
      ).timeout(timeout);
      
      if (response.statusCode != 200) {
        throw _handleErrorResponse(response);
      }
    } catch (e) {
      throw Exception('重试任务失败: $e');
    }
  }

  Future<http.Response> getTaskFile(String taskId, String filename) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl${ApiConstants.taskFile(taskId, filename)}'),
        headers: _headers,
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        return response;
      }
      
      throw _handleErrorResponse(response);
    } catch (e) {
      throw Exception('获取任务文件失败: $e');
    }
  }

  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    final token = AuthManager().token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConstants.login}'),
        body: {
          'username': username,
          'password': password,
        },
      ).timeout(timeout);
      
      final String decodedBody = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> data = json.decode(decodedBody);
      
      if (response.statusCode == 200) {
        AuthManager().setToken(data['access_token']);
        return data;
      }
      
      throw data['detail'] ?? '未知错误';
    } on TimeoutException {
      throw '请求超时';
    } catch (e) {
      throw '登录失败: $e';
    }
  }

  Future<void> register(String username, String password, {String? nickname}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConstants.register}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
          if (nickname != null) 'nickname': nickname,
        }),
      ).timeout(timeout);
      
      if (response.statusCode == 201) {
        return;
      }
      
      final String decodedBody = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> data = json.decode(decodedBody);
      throw data['detail'] ?? '注册失败';
    } on TimeoutException {
      throw '请求超时';
    } catch (e) {
      if (e is String) throw e;
      throw e.toString();
    }
  }

  Future<User> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl${ApiConstants.me}'),
        headers: _headers,
      ).timeout(timeout);
      
      if (response.statusCode == 200) {
        final String decodedBody = utf8.decode(response.bodyBytes);
        return User.fromJson(json.decode(decodedBody));
      }
      
      throw _handleErrorResponse(response);
    } catch (e) {
      throw Exception('获取用户信息失败: $e');
    }
  }
}
