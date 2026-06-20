import 'package:equatable/equatable.dart';

abstract class ArticleEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadArticles extends ArticleEvent {
  final String? feedId;
  final String? categoryId;
  LoadArticles({this.feedId, this.categoryId});
  @override
  List<Object?> get props => [feedId, categoryId];
}

class LoadAllArticles extends ArticleEvent {}

class LoadFavoriteArticles extends ArticleEvent {}

class MarkArticleRead extends ArticleEvent {
  final String articleId;
  final bool isRead;
  MarkArticleRead(this.articleId, this.isRead);
  @override
  List<Object?> get props => [articleId, isRead];
}

class MarkArticleFavorite extends ArticleEvent {
  final String articleId;
  final bool isFavorite;
  MarkArticleFavorite(this.articleId, this.isFavorite);
  @override
  List<Object?> get props => [articleId, isFavorite];
}

class UpdateReadProgress extends ArticleEvent {
  final String articleId;
  final double progress;
  UpdateReadProgress(this.articleId, this.progress);
  @override
  List<Object?> get props => [articleId, progress];
}

class SearchArticles extends ArticleEvent {
  final String query;
  SearchArticles(this.query);
  @override
  List<Object?> get props => [query];
}

class LoadUnreadCount extends ArticleEvent {
  final String? feedId;
  LoadUnreadCount({this.feedId});
  @override
  List<Object?> get props => [feedId];
}

class LoadArticleById extends ArticleEvent {
  final String articleId;
  LoadArticleById(this.articleId);
  @override
  List<Object?> get props => [articleId];
}

class DeleteArticlesByFeedId extends ArticleEvent {
  final String feedId;
  DeleteArticlesByFeedId(this.feedId);
  @override
  List<Object?> get props => [feedId];
}
