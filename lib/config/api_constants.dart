class ApiConstants {
  static const String login = '/api/v1/auth/login';
  static const String register = '/api/v1/auth/register';
  static const String me = '/api/v1/auth/me';
  static const String tasks = '/api/v1/tasks';
  static String task(String taskId) => '/api/v1/tasks/$taskId';
  static String taskRetry(String taskId) => '/api/v1/tasks/$taskId/retry';
  static String taskFile(String taskId, String filename) => 
      '/api/v1/tasks/files/$taskId/$filename';
}
