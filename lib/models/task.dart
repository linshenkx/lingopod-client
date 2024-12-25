import 'style_params.dart';

class Task {
  final String id;
  final String url;
  final String status;
  final String progress;
  final String? currentStep;
  final bool isPublic;
  final int createdAt;
  final int updatedAt;
  final String? progressMessage;
  final int? currentStepIndex;
  final int? totalSteps;
  final int? stepProgress;
  final String? title;
  final StyleParams styleParams;
  final Map<String, Map<String, Map<String, String>>> files;
  final int userId;
  final int createdBy;
  final int? updatedBy;
  final String? errorMessage;

  Task({
    required this.id,
    required this.url,
    required this.status,
    required this.progress,
    this.currentStep,
    this.isPublic = false,
    required this.createdAt,
    required this.updatedAt,
    this.progressMessage,
    this.currentStepIndex,
    this.totalSteps,
    this.stepProgress,
    this.title,
    StyleParams? styleParams,
    Map<String, Map<String, Map<String, String>>>? files,
    required this.userId,
    required this.createdBy,
    this.updatedBy,
    this.errorMessage,
  })  : styleParams = styleParams ?? StyleParams(),
        files = files ?? {};

  Task copyWith({
    String? id,
    String? url,
    String? status,
    String? progress,
    String? currentStep,
    bool? isPublic,
    int? createdAt,
    int? updatedAt,
    String? progressMessage,
    int? currentStepIndex,
    int? totalSteps,
    int? stepProgress,
    String? title,
    StyleParams? styleParams,
    Map<String, Map<String, Map<String, String>>>? files,
    int? userId,
    int? createdBy,
    int? updatedBy,
    String? errorMessage,
  }) {
    return Task(
      id: id ?? this.id,
      url: url ?? this.url,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      currentStep: currentStep ?? this.currentStep,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      progressMessage: progressMessage ?? this.progressMessage,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      totalSteps: totalSteps ?? this.totalSteps,
      stepProgress: stepProgress ?? this.stepProgress,
      title: title ?? this.title,
      styleParams: styleParams ?? this.styleParams,
      files: files ?? this.files,
      userId: userId ?? this.userId,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['taskId'],
      url: json['url'],
      status: json['status'],
      progress: json['progress'].toString(),
      currentStep: json['current_step'],
      isPublic: json['is_public'] ?? false,
      createdAt: json['created_at'] ?? 0,
      updatedAt: json['updated_at'] ?? 0,
      progressMessage: json['progress_message'],
      currentStepIndex: json['current_step_index'],
      totalSteps: json['total_steps'],
      stepProgress: json['step_progress'],
      title: json['title'],
      styleParams: json['style_params'] != null
          ? StyleParams.fromJson(json['style_params'])
          : null,
      files: json['files'] != null ? _parseFiles(json['files']) : null,
      userId: json['user_id'] ?? 0,
      createdBy: json['created_by'] ?? 0,
      updatedBy: json['updated_by'],
      errorMessage: json['status'] == 'failed'
          ? (json['progress_message'] ?? json['error'] ?? '未知错误')
          : null,
    );
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

  String? getFileUrl(String level, String lang, String type) {
    return files[level]?[lang]?[type];
  }
}
