import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import '../config/api_constants.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _defaultBaseUrl = 'http://localhost:28811/api';
  static const String _baseUrlKey = 'base_url';
  late SharedPreferences _prefs;
  String _baseUrl = _defaultBaseUrl;
  Function? _onBaseUrlChanged;

  String get baseUrl => _baseUrl;
  String get defaultBaseUrl => _defaultBaseUrl;

  // 初始化方法
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _baseUrl = _prefs.getString(_baseUrlKey) ?? _defaultBaseUrl;
    notifyListeners();
  }

  void setOnBaseUrlChanged(Function callback) {
    _onBaseUrlChanged = callback;
  }

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url;
    await _prefs.setString(_baseUrlKey, url);
    notifyListeners();
    
    // 触发回调
    if (_onBaseUrlChanged != null) {
      _onBaseUrlChanged!();
    }
  }

  // 重置为默认URL
  Future<void> resetToDefault() async {
    await setBaseUrl(_defaultBaseUrl);
  }

  Future<(bool, String)> testConnection(String url) async {
    try {
      final uri = Uri.parse('$url${ApiConstants.getList}');
      final response = await http.get(uri).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('连接超时');
        },
      );
      
      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          if (data is List) {
            return (true, '成功获取播客列表');
          }
          return (false, '服务器返回数据格式不符合预期：应为列表格式');
        } catch (e) {
          return (false, '服务器返回的JSON格式无效');
        }
      } else if (response.statusCode == 404) {
        return (false, 'API路径不存在，请检查服务器地址是否正确');
      } else {
        return (false, '服务器返回错误状态码：${response.statusCode}');
      }
    } on TimeoutException {
      return (false, '连接超时，请检查服务器地址是否正确');
    } on FormatException {
      return (false, 'URL格式无效');
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        return (false, '无法连接到服务器，请检查服务器是否在运行');
      }
      return (false, '连接错误：${e.toString()}');
    }
  }
} 