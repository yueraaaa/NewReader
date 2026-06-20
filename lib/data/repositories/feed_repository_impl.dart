import 'package:uuid/uuid.dart';
import '../../domain/repositories/feed_repository.dart';
import '../datasources/local/feed_local_datasource.dart';
import '../datasources/remote/rss_remote_datasource.dart';
import '../datasources/remote/supabase_datasource.dart';
import '../models/feed_model.dart';
import '../models/category_model.dart';
import '../services/sync_service.dart';

class FeedRepositoryImpl implements FeedRepository {
  final FeedLocalDatasource _localDatasource;
  final RssRemoteDatasource _rssRemoteDatasource;
  final SupabaseDatasource? _supabaseDatasource;
  final SyncService? _syncService;
  final Uuid _uuid;

  FeedRepositoryImpl({
    FeedLocalDatasource? localDatasource,
    RssRemoteDatasource? rssRemoteDatasource,
    SupabaseDatasource? supabaseDatasource,
    SyncService? syncService,
    Uuid? uuid,
  })  : _localDatasource = localDatasource ?? FeedLocalDatasource(),
        _rssRemoteDatasource = rssRemoteDatasource ?? RssRemoteDatasource(),
        _supabaseDatasource = supabaseDatasource,
        _syncService = syncService,
        _uuid = uuid ?? const Uuid();

  bool get _isLoggedIn =>
      _supabaseDatasource != null && _syncService != null;

  @override
  void setUserId(String? userId) {
    _localDatasource.setUserId(userId);
  }

  Future<void> _syncToCloud() async {
    if (!_isLoggedIn) return;
    try {
      final userId = _supabaseDatasource?.getCurrentUserId();
      _syncService!.setUserId(userId);
      await _syncService!.syncAll();
    } catch (e) {
      // Silently fail - local operations should not be blocked by sync failures
      // TODO: Use proper logging (e.g., dart:developer) in production
    }
  }

  @override
  Future<List<FeedModel>> getFeeds() async {
    return _localDatasource.getAllFeeds();
  }

  @override
  Future<List<FeedModel>> getFeedsByCategory(String categoryId) async {
    return _localDatasource.getFeedsByCategory(categoryId);
  }

  @override
  Future<FeedModel?> getFeedById(String id) async {
    return _localDatasource.getFeedById(id);
  }

  @override
  Future<void> addFeed(String url, {String? categoryId}) async {
    final now = DateTime.now();
    final feedId = _uuid.v4();
    final userId = _supabaseDatasource?.getCurrentUserId() ?? '';

    // First insert a placeholder feed
    final placeholderFeed = FeedModel(
      id: feedId,
      title: 'Loading...',
      url: url,
      description: null,
      iconUrl: null,
      categoryId: categoryId,
      userId: userId,
      isDeleted: false,
      createdAt: now,
      updatedAt: now,
    );
    await _localDatasource.insertFeed(placeholderFeed);

    // Fetch articles and feed info from remote
    try {
      final articles = await _rssRemoteDatasource.fetchAndParseArticles(url, feedId);
      final feedInfo = await _rssRemoteDatasource.fetchRssFeed(url);

      // Use RSS feed title as the feed title
      String feedTitle = feedInfo.title ?? 'Untitled Feed';
      if (feedTitle.isEmpty) {
        feedTitle = 'Untitled Feed';
      }

      // Save articles with userId (skip existing to preserve read state)
      for (final article in articles) {
        final existing = await _localDatasource.getFeedById(article.id);
        if (existing == null) {
          await _localDatasource.insertArticle(article.copyWith(userId: userId));
        }
      }

      // Update feed with actual title from RSS feed
      await _localDatasource.updateFeed(
        placeholderFeed.copyWith(
          title: feedTitle,
          description: feedInfo.description,
          iconUrl: feedInfo.image?.url,
          updatedAt: DateTime.now(),
        ),
      );
    } catch (e) {
      // Update placeholder to show error state
      await _localDatasource.updateFeed(
        placeholderFeed.copyWith(
          title: 'Failed to load',
          updatedAt: DateTime.now(),
        ),
      );
      rethrow;
    }

    // Sync to cloud
    await _syncToCloud();
  }

  @override
  Future<void> updateFeed(FeedModel feed) async {
    await _localDatasource.updateFeed(feed);
    await _syncToCloud();
  }

  @override
  Future<void> deleteFeed(String id) async {
    // Soft delete the feed
    await _localDatasource.deleteFeed(id);
    // Soft delete all articles in the feed
    await _localDatasource.softDeleteArticlesByFeedId(id);
    await _syncToCloud();
  }

  @override
  Future<void> refreshFeed(String id) async {
    final feed = await _localDatasource.getFeedById(id);
    if (feed == null) return;

    // Fetch articles from remote
    final articles = await _rssRemoteDatasource.fetchAndParseArticles(feed.url, id);

    // Load existing articles once and use Set for O(1) lookup
    final existingArticles = await _localDatasource.getArticlesByFeedId(id);
    final existingMap = {for (var a in existingArticles) a.id: a};

    // Upsert articles, preserving existing read state and userId
    for (final article in articles) {
      final existing = existingMap[article.id];
      if (existing != null) {
        // Preserve reading state and userId
        await _localDatasource.insertArticle(
          article.copyWith(
            isRead: existing.isRead,
            isFavorite: existing.isFavorite,
            readProgress: existing.readProgress,
            userId: existing.userId,
          ),
        );
      } else {
        await _localDatasource.insertArticle(article.copyWith(userId: feed.userId));
      }
    }

    // Update feed's updatedAt
    await _localDatasource.updateFeed(
      feed.copyWith(updatedAt: DateTime.now()),
    );
  }

  @override
  Future<void> refreshAllFeeds() async {
    final feeds = await _localDatasource.getAllFeeds();
    await Future.wait(feeds.map((f) => refreshFeed(f.id)));
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    return _localDatasource.getAllCategories();
  }

  @override
  Future<void> addCategory(String name, String color) async {
    final now = DateTime.now();
    final userId = _supabaseDatasource?.getCurrentUserId() ?? '';
    final category = CategoryModel(
      id: _uuid.v4(),
      name: name,
      color: color,
      sortOrder: 0,
      userId: userId,
      isDeleted: false,
      createdAt: now,
      updatedAt: now,
    );
    await _localDatasource.insertCategory(category);
    await _syncToCloud();
  }

  @override
  Future<void> updateCategory(CategoryModel category) async {
    await _localDatasource.updateCategory(category);
    await _syncToCloud();
  }

  @override
  Future<void> updateFeedFields(String feedId, {String? title, String? categoryId}) async {
    final feed = await _localDatasource.getFeedById(feedId);
    if (feed == null) return;
    final updated = feed.copyWith(
      title: title ?? feed.title,
      categoryId: categoryId,
      updatedAt: DateTime.now(),
    );
    await _localDatasource.updateFeed(updated);
    await _syncToCloud();
  }

  @override
  Future<void> updateCategoryFields(String categoryId, String name) async {
    final categories = await _localDatasource.getAllCategories();
    final category = categories.where((c) => c.id == categoryId).firstOrNull;
    if (category == null) return;
    final updated = category.copyWith(name: name, updatedAt: DateTime.now());
    await _localDatasource.updateCategory(updated);
    await _syncToCloud();
  }

  @override
  Future<void> deleteCategory(String id) async {
    // Move feeds in this category to uncategorized
    final uncategorizedCategories = await _localDatasource.getAllCategories();
    final uncategorized = uncategorizedCategories.where((c) => c.name == '未分类').firstOrNull;
    if (uncategorized != null) {
      final feedsInCategory = await _localDatasource.getFeedsByCategory(id);
      for (final feed in feedsInCategory) {
        await _localDatasource.updateFeed(
          feed.copyWith(categoryId: uncategorized.id, updatedAt: DateTime.now()),
        );
      }
    }
    await _localDatasource.deleteCategory(id);
    await _syncToCloud();
  }

  /// Pull remote data from cloud and merge with local
  Future<void> pullFromCloud() async {
    if (!_isLoggedIn) return;
    try {
      final userId = _supabaseDatasource?.getCurrentUserId();
      _syncService!.setUserId(userId);
      await _syncService!.syncAll();
    } catch (e) {
      // Silently fail - local operations should not be blocked by sync failures
      // TODO: Use proper logging (e.g., dart:developer) in production
    }
  }
}
