import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
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
    int? startDate,
    int? endDate,
  }) async {
    try {
      final queryParams = {
        if (status != null) 'status': status,
        if (isPublic != null) 'is_public': isPublic,
        if (titleKeyword != null) 'title_keyword': titleKeyword,
        if (urlKeyword != null) 'url_keyword': urlKeyword,
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
      };

      // 打印查询参数，帮助调试
      debugPrint('getPodcastList 查询参数: $queryParams');

      final items = await _fetchItems(
        endpoint: ApiConstants.tasks,
        limit: limit,
        offset: offset,
        additionalParams: queryParams,
        processUrls: true,
      );

      return items.map((json) {
        try {
          return Podcast.fromJson(json);
        } catch (e, stack) {
          debugPrint('跳过无效的播客数据: taskId=${json['taskId']}\n错误: $e\n堆栈: $stack');
          // 在这里，我们不再直接 rethrow，而是记录错误
          return null;
        }
      }).whereType<Podcast>().toList(); // 过滤掉转换失败的项目
    } catch (e) {
      // 更详细的错误日志
      debugPrint('getPodcastList 获取数据失败: $e');
      throw Exception('加载播客列表失败: $e');
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
      rethrow;
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

  Future<List<Map<String, dynamic>>> fetchUserTasks({
    int limit = 20,
    int offset = 0,
    String? status,
    bool? isPublic,
    String? titleKeyword,
    String? urlKeyword,
    int? startDate,
    int? endDate,
  }) async {
    final queryParams = <String, dynamic>{
      if (status != null) 'status': status,
      if (isPublic != null) 'is_public': isPublic,
      if (titleKeyword != null) 'title_keyword': titleKeyword,
      if (urlKeyword != null) 'url_keyword': urlKeyword,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
    };

    return _fetchItems(
      endpoint: ApiConstants.tasks,
      limit: limit,
      offset: offset,
      additionalParams: queryParams,
    );
  }

  Future<List<Map<String, dynamic>>> _fetchItems({
    required String endpoint,
    int limit = 20,
    int offset = 0,
    Map<String, dynamic>? additionalParams,
    bool processUrls = false,
  }) async {
    try {
      // 准备查询参数，确保所有值都被安全转换
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };

      // 智能添加额外参数，确保安全转换
      if (additionalParams != null) {
        additionalParams.forEach((key, value) {
          if (value != null) {
            // 安全地将各种类型转换为字符串
            if (value is bool) {
              queryParams[key] = value.toString();
            } else if (value is int) {
              queryParams[key] = value.toString();
            } else if (value is String) {
              queryParams[key] = value;
            } else {
              // 对于其他类型，尝试调用 toString()
              queryParams[key] = value.toString();
            }
          }
        });
      }

      // 解析基础 URL
      final uri = Uri.parse('$baseUrl$endpoint').replace(
        queryParameters: queryParams
      );

      debugPrint('请求 URL: $uri');

      final response = await http.get(
        uri, 
        headers: _headers
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final String decodedBody = utf8.decode(response.bodyBytes);
        
        final Map<String, dynamic> responseData = json.decode(decodedBody);
        
        // 添加类型检查
        if (responseData['items'] == null) {
          debugPrint('Warning: No items found in the response');
          return [];
        }

        // 确保 items 是一个列表
        final List<dynamic> items = responseData['items'] is List 
            ? responseData['items'] 
            : [responseData['items']];
        
        // 处理 URL 和时间戳
        return items.map((dynamic item) {
          // 确保 item 是 Map 类型
          if (item is! Map) {
            debugPrint('Warning: Non-map item found: $item');
            return <String, dynamic>{};
          }

          final json = Map<String, dynamic>.from(item);
          

          // 可选的 URL 处理
          if (processUrls && json['taskId'] != null) {
            final taskId = json['taskId'];
            json['audioUrlCn'] = _getTaskFileUrl(taskId, json['audioUrlCn']);
            json['audioUrlEn'] = _getTaskFileUrl(taskId, json['audioUrlEn']);
            json['subtitleUrlCn'] = _getTaskFileUrl(taskId, json['subtitleUrlCn']);
            json['subtitleUrlEn'] = _getTaskFileUrl(taskId, json['subtitleUrlEn']);
          }
          
          return json;
        }).toList();
      }
      
      throw _handleErrorResponse(response);
    } catch (e) {
      debugPrint('获取数据失败详细信息: $e');
      throw Exception('获取数据失败: $e');
    }
  }

  Future<void> updateTask(String taskId, {
    String? title,
    bool? isPublic,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl${ApiConstants.task(taskId)}'),
      headers: _headers,
      body: json.encode({
        if (title != null) 'title': title,
        if (isPublic != null) 'is_public': isPublic,
      }),
    ).timeout(timeout);

    if (response.statusCode != 200) {
      throw _handleErrorResponse(response);
    }
  }
}
