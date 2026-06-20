import 'package:sqflite/sqflite.dart';
import '../../models/feed_model.dart';
import '../../models/article_model.dart';
import '../../models/category_model.dart';
import 'database_helper.dart';

class FeedLocalDatasource {
  Future<Database> get _db => DatabaseHelper.database;

  String? _userId;

  void setUserId(String? userId) {
    _userId = userId;
  }

  String _getUserIdOrEmpty() => _userId ?? '';

  // Feed methods
  Future<List<FeedModel>> getAllFeeds() async {
    final db = await _db;
    final maps = await db.query(
      'feeds',
      where: 'is_deleted = ? AND user_id = ?',
      whereArgs: [0, _getUserIdOrEmpty()],
      orderBy: 'title ASC',
    );
    return maps.map((m) => FeedModel.fromMap(m)).toList();
  }

  Future<List<FeedModel>> getFeedsByCategory(String categoryId) async {
    final db = await _db;
    final maps = await db.query(
      'feeds',
      where: 'category_id = ? AND is_deleted = ? AND user_id = ?',
      whereArgs: [categoryId, 0, _getUserIdOrEmpty()],
      orderBy: 'title ASC',
    );
    return maps.map((m) => FeedModel.fromMap(m)).toList();
  }

  Future<FeedModel?> getFeedById(String id) async {
    final db = await _db;
    final maps = await db.query(
      'feeds',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return FeedModel.fromMap(maps.first);
  }

  Future<void> insertFeed(FeedModel feed) async {
    final db = await _db;
    await db.insert(
      'feeds',
      feed.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateFeed(FeedModel feed) async {
    final db = await _db;
    await db.update(
      'feeds',
      feed.toMap(),
      where: 'id = ?',
      whereArgs: [feed.id],
    );
  }

  Future<void> deleteFeed(String id) async {
    final db = await _db;
    await db.update(
      'feeds',
      {'is_deleted': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Category methods
  Future<List<CategoryModel>> getAllCategories() async {
    final db = await _db;
    final maps = await db.query(
      'categories',
      where: 'is_deleted = ? AND user_id = ?',
      whereArgs: [0, _getUserIdOrEmpty()],
      orderBy: 'sort_order ASC, name ASC',
    );
    return maps.map((m) => CategoryModel.fromMap(m)).toList();
  }

  Future<CategoryModel?> getCategoryById(String id) async {
    final db = await _db;
    final maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return CategoryModel.fromMap(maps.first);
  }

  Future<void> insertCategory(CategoryModel category) async {
    final db = await _db;
    await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateCategory(CategoryModel category) async {
    final db = await _db;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deleteCategory(String id) async {
    final db = await _db;
    await db.update(
      'categories',
      {'is_deleted': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Article methods
  Future<void> insertArticle(ArticleModel article) async {
    final db = await _db;
    await db.insert(
      'articles',
      article.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ArticleModel>> getArticlesByFeedId(String feedId) async {
    final db = await _db;
    final maps = await db.query(
      'articles',
      where: 'feed_id = ? AND is_deleted = ? AND user_id = ?',
      whereArgs: [feedId, 0, _getUserIdOrEmpty()],
      orderBy: 'published_at DESC',
    );
    return maps.map((m) => ArticleModel.fromMap(m)).toList();
  }

  Future<void> softDeleteArticlesByFeedId(String feedId) async {
    final db = await _db;
    await db.update(
      'articles',
      {'is_deleted': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'feed_id = ?',
      whereArgs: [feedId],
    );
  }
}
