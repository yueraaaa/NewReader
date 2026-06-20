import 'package:equatable/equatable.dart';
import '../../../data/models/article_model.dart';

abstract class ArticleState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ArticleInitial extends ArticleState {}

class ArticleLoading extends ArticleState {}

class ArticlesLoaded extends ArticleState {
  final List<ArticleModel> articles;
  final int unreadCount;
  ArticlesLoaded(this.articles, {this.unreadCount = 0});
  @override
  List<Object?> get props => [articles, unreadCount];

  ArticlesLoaded copyWith({
    List<ArticleModel>? articles,
    int? unreadCount,
  }) {
    return ArticlesLoaded(
      articles ?? this.articles,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class ArticleError extends ArticleState {
  final String message;
  ArticleError(this.message);
  @override
  List<Object?> get props => [message];
}
