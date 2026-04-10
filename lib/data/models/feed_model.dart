import 'package:equatable/equatable.dart';

class FeedModel extends Equatable {
  final String id;
  final String title;
  final String url;
  final String? description;
  final String? iconUrl;
  final String? categoryId;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FeedModel({
    required this.id,
    required this.title,
    required this.url,
    this.description,
    this.iconUrl,
    this.categoryId,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FeedModel.fromMap(Map<String, dynamic> map) {
    return FeedModel(
      id: map['id'] as String,
      title: map['title'] as String,
      url: map['url'] as String,
      description: map['description'] as String?,
      iconUrl: map['icon_url'] as String?,
      categoryId: map['category_id'] as String?,
      isDeleted: (map['is_deleted'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'description': description,
      'icon_url': iconUrl,
      'category_id': categoryId,
      'is_deleted': isDeleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  FeedModel copyWith({
    String? id,
    String? title,
    String? url,
    String? description,
    String? iconUrl,
    String? categoryId,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FeedModel(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      categoryId: categoryId ?? this.categoryId,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        url,
        description,
        iconUrl,
        categoryId,
        isDeleted,
        createdAt,
        updatedAt,
      ];
}
