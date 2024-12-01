// 单例模式管理认证信息
class AuthManager {
  static final AuthManager _instance = AuthManager._internal();
  
  factory AuthManager() {
    return _instance;
  }
  
  AuthManager._internal();

  String? _authToken;
  
  // Getter
  String? get token => _authToken;
  
  // Setter
  void setToken(String? token) {
    _authToken = token;
  }
  
  // 清除token
  void clearToken() {
    _authToken = null;
  }
  
  // 检查是否已认证
  bool get isAuthenticated => _authToken != null && _authToken!.isNotEmpty;
} 