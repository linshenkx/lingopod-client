class Podcast {
  final String taskId;
  final String id;
  final String title;
  final String url;
  final DateTime createdAt;
  final String? audioUrlCn;
  final String? audioUrlEn;
  final String? subtitleUrlCn;
  final String? subtitleUrlEn;
  final String? status;

  Podcast({
    required this.taskId,
    required this.id,
    required this.title,
    required this.url,
    required this.createdAt,
    this.audioUrlCn,
    this.audioUrlEn,
    this.subtitleUrlCn,
    this.subtitleUrlEn,
    this.status,
  });

  factory Podcast.fromJson(Map<String, dynamic> json) {
    return Podcast(
      taskId: json['taskId'] ?? '',
      id: json['taskId'] ?? '',
      title: json['title'] ?? '',
      url: json['url'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      audioUrlCn: json['audio_url_cn'],
      audioUrlEn: json['audio_url_en'],
      subtitleUrlCn: json['subtitle_url_cn'],
      subtitleUrlEn: json['subtitle_url_en'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'id': id,
      'title': title,
      'url': url,
      'audioUrlCn': audioUrlCn,
      'audioUrlEn': audioUrlEn,
      'subtitleUrlCn': subtitleUrlCn,
      'subtitleUrlEn': subtitleUrlEn,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }
} 