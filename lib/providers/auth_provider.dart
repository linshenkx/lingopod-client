import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../services/auth_manager.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../main.dart';  // 导入 main.dart 以使用 navigatorKey

class AuthProvider with ChangeNotifier {
  final ApiService _apiService;
  User? _currentUser;
  String? _token;
  bool _isLoading = false;
  static const String _tokenKey = 'auth_token';
  static const String _rememberLoginKey = 'remember_login';
  bool _rememberLogin = false;
  
  // 添加一个 BuildContext 字段
  BuildContext? _context;

  AuthProvider(this._apiService);

  // 添加设置 context 的方法
  void setContext(BuildContext context) {
    _context = context;
  }

  // 获取 AudioProvider 的辅助方法
  void _resetAudioProvider() {
    if (_context != null) {
      Provider.of<AudioProvider>(_context!, listen: false).reset();
    } else if (navigatorKey.currentContext != null) {
      Provider.of<AudioProvider>(navigatorKey.currentContext!, listen: false).reset();
    }
  }

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_tokenKey);
      
      if (_token != null) {
        AuthManager().setToken(_token);
        _currentUser = await _apiService.getCurrentUser();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('初始化认证状态失败: $e');
      // 如果获取用户信息失败，清除token
      await logout();
    }
  }

  Future<void> login(String username, String password, {bool rememberLogin = false}) async {
    try {
      _isLoading = true;
      notifyListeners();

      final authResult = await _apiService.login(username, password);
      _token = authResult['access_token'];
      _rememberLogin = rememberLogin;
      
      final prefs = await SharedPreferences.getInstance();
      if (_rememberLogin) {
        // 如果选择记住登录，保存token
        await prefs.setString(_tokenKey, _token!);
        await prefs.setBool(_rememberLoginKey, true);
      } else {
        // 如果不记住登录，清除保存的信息
        await prefs.remove(_tokenKey);
        await prefs.remove(_rememberLoginKey);
      }
      
      AuthManager().setToken(_token);
      _currentUser = await _apiService.getCurrentUser();
            // 重置音频播放器状态
      _resetAudioProvider();
      
      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String username, String password, {String? nickname}) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _apiService.register(username, password, nickname: nickname);
      await login(username, password);
      
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkSavedLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(_tokenKey);
      final rememberLogin = prefs.getBool(_rememberLoginKey) ?? false;

      if (savedToken != null && rememberLogin) {
        _token = savedToken;
        AuthManager().setToken(_token);
        _currentUser = await _apiService.getCurrentUser();
        _rememberLogin = true;
        notifyListeners();
      }
    } catch (e) {
      // 如果获取用户信息失败，清除保存的登录信息
      logout();
    }
  }

  Future<void> logout() async {
    // 重置音频播放器状态
    _resetAudioProvider();
    
    _token = null;
    _currentUser = null;
    _rememberLogin = false;
    AuthManager().setToken(null);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_rememberLoginKey);
    
    notifyListeners();
  }
}
