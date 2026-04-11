import 'package:equatable/equatable.dart';

class ArticleModel extends Equatable {
  final String id;
  final String feedId;
  final String title;
  final String link;
  final String? description;
  final String? content;
  final String? author;
  final String? imageUrl;
  final DateTime? publishedAt;
  final bool isRead;
  final bool isFavorite;
  final double readProgress;
  final String userId;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ArticleModel({
    required this.id,
    required this.feedId,
    required this.title,
    required this.link,
    this.description,
    this.content,
    this.author,
    this.imageUrl,
    this.publishedAt,
    this.isRead = false,
    this.isFavorite = false,
    this.readProgress = 0.0,
    this.userId = '',
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  int get readingTimeMinutes {
    final text = '${description ?? ''} ${content ?? ''}';
    final words =
        text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    return (words / 200).ceil().clamp(1, 999);
  }

  factory ArticleModel.fromMap(Map<String, dynamic> map) {
    return ArticleModel(
      id: map['id'] as String,
      feedId: map['feed_id'] as String,
      title: map['title'] as String,
      link: map['link'] as String,
      description: map['description'] as String?,
      content: map['content'] as String?,
      author: map['author'] as String?,
      imageUrl: map['image_url'] as String?,
      publishedAt: map['published_at'] != null
          ? DateTime.parse(map['published_at'] as String)
          : null,
      isRead: (map['is_read'] as int?) == 1,
      isFavorite: (map['is_favorite'] as int?) == 1,
      readProgress: (map['read_progress'] as num?)?.toDouble() ?? 0.0,
      userId: map['user_id'] as String? ?? '',
      isDeleted: (map['is_deleted'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'feed_id': feedId,
      'title': title,
      'link': link,
      'description': description,
      'content': content,
      'author': author,
      'image_url': imageUrl,
      'published_at': publishedAt?.toIso8601String(),
      'is_read': isRead ? 1 : 0,
      'is_favorite': isFavorite ? 1 : 0,
      'read_progress': readProgress,
      'user_id': userId,
      'is_deleted': isDeleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ArticleModel copyWith({
    String? id,
    String? feedId,
    String? title,
    String? link,
    String? description,
    String? content,
    String? author,
    String? imageUrl,
    DateTime? publishedAt,
    bool? isRead,
    bool? isFavorite,
    double? readProgress,
    String? userId,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ArticleModel(
      id: id ?? this.id,
      feedId: feedId ?? this.feedId,
      title: title ?? this.title,
      link: link ?? this.link,
      description: description ?? this.description,
      content: content ?? this.content,
      author: author ?? this.author,
      imageUrl: imageUrl ?? this.imageUrl,
      publishedAt: publishedAt ?? this.publishedAt,
      isRead: isRead ?? this.isRead,
      isFavorite: isFavorite ?? this.isFavorite,
      readProgress: readProgress ?? this.readProgress,
      userId: userId ?? this.userId,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        feedId,
        title,
        link,
        description,
        content,
        author,
        imageUrl,
        publishedAt,
        isRead,
        isFavorite,
        readProgress,
        userId,
        isDeleted,
        createdAt,
        updatedAt,
      ];
}
