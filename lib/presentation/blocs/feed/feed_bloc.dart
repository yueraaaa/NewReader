import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/feed_repository.dart';
import 'feed_event.dart';
import 'feed_state.dart';

class FeedBloc extends Bloc<FeedEvent, FeedState> {
  final FeedRepository _feedRepository;

  FeedBloc({required FeedRepository feedRepository})
      : _feedRepository = feedRepository,
        super(FeedInitial()) {
    on<LoadFeeds>(_onLoadFeeds);
    on<AddFeed>(_onAddFeed);
    on<DeleteFeed>(_onDeleteFeed);
    on<RefreshFeeds>(_onRefreshFeeds);
    on<RefreshFeed>(_onRefreshFeed);
    on<AddCategory>(_onAddCategory);
    on<DeleteCategory>(_onDeleteCategory);
  }

  Future<void> _onLoadFeeds(
    LoadFeeds event,
    Emitter<FeedState> emit,
  ) async {
    emit(FeedLoading());
    try {
      final feeds = await _feedRepository.getFeeds();
      final categories = await _feedRepository.getCategories();
      emit(FeedsLoaded(feeds: feeds, categories: categories));
    } catch (e) {
      emit(FeedError(e.toString()));
    }
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
}
