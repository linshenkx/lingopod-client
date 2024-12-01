class User {
  final int id;
  final String username;
  final String nickname;
  final bool isActive;
  final bool isAdmin;
  final int createdAt;
  final String? ttsVoice;
  final double? ttsRate;

  User({
    required this.id,
    required this.username,
    required this.nickname,
    required this.isActive,
    required this.isAdmin,
    required this.createdAt,
    this.ttsVoice,
    this.ttsRate,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      nickname: json['nickname'],
      isActive: json['is_active'],
      isAdmin: json['is_admin'],
      createdAt: json['created_at'],
      ttsVoice: json['tts_voice'],
      ttsRate: json['tts_rate']?.toDouble(),
    );
  }
} 