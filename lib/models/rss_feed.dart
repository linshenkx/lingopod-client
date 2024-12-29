class RssFeed {
  final int id;
  final String url;
  final String title;
  final int initialEntriesCount;
  final int updateEntriesCount;
  final int userId;
  final int? lastFetch;
  final bool isActive;
  final int createdAt;
  final int updatedAt;

  RssFeed({
    required this.id,
    required this.url,
    required this.title,
    required this.initialEntriesCount,
    required this.updateEntriesCount,
    required this.userId,
    this.lastFetch,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RssFeed.fromJson(Map<String, dynamic> json) {
    return RssFeed(
      id: json['id'],
      url: json['url'],
      title: json['title'],
      initialEntriesCount: json['initial_entries_count'],
      updateEntriesCount: json['update_entries_count'],
      userId: json['user_id'],
      lastFetch: json['last_fetch'],
      isActive: json['is_active'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'initial_entries_count': initialEntriesCount,
      'update_entries_count': updateEntriesCount,
      'user_id': userId,
      'last_fetch': lastFetch,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  DateTime get lastFetchDateTime => lastFetch != null
      ? DateTime.fromMillisecondsSinceEpoch(lastFetch!)
      : DateTime.now();

  DateTime get createdAtDateTime =>
      DateTime.fromMillisecondsSinceEpoch(createdAt);

  DateTime get updatedAtDateTime =>
      DateTime.fromMillisecondsSinceEpoch(updatedAt);
}
