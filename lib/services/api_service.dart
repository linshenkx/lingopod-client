import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../config/api_constants.dart';
import '../models/podcast.dart';
import '../providers/settings_provider.dart';
import '../models/user.dart';
import '../services/auth_manager.dart';
import '../models/style_params.dart';
import '../models/rss_feed.dart';
import '../main.dart';

class ApiService {
  static const timeout = Duration(seconds: 30);
  final SettingsProvider _settingsProvider;

  ApiService(this._settingsProvider);

  String get baseUrl => _settingsProvider.baseUrl;

  String _getTaskFileUrl(
      String taskId, String level, String lang, String type) {
    final uri = Uri.parse(baseUrl);
    final baseHost =
        '${uri.scheme}://${uri.host}:${uri.port}/api/v1/tasks/files';
    final token = AuthManager().token;
    if (token != null && token.isNotEmpty) {
      return '$baseHost/$taskId/$level/$lang/$type?token=$token';
    }
    return '$baseHost/$taskId/$level/$lang/$type';
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

      return items
          .map((json) {
            try {
              return Podcast.fromJson(json);
            } catch (e, stack) {
              debugPrint(
                  '跳过无效的播客数据: taskId=${json['taskId']}\n错误: $e\n堆栈: $stack');
              // 在这里，我们不再直接 rethrow，而是记录错误
              return null;
            }
          })
          .whereType<Podcast>()
          .toList(); // 过滤掉转换失败的项目
    } catch (e) {
      // 更详细的错误日志
      debugPrint('getPodcastList 获取数据失败: $e');
      throw Exception('加载播客列表失败: $e');
    }
  }

  Future<String> createPodcastTask(
    String url, {
    bool isPublic = false,
    StyleParams? styleParams,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl${ApiConstants.tasks}'),
            headers: _headers,
            body: json.encode({
              'url': url,
              'is_public': isPublic,
              if (styleParams != null) 'style_params': styleParams.toJson(),
            }),
          )
          .timeout(timeout);

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
      final response = await http
          .get(
            Uri.parse('$baseUrl${ApiConstants.task(taskId)}'),
            headers: _headers,
          )
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

  Future<void> pollTaskStatus(
    String taskId, {
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
      // 如果状态码是200，不应该被视为错误
      if (response.statusCode == 200) {
        return Exception('Success');
      }

      // 处理401未授权错误
      if (response.statusCode == 401) {
        AuthManager().clearToken();
        // 使用全局导航器跳转到登录页面
        if (navigatorKey.currentContext != null) {
          Navigator.of(navigatorKey.currentContext!).pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        }
        return Exception('登录已过期，请重新登录');
      }

      final String decodedBody = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> error = json.decode(decodedBody);
      return Exception(error['message'] ?? '未知错误');
    } catch (e) {
      return Exception('请求失败: ${response.statusCode}');
    }
  }

  Future<bool> deletePodcast(String taskId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl${ApiConstants.task(taskId)}'),
            headers: _headers,
          )
          .timeout(timeout);

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
      final response = await http
          .post(
            Uri.parse('$baseUrl${ApiConstants.taskRetry(taskId)}'),
            headers: _headers,
          )
          .timeout(timeout);

      if (response.statusCode != 200) {
        throw _handleErrorResponse(response);
      }
    } catch (e) {
      throw Exception('重试任务失败: $e');
    }
  }

  Future<http.Response> getTaskFile(String taskId, String filename) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl${ApiConstants.taskFile(taskId, filename)}'),
            headers: _headers,
          )
          .timeout(timeout);

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

  Future<void> register(String username, String password,
      {String? nickname}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl${ApiConstants.register}'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'username': username,
              'password': password,
              if (nickname != null) 'nickname': nickname,
            }),
          )
          .timeout(timeout);

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
      final response = await http
          .get(
            Uri.parse('$baseUrl${ApiConstants.me}'),
            headers: _headers,
          )
          .timeout(timeout);

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
    String? status,
    bool? isPublic,
    String? titleKeyword,
    String? urlKeyword,
    int? startDate,
    int? endDate,
  }) async {
    final additionalParams = {
      if (status != null) 'status': status,
      if (isPublic != null) 'is_public': isPublic,
      if (titleKeyword != null) 'title_keyword': titleKeyword,
      if (urlKeyword != null) 'url_keyword': urlKeyword,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
    };

    final items = await _fetchItems(
      endpoint: ApiConstants.tasks,
      additionalParams: additionalParams,
      processUrls: true,
    );

    return items.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  Future<List<dynamic>> _fetchItems({
    required String endpoint,
    int limit = 10,
    int offset = 0,
    Map<String, dynamic>? additionalParams,
    bool processUrls = false,
  }) async {
    try {
      final queryParams = {
        'limit': limit.toString(),
        'offset': offset.toString(),
        ...?additionalParams,
      };

      // 解析基础 URL
      final uri =
          Uri.parse('$baseUrl$endpoint').replace(queryParameters: queryParams);

      debugPrint('请求 URL: $uri');

      final response = await http.get(uri, headers: _headers).timeout(timeout);

      if (response.statusCode == 200) {
        final String decodedBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = json.decode(decodedBody);
        final items = data['items'] as List<dynamic>;

        if (processUrls) {
          return items.map((item) {
            final json = Map<String, dynamic>.from(item);
            final taskId = json['taskId'];

            // 处理文件URL
            if (taskId != null && json['files'] != null) {
              final files = json['files'] as Map<String, dynamic>;
              files.forEach((level, levelData) {
                if (levelData is Map) {
                  (levelData as Map<String, dynamic>).forEach((lang, langData) {
                    if (langData is Map) {
                      (langData as Map<String, dynamic>).forEach((type, url) {
                        if (url is String) {
                          files[level][lang][type] =
                              _getTaskFileUrl(taskId, level, lang, type);
                        }
                      });
                    }
                  });
                }
              });
              json['files'] = files;
            }

            return json;
          }).toList();
        }

        return items;
      }

      throw _handleErrorResponse(response);
    } catch (e) {
      debugPrint('获取数据失败详细信息: $e');
      throw Exception('获取数据失败: $e');
    }
  }

  Future<void> updateTask(
    String taskId, {
    String? title,
    bool? isPublic,
  }) async {
    final response = await http
        .patch(
          Uri.parse('$baseUrl${ApiConstants.task(taskId)}'),
          headers: _headers,
          body: json.encode({
            if (title != null) 'title': title,
            if (isPublic != null) 'is_public': isPublic,
          }),
        )
        .timeout(timeout);

    if (response.statusCode != 200) {
      throw _handleErrorResponse(response);
    }
  }

  // RSS Feed APIs
  Future<RssFeed> createRssFeed(Map<String, dynamic> feedData) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl${ApiConstants.rssFeeds}'),
            headers: _headers,
            body: json.encode(feedData),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final String decodedBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = json.decode(decodedBody);
        return RssFeed.fromJson(data);
      }

      throw _handleErrorResponse(response);
    } catch (e) {
      throw Exception('创建RSS订阅失败: $e');
    }
  }

  Future<List<RssFeed>> getRssFeeds() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl${ApiConstants.rssFeeds}'),
            headers: _headers,
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final String decodedBody = utf8.decode(response.bodyBytes);
        final List<dynamic> data = json.decode(decodedBody);
        return data.map((json) => RssFeed.fromJson(json)).toList();
      }

      throw _handleErrorResponse(response);
    } catch (e) {
      throw Exception('获取RSS订阅列表失败: $e');
    }
  }

  Future<RssFeed> getRssFeed(int feedId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl${ApiConstants.rssFeed(feedId)}'),
            headers: _headers,
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final String decodedBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = json.decode(decodedBody);
        return RssFeed.fromJson(data);
      }

      throw _handleErrorResponse(response);
    } catch (e) {
      throw Exception('获取RSS订阅失败: $e');
    }
  }

  Future<RssFeed> updateRssFeed(int feedId,
      {int? initialEntriesCount, int? updateEntriesCount}) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl${ApiConstants.rssFeed(feedId)}'),
          headers: _headers,
          body: json.encode({
            if (initialEntriesCount != null)
              'initial_entries_count': initialEntriesCount,
            if (updateEntriesCount != null)
              'update_entries_count': updateEntriesCount,
          }),
        )
        .timeout(timeout);

    if (response.statusCode == 200) {
      final String decodedBody = utf8.decode(response.bodyBytes);
      return RssFeed.fromJson(json.decode(decodedBody));
    }
    throw _handleErrorResponse(response);
  }

  Future<void> deleteRssFeed(int feedId) async {
    final response = await http
        .delete(
          Uri.parse('$baseUrl${ApiConstants.rssFeed(feedId)}'),
          headers: _headers,
        )
        .timeout(timeout);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw _handleErrorResponse(response);
    }
  }

  Future<void> fetchRssFeed(int feedId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl${ApiConstants.rssFeedFetch(feedId)}'),
            headers: _headers,
          )
          .timeout(timeout);

      if (response.statusCode != 200) {
        throw _handleErrorResponse(response);
      }
    } on TimeoutException {
      throw '请求超时，请检查网络连接';
    } on http.ClientException catch (e) {
      throw '网络请求失败: ${e.message}';
    } on FormatException catch (e) {
      throw '数据格式错误: ${e.message}';
    } catch (e) {
      throw '获取RSS订阅失败: ${e.toString()}';
    }
  }

  Future<List<Map<String, dynamic>>> getRssFeedEntries(int feedId) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl${ApiConstants.rssFeedEntries(feedId)}'),
          headers: _headers,
        )
        .timeout(timeout);

    if (response.statusCode == 200) {
      final String decodedBody = utf8.decode(response.bodyBytes);
      return List<Map<String, dynamic>>.from(json.decode(decodedBody));
    }
    throw _handleErrorResponse(response);
  }
}
