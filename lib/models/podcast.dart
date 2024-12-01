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
    // 首先检查必需字段
    final taskId = json['taskId'];
    if (taskId == null) {
      throw Exception('任务ID不能为空');
    }

    // 检查已完成任务的音频和字幕文件
    final status = json['status'] ?? 'pending';
    final audioUrlCn = json['audioUrlCn'];
    final audioUrlEn = json['audioUrlEn'];
    final subtitleUrlCn = json['subtitleUrlCn'];
    final subtitleUrlEn = json['subtitleUrlEn'];
    
    if (status == 'completed' && 
        (audioUrlCn == null || audioUrlEn == null || 
         subtitleUrlCn == null || subtitleUrlEn == null)) {
      throw Exception('已完成的任务缺少必要的音频或字幕文件');
    }

    return Podcast(
      taskId: taskId.toString(),
      url: json['url'] ?? '',
      status: status,
      progress: json['progress'] ?? 'waiting',
      title: json['title'] ?? '',
      currentStep: json['current_step'] ?? '',
      currentStepIndex: json['current_step_index'] ?? 0,
      totalSteps: json['total_steps'] ?? 0,
      stepProgress: json['step_progress'] ?? 0,
      audioUrlCn: audioUrlCn ?? '',
      audioUrlEn: audioUrlEn ?? '',
      subtitleUrlCn: subtitleUrlCn ?? '',
      subtitleUrlEn: subtitleUrlEn ?? '',
      isPublic: json['is_public'] ?? false,
      userId: json['user_id'] ?? 0,
      createdBy: json['created_by'] ?? 0,
      updatedBy: json['updated_by'],
      createdAt: json['createdAt'] ?? 0,
      updatedAt: json['updatedAt'] ?? 0,
      progressMessage: json['progress_message'] ?? '',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'url': url,
      'status': status,
      'progress': progress,
      'title': title,
      'current_step': currentStep,
      'current_step_index': currentStepIndex,
      'total_steps': totalSteps,
      'step_progress': stepProgress,
      'audio_url_cn': audioUrlCn,
      'audio_url_en': audioUrlEn,
      'subtitle_url_cn': subtitleUrlCn,
      'subtitle_url_en': subtitleUrlEn,
      'is_public': isPublic,
      'user_id': userId,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'progress_message': progressMessage,
    };
  }
} 