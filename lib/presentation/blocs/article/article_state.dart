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
  ArticlesLoaded(this.articles);
  @override
  List<Object?> get props => [articles];
}

class ArticleError extends ArticleState {
  final String message;
  ArticleError(this.message);
  @override
  List<Object?> get props => [message];
}
