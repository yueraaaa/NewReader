import 'package:equatable/equatable.dart';
import '../../../data/models/article_model.dart';

abstract class AiEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class TranslateArticle extends AiEvent {
  final ArticleModel article;
  TranslateArticle(this.article);
  @override
  List<Object?> get props => [article];
}

class SummarizeArticle extends AiEvent {
  final ArticleModel article;
  SummarizeArticle(this.article);
  @override
  List<Object?> get props => [article];
}

class ReadArticleAloud extends AiEvent {
  final ArticleModel article;
  ReadArticleAloud(this.article);
  @override
  List<Object?> get props => [article];
}

class StopReadAloud extends AiEvent {}

class ClearAiResults extends AiEvent {}
