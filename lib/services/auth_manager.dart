import 'package:shared_preferences/shared_preferences.dart';

// 单例模式管理认证信息
class AuthManager {
  static final AuthManager _instance = AuthManager._internal();
  
  factory AuthManager() {
    return _instance;
  }
  
  AuthManager._internal();

  static const String _tokenKey = 'auth_token';
  String? _authToken;
  
  // 初始化方法，从持久化存储加载token
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString(_tokenKey);
  }
  
  // Getter
  String? get token => _authToken;
  
  // Setter
  Future<void> setToken(String? token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString(_tokenKey, token);
    } else {
      await prefs.remove(_tokenKey);
    }
  }
  
  // 清除token
  Future<void> clearToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
  
  // 检查是否已认证
  bool get isAuthenticated => _authToken != null && _authToken!.isNotEmpty;
} 