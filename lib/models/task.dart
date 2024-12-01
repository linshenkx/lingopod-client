class Task {
  final String id;
  final String url;
  final String status;
  final String progress;
  final String? currentStep;
  final bool isPublic;
  final int createdAt;
  final String? progressMessage;
  final int? currentStepIndex;
  final int? totalSteps;
  final int? stepProgress;
  final String? title;

  Task({
    required this.id,
    required this.url,
    required this.status,
    required this.progress,
    this.currentStep,
    this.isPublic = false,
    required this.createdAt,
    this.progressMessage,
    this.currentStepIndex,
    this.totalSteps,
    this.stepProgress,
    this.title,
  });

  Task copyWith({
    String? id,
    String? url,
    String? status,
    String? progress,
    String? currentStep,
    bool? isPublic,
    int? createdAt,
    String? progressMessage,
    int? currentStepIndex,
    int? totalSteps,
    int? stepProgress,
    String? title,
  }) {
    return Task(
      id: id ?? this.id,
      url: url ?? this.url,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      currentStep: currentStep ?? this.currentStep,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      progressMessage: progressMessage ?? this.progressMessage,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      totalSteps: totalSteps ?? this.totalSteps,
      stepProgress: stepProgress ?? this.stepProgress,
      title: title ?? this.title,
    );
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['taskId'],
      url: json['url'],
      status: json['status'],
      progress: json['progress'].toString(),
      currentStep: json['current_step'],
      isPublic: json['is_public'],
      createdAt: json['createdAt'],
      progressMessage: json['progress_message'],
      currentStepIndex: json['current_step_index'],
      totalSteps: json['total_steps'],
      stepProgress: json['step_progress'],
      title: json['title'],
    );
  }
} 