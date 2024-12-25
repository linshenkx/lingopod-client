import 'style_params.dart';

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
  final bool isPublic;
  final int userId;
  final int createdBy;
  final int? updatedBy;
  final int createdAt;
  final int updatedAt;
  final String progressMessage;
  final StyleParams styleParams;
  final Map<String, Map<String, Map<String, String>>> files;

  String? get audioUrlCn => files['elementary']?['cn']?['audio'];
  String? get audioUrlEn => files['elementary']?['en']?['audio'];
  String? get subtitleUrlCn => files['elementary']?['cn']?['subtitle'];
  String? get subtitleUrlEn => files['elementary']?['en']?['subtitle'];

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
    required this.isPublic,
    required this.userId,
    required this.createdBy,
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
    required this.progressMessage,
    StyleParams? styleParams,
    Map<String, Map<String, Map<String, String>>>? files,
  })  : styleParams = styleParams ?? StyleParams(),
        files = files ?? {};

  factory Podcast.fromJson(Map<String, dynamic> json) {
    // 首先检查必需字段
    final taskId = json['taskId'];
    if (taskId == null) {
      throw Exception('任务ID不能为空');
    }

    // 检查已完成任务的音频和字幕文件
    final status = json['status'] ?? 'pending';
    final files = json['files'] != null
        ? _parseFiles(json['files'])
        : <String, Map<String, Map<String, String>>>{};

    if (status == 'completed') {
      final audioUrlCn = files['elementary']?['cn']?['audio'];
      final audioUrlEn = files['elementary']?['en']?['audio'];
      final subtitleUrlCn = files['elementary']?['cn']?['subtitle'];
      final subtitleUrlEn = files['elementary']?['en']?['subtitle'];

      if (audioUrlCn == null ||
          audioUrlEn == null ||
          subtitleUrlCn == null ||
          subtitleUrlEn == null) {
        throw Exception('已完成的任务缺少必要的音频或字幕文件');
      }
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
      isPublic: json['is_public'] ?? false,
      userId: json['user_id'] ?? 0,
      createdBy: json['created_by'] ?? 0,
      updatedBy: json['updated_by'],
      createdAt: json['created_at'] ?? 0,
      updatedAt: json['updated_at'] ?? 0,
      progressMessage: json['progress_message'] ?? '',
      styleParams: json['style_params'] != null
          ? StyleParams.fromJson(json['style_params'])
          : null,
      files: files,
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
      'is_public': isPublic,
      'user_id': userId,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'progress_message': progressMessage,
      'style_params': styleParams.toJson(),
      'files': files,
    };
  }

  static Map<String, Map<String, Map<String, String>>> _parseFiles(
      Map<String, dynamic> json) {
    final result = <String, Map<String, Map<String, String>>>{};

    json.forEach((level, levelData) {
      if (levelData is Map) {
        result[level] = {};
        (levelData as Map<String, dynamic>).forEach((lang, langData) {
          if (langData is Map) {
            result[level]![lang] = {};
            (langData as Map<String, dynamic>).forEach((type, url) {
              if (url is String) {
                result[level]![lang]![type] = url;
              }
            });
          }
        });
      }
    });

    return result;
  }
}
