import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/local/article_local_datasource.dart';
import 'article_event.dart';
import 'article_state.dart';

class ArticleBloc extends Bloc<ArticleEvent, ArticleState> {
  final ArticleLocalDatasource _articleDatasource;

  ArticleBloc({ArticleLocalDatasource? articleDatasource})
      : _articleDatasource = articleDatasource ?? ArticleLocalDatasource(),
        super(ArticleInitial()) {
    on<LoadArticles>(_onLoadArticles);
    on<LoadAllArticles>(_onLoadAllArticles);
    on<LoadFavoriteArticles>(_onLoadFavoriteArticles);
    on<MarkArticleRead>(_onMarkArticleRead);
    on<MarkArticleFavorite>(_onMarkArticleFavorite);
    on<UpdateReadProgress>(_onUpdateReadProgress);
    on<SearchArticles>(_onSearchArticles);
  }

  Future<void> _onLoadArticles(
    LoadArticles event,
    Emitter<ArticleState> emit,
  ) async {
    emit(ArticleLoading());
    try {
      final articles = event.feedId != null
          ? await _articleDatasource.getArticlesByFeed(event.feedId!)
          : event.categoryId != null
              ? await _articleDatasource.getArticlesByCategory(event.categoryId!)
              : await _articleDatasource.getAllArticles();
      emit(ArticlesLoaded(articles));
    } catch (e) {
      emit(ArticleError(e.toString()));
    }
  }

  Future<void> _onLoadAllArticles(
    LoadAllArticles event,
    Emitter<ArticleState> emit,
  ) async {
    emit(ArticleLoading());
    try {
      final articles = await _articleDatasource.getAllArticles();
      emit(ArticlesLoaded(articles));
    } catch (e) {
      emit(ArticleError(e.toString()));
    }
  }

  Future<void> _onLoadFavoriteArticles(
    LoadFavoriteArticles event,
    Emitter<ArticleState> emit,
  ) async {
    emit(ArticleLoading());
    try {
      final articles = await _articleDatasource.getFavoriteArticles();
      emit(ArticlesLoaded(articles));
    } catch (e) {
      emit(ArticleError(e.toString()));
    }
  }

  Future<void> _onMarkArticleRead(
    MarkArticleRead event,
    Emitter<ArticleState> emit,
  ) async {
    try {
      await _articleDatasource.markRead(event.articleId, event.isRead);
      // Refresh current list
      if (state is ArticlesLoaded) {
        final currentArticles = (state as ArticlesLoaded).articles;
        final updatedArticles = currentArticles.map((a) {
          if (a.id == event.articleId) {
            return a.copyWith(isRead: event.isRead);
          }
          return a;
        }).toList();
        emit(ArticlesLoaded(updatedArticles));
      }
    } catch (e) {
      emit(ArticleError(e.toString()));
    }
  }

  Future<void> _onMarkArticleFavorite(
    MarkArticleFavorite event,
    Emitter<ArticleState> emit,
  ) async {
    try {
      await _articleDatasource.markFavorite(event.articleId, event.isFavorite);
      // Refresh current list
      if (state is ArticlesLoaded) {
        final currentArticles = (state as ArticlesLoaded).articles;
        final updatedArticles = currentArticles.map((a) {
          if (a.id == event.articleId) {
            return a.copyWith(isFavorite: event.isFavorite);
          }
          return a;
        }).toList();
        emit(ArticlesLoaded(updatedArticles));
      }
    } catch (e) {
      emit(ArticleError(e.toString()));
    }
  }

  Future<void> _onUpdateReadProgress(
    UpdateReadProgress event,
    Emitter<ArticleState> emit,
  ) async {
    try {
      await _articleDatasource.updateReadProgress(event.articleId, event.progress);
      // Refresh current list
      if (state is ArticlesLoaded) {
        final currentArticles = (state as ArticlesLoaded).articles;
        final updatedArticles = currentArticles.map((a) {
          if (a.id == event.articleId) {
            return a.copyWith(readProgress: event.progress);
          }
          return a;
        }).toList();
        emit(ArticlesLoaded(updatedArticles));
      }
    } catch (e) {
      emit(ArticleError(e.toString()));
    }
  }

  Future<void> _onSearchArticles(
    SearchArticles event,
    Emitter<ArticleState> emit,
  ) async {
    emit(ArticleLoading());
    try {
      final articles = await _articleDatasource.searchArticles(event.query);
      emit(ArticlesLoaded(articles));
    } catch (e) {
      emit(ArticleError(e.toString()));
    }
  }
}
