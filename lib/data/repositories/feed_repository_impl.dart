import 'package:uuid/uuid.dart';
import '../../domain/repositories/feed_repository.dart';
import '../datasources/local/feed_local_datasource.dart';
import '../datasources/remote/rss_remote_datasource.dart';
import '../models/feed_model.dart';
import '../models/category_model.dart';

class FeedRepositoryImpl implements FeedRepository {
  final FeedLocalDatasource _localDatasource;
  final RssRemoteDatasource _remoteDatasource;
  final Uuid _uuid;

  FeedRepositoryImpl({
    FeedLocalDatasource? localDatasource,
    RssRemoteDatasource? remoteDatasource,
    Uuid? uuid,
  })  : _localDatasource = localDatasource ?? FeedLocalDatasource(),
        _remoteDatasource = remoteDatasource ?? RssRemoteDatasource(),
        _uuid = uuid ?? const Uuid();

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
    // Create feed model with a temporary ID first
    final now = DateTime.now();
    final feedId = _uuid.v4();

    // First insert a placeholder feed
    final placeholderFeed = FeedModel(
      id: feedId,
      title: 'Loading...',
      url: url,
      description: null,
      iconUrl: null,
      categoryId: categoryId,
      isDeleted: false,
      createdAt: now,
      updatedAt: now,
    );
    await _localDatasource.insertFeed(placeholderFeed);

    // Fetch articles with the feedId
    final articles = await _remoteDatasource.fetchAndParseArticles(url, feedId);

    // Save articles
    for (final article in articles) {
      await _localDatasource.insertArticle(article);
    }

    // Update feed with actual title if available (first article's feed title)
    String title = 'Untitled Feed';
    if (articles.isNotEmpty) {
      title = articles.first.title;
    }

    await _localDatasource.updateFeed(
      placeholderFeed.copyWith(
        title: title,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> updateFeed(FeedModel feed) async {
    await _localDatasource.updateFeed(feed);
  }

  @override
  Future<void> deleteFeed(String id) async {
    // Soft delete the feed
    await _localDatasource.deleteFeed(id);
    // Soft delete all articles in the feed
    await _localDatasource.softDeleteArticlesByFeedId(id);
  }

  @override
  Future<void> refreshFeed(String id) async {
    final feed = await _localDatasource.getFeedById(id);
    if (feed == null) return;

    // Fetch articles from remote
    final articles = await _remoteDatasource.fetchAndParseArticles(feed.url, id);

    // Upsert articles (insert or replace by id)
    for (final article in articles) {
      await _localDatasource.insertArticle(article);
    }

    // Update feed's updatedAt
    await _localDatasource.updateFeed(
      feed.copyWith(updatedAt: DateTime.now()),
    );
  }

  @override
  Future<void> refreshAllFeeds() async {
    final feeds = await _localDatasource.getAllFeeds();
    for (final feed in feeds) {
      await refreshFeed(feed.id);
    }
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    return _localDatasource.getAllCategories();
  }

  @override
  Future<void> addCategory(String name, String color) async {
    final now = DateTime.now();
    final category = CategoryModel(
      id: _uuid.v4(),
      name: name,
      color: color,
      sortOrder: 0,
      isDeleted: false,
      createdAt: now,
      updatedAt: now,
    );
    await _localDatasource.insertCategory(category);
  }

  @override
  Future<void> updateCategory(CategoryModel category) async {
    await _localDatasource.updateCategory(category);
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _localDatasource.deleteCategory(id);
  }
}
