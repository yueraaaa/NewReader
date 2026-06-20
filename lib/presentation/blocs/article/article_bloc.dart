import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/local/article_local_datasource.dart';
import '../../../data/datasources/remote/supabase_datasource.dart';
import '../../../data/models/article_model.dart';
import '../auth/auth_bloc.dart';
import '../auth/auth_state.dart';
import 'article_event.dart';
import 'article_state.dart';

class ArticleBloc extends Bloc<ArticleEvent, ArticleState> {
  final ArticleLocalDatasource _articleDatasource;
  final SupabaseDatasource? _supabaseDatasource;
  StreamSubscription<AuthState>? _authSubscription;

  ArticleBloc({
    ArticleLocalDatasource? articleDatasource,
    SupabaseDatasource? supabaseDatasource,
    AuthBloc? authBloc,
  })  : _articleDatasource = articleDatasource ?? ArticleLocalDatasource(),
        _supabaseDatasource = supabaseDatasource,
        super(ArticleInitial()) {
    on<LoadArticles>(_onLoadArticles);
    on<LoadAllArticles>(_onLoadAllArticles);
    on<LoadFavoriteArticles>(_onLoadFavoriteArticles);
    on<MarkArticleRead>(_onMarkArticleRead);
    on<MarkArticleFavorite>(_onMarkArticleFavorite);
    on<UpdateReadProgress>(_onUpdateReadProgress);
    on<SearchArticles>(_onSearchArticles);
    on<LoadUnreadCount>(_onLoadUnreadCount);
    on<LoadArticleById>(_onLoadArticleById);
    on<DeleteArticlesByFeedId>(_onDeleteArticlesByFeedId);

    if (authBloc != null) {
      _authSubscription = authBloc.stream.listen(_onAuthStateChanged);
    }
  }

  void _onAuthStateChanged(AuthState authState) {
    String? userId;
    if (authState is AuthAuthenticated) {
      userId = authState.user.id;
    }
    _articleDatasource.setUserId(userId);
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  bool get _isLoggedIn => _supabaseDatasource != null;

  Future<void> _syncArticleToCloud(ArticleModel article) async {
    if (!_isLoggedIn) return;
    try {
      await _supabaseDatasource!.upsertArticle(article.toMap());
    } catch (e) {
      // Silently fail - local operations should not be blocked by sync failures
    }
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
        ArticleModel? updatedArticle;
        final updatedArticles = currentArticles.map((a) {
          if (a.id == event.articleId) {
            updatedArticle = a.copyWith(isRead: event.isRead);
            return updatedArticle!;
          }
          return a;
        }).toList();
        emit(ArticlesLoaded(updatedArticles));
        // Sync to cloud
        if (updatedArticle != null) {
          _syncArticleToCloud(updatedArticle!);
        }
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
        ArticleModel? updatedArticle;
        final updatedArticles = currentArticles.map((a) {
          if (a.id == event.articleId) {
            updatedArticle = a.copyWith(isFavorite: event.isFavorite);
            return updatedArticle!;
          }
          return a;
        }).toList();
        emit(ArticlesLoaded(updatedArticles));
        // Sync to cloud
        if (updatedArticle != null) {
          _syncArticleToCloud(updatedArticle!);
        }
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
        ArticleModel? updatedArticle;
        final updatedArticles = currentArticles.map((a) {
          if (a.id == event.articleId) {
            updatedArticle = a.copyWith(readProgress: event.progress);
            return updatedArticle!;
          }
          return a;
        }).toList();
        emit(ArticlesLoaded(updatedArticles));
        // Sync to cloud
        if (updatedArticle != null) {
          _syncArticleToCloud(updatedArticle!);
        }
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

  Future<void> _onLoadUnreadCount(
    LoadUnreadCount event,
    Emitter<ArticleState> emit,
  ) async {
    try {
      final count = event.feedId != null
          ? await _articleDatasource.getUnreadCountByFeed(event.feedId!)
          : await _articleDatasource.getTotalUnreadCount();

      if (state is ArticlesLoaded) {
        emit((state as ArticlesLoaded).copyWith(unreadCount: count));
      } else {
        emit(ArticlesLoaded(const [], unreadCount: count));
      }
    } catch (e) {
      // Silently fail for unread count
    }
  }

  Future<void> _onLoadArticleById(
    LoadArticleById event,
    Emitter<ArticleState> emit,
  ) async {
    try {
      final article = await _articleDatasource.getArticleById(event.articleId);
      if (article != null) {
        // If we have existing articles, add this one; otherwise create new list
        if (state is ArticlesLoaded) {
          final currentArticles = (state as ArticlesLoaded).articles;
          // Check if article already exists
          final exists = currentArticles.any((a) => a.id == article.id);
          if (exists) {
            emit(ArticlesLoaded(currentArticles));
          } else {
            emit(ArticlesLoaded([article, ...currentArticles]));
          }
        } else {
          emit(ArticlesLoaded([article]));
        }
      }
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _onDeleteArticlesByFeedId(
    DeleteArticlesByFeedId event,
    Emitter<ArticleState> emit,
  ) async {
    try {
      await _articleDatasource.deleteArticlesByFeed(event.feedId);
      // Refresh current list by removing articles from this feed
      if (state is ArticlesLoaded) {
        final updatedArticles = (state as ArticlesLoaded).articles
            .where((a) => a.feedId != event.feedId)
            .toList();
        emit(ArticlesLoaded(updatedArticles));
      }
    } catch (e) {
      // Silently fail
    }
  }
}
