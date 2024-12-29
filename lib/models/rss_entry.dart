class RssEntry {
  final int id;
  final int feedId;
  final String title;
  final String link;
  final int published;
  final String content;
  final bool isRead;
  final int createdAt;
  final int updatedAt;

  RssEntry({
    required this.id,
    required this.feedId,
    required this.title,
    required this.link,
    required this.published,
    required this.content,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RssEntry.fromJson(Map<String, dynamic> json) {
    return RssEntry(
      id: json['id'],
      feedId: json['feed_id'],
      title: json['title'],
      link: json['link'],
      published: json['published'],
      content: json['content'],
      isRead: json['is_read'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'feed_id': feedId,
      'title': title,
      'link': link,
      'published': published,
      'content': content,
      'is_read': isRead,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  DateTime get publishedDateTime =>
      DateTime.fromMillisecondsSinceEpoch(published);

  DateTime get createdAtDateTime =>
      DateTime.fromMillisecondsSinceEpoch(createdAt);

  DateTime get updatedAtDateTime =>
      DateTime.fromMillisecondsSinceEpoch(updatedAt);
}
