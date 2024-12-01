class Podcast {
  final String taskId;
  final String url;
  final String status;
  final String progress;
  final String title;
  final String currentStep;
  final int currentStepIndex;
  final int totalSteps;
  final int stepProgress;
  final String audioUrlCn;
  final String audioUrlEn;
  final String subtitleUrlCn;
  final String subtitleUrlEn;
  final bool isPublic;
  final int userId;
  final int createdBy;
  final int? updatedBy;
  final int createdAt;
  final int updatedAt;
  final String progressMessage;

  Podcast({
    required this.taskId,
    required this.url,
    required this.status,
    required this.progress,
    required this.title,
    required this.currentStep,
    required this.currentStepIndex,
    required this.totalSteps,
    required this.stepProgress,
    required this.audioUrlCn,
    required this.audioUrlEn,
    required this.subtitleUrlCn,
    required this.subtitleUrlEn,
    required this.isPublic,
    required this.userId,
    required this.createdBy,
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
    required this.progressMessage,
  });

  factory Podcast.fromJson(Map<String, dynamic> json) {
    return Podcast(
      taskId: json['taskId'] as String,
      url: json['url'] as String,
      status: json['status'] as String,
      progress: json['progress'] as String,
      title: json['title'] as String,
      currentStep: json['current_step'] as String,
      currentStepIndex: json['current_step_index'] as int,
      totalSteps: json['total_steps'] as int,
      stepProgress: json['step_progress'] as int,
      audioUrlCn: json['audio_url_cn'] ?? '',
      audioUrlEn: json['audio_url_en'] ?? '',
      subtitleUrlCn: json['subtitle_url_cn'] ?? '',
      subtitleUrlEn: json['subtitle_url_en'] ?? '',
      isPublic: json['is_public'] as bool,
      userId: json['user_id'] as int,
      createdBy: json['created_by'] as int,
      updatedBy: json['updated_by'] as int?,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int,
      progressMessage: json['progress_message'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'url': url,
      'status': status,
      'progress': progress,
      'title': title,
      'currentStep': currentStep,
      'currentStepIndex': currentStepIndex,
      'totalSteps': totalSteps,
      'stepProgress': stepProgress,
      'audioUrlCn': audioUrlCn,
      'audioUrlEn': audioUrlEn,
      'subtitleUrlCn': subtitleUrlCn,
      'subtitleUrlEn': subtitleUrlEn,
      'isPublic': isPublic,
      'userId': userId,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'progressMessage': progressMessage,
    };
  }
} 