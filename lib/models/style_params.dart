class StyleParams {
  final String contentLength;
  final String tone;
  final String emotion;

  StyleParams({
    this.contentLength = 'medium',
    this.tone = 'casual',
    this.emotion = 'neutral',
  });

  factory StyleParams.fromJson(Map<String, dynamic> json) {
    return StyleParams(
      contentLength: json['content_length'] ?? 'medium',
      tone: json['tone'] ?? 'casual',
      emotion: json['emotion'] ?? 'neutral',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content_length': contentLength,
      'tone': tone,
      'emotion': emotion,
    };
  }

  StyleParams copyWith({
    String? contentLength,
    String? tone,
    String? emotion,
  }) {
    return StyleParams(
      contentLength: contentLength ?? this.contentLength,
      tone: tone ?? this.tone,
      emotion: emotion ?? this.emotion,
    );
  }
}
