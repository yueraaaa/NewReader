import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/feed_repository.dart';
import 'feed_event.dart';
import 'feed_state.dart';
import '../auth/auth_bloc.dart';
import '../auth/auth_state.dart';

class FeedBloc extends Bloc<FeedEvent, FeedState> {
  final FeedRepository _feedRepository;
  final AuthBloc _authBloc;
  StreamSubscription<AuthState>? _authSubscription;

  FeedBloc({required FeedRepository feedRepository, required AuthBloc authBloc})
      : _feedRepository = feedRepository,
        _authBloc = authBloc,
        super(FeedInitial()) {
    on<LoadFeeds>(_onLoadFeeds);
    on<AddFeed>(_onAddFeed);
    on<DeleteFeed>(_onDeleteFeed);
    on<RefreshFeeds>(_onRefreshFeeds);
    on<RefreshFeed>(_onRefreshFeed);
    on<AddCategory>(_onAddCategory);
    on<DeleteCategory>(_onDeleteCategory);
    on<UpdateFeed>(_onUpdateFeed);
    on<UpdateCategory>(_onUpdateCategory);
    on<EnsureUncategorized>(_onEnsureUncategorized);

    _authSubscription = _authBloc.stream.listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(AuthState authState) {
    String? userId;
    if (authState is AuthAuthenticated) {
      userId = authState.user.id;
    }
    _feedRepository.setUserId(userId);
    add(LoadFeeds());
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadFeeds(
    LoadFeeds event,
    Emitter<FeedState> emit,
  ) async {
    // Don't emit FeedLoading if we already have data (to avoid UI flash)
    final hasData = state is FeedsLoaded;
    if (!hasData) {
      emit(FeedLoading());
    }
    try {
      // Ensure "uncategorized" category exists
      await _ensureUncategorizedCategory();
      final feeds = await _feedRepository.getFeeds();
      final categories = await _feedRepository.getCategories();
      emit(FeedsLoaded(feeds: feeds, categories: categories));
    } catch (e) {
      emit(FeedError(e.toString()));
    }
  }

  Future<void> _ensureUncategorizedCategory() async {
    try {
      final categories = await _feedRepository.getCategories();
      final hasUncategorized = categories.any((c) => c.name == '未分类');
      if (!hasUncategorized) {
        await _feedRepository.addCategory('未分类', '#808080');
      }
    } catch (_) {}
  }

  Future<void> _onAddFeed(
    AddFeed event,
    Emitter<FeedState> emit,
  ) async {
    try {
      await _feedRepository.addFeed(event.url, categoryId: event.categoryId);
      add(LoadFeeds()); // Refresh
    } catch (e) {
      emit(FeedError(e.toString()));
    }
  }

  Future<void> _onDeleteFeed(
    DeleteFeed event,
    Emitter<FeedState> emit,
  ) async {
    try {
      await _feedRepository.deleteFeed(event.feedId);
      add(LoadFeeds()); // Refresh
    } catch (e) {
      emit(FeedError(e.toString()));
    }
  }

  Future<void> _onRefreshFeeds(
    RefreshFeeds event,
    Emitter<FeedState> emit,
  ) async {
    try {
      await _feedRepository.refreshAllFeeds();
      add(LoadFeeds()); // Refresh
    } catch (e) {
      emit(FeedError(e.toString()));
    }
  }

  Future<void> _onRefreshFeed(
    RefreshFeed event,
    Emitter<FeedState> emit,
  ) async {
    try {
      await _feedRepository.refreshFeed(event.feedId);
      add(LoadFeeds()); // Refresh
    } catch (e) {
      emit(FeedError(e.toString()));
    }
  }

  Future<void> _onAddCategory(
    AddCategory event,
    Emitter<FeedState> emit,
  ) async {
    try {
      await _feedRepository.addCategory(event.name, event.color);
      add(LoadFeeds()); // Refresh
    } catch (e) {
      emit(FeedError(e.toString()));
    }
  }

  Future<void> _onDeleteCategory(
    DeleteCategory event,
    Emitter<FeedState> emit,
  ) async {
    try {
      await _feedRepository.deleteCategory(event.categoryId);
      add(LoadFeeds()); // Refresh
    } catch (e) {
      emit(FeedError(e.toString()));
    }
  }

  Future<void> _onUpdateFeed(
    UpdateFeed event,
    Emitter<FeedState> emit,
  ) async {
    try {
      await _feedRepository.updateFeedFields(event.feedId, title: event.title, categoryId: event.categoryId);
      add(LoadFeeds()); // Refresh
    } catch (e) {
      emit(FeedError(e.toString()));
    }
  }

  Future<void> _onUpdateCategory(
    UpdateCategory event,
    Emitter<FeedState> emit,
  ) async {
    try {
      await _feedRepository.updateCategoryFields(event.categoryId, event.name);
      add(LoadFeeds()); // Refresh
    } catch (e) {
      emit(FeedError(e.toString()));
    }
  }

  Future<void> _onEnsureUncategorized(
    EnsureUncategorized event,
    Emitter<FeedState> emit,
  ) async {
    await _ensureUncategorizedCategory();
    add(LoadFeeds());
  }
}
